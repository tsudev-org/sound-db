//! Phân tích phổ FFT có hiệu chỉnh cửa sổ, lấy trung bình, giữ đỉnh và ước
//! lượng tần số đỉnh dưới mức bin (nội suy Gauss trên biên độ).
//!
//! Hai thang hiển thị:
//! - `Amplitude`: mỗi bin đọc ra mức RMS của một sóng sin nằm ở bin đó (đã bù
//!   độ lợi kết hợp của cửa sổ). Đúng cho đo tông.
//! - `Power`: công suất trên từng bin (đã bù ENBW), cộng các bin trong một dải
//!   ra đúng mean-square của dải - dùng cho dải octave và tổng năng lượng.

use std::sync::Arc;

use realfft::{RealFftPlanner, RealToComplex, num_complex::Complex};

use crate::weighting::{Weighting, analog_gain_db};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u8)]
pub enum WindowKind {
    Rectangular = 0,
    Hann = 1,
    Hamming = 2,
    BlackmanHarris = 3,
    /// Cửa sổ đỉnh phẳng (HFT): sai số biên độ < 0,01 dB, dùng khi đo mức tông.
    FlatTop = 4,
}

impl WindowKind {
    pub fn from_index(index: u8) -> Option<Self> {
        match index {
            0 => Some(Self::Rectangular),
            1 => Some(Self::Hann),
            2 => Some(Self::Hamming),
            3 => Some(Self::BlackmanHarris),
            4 => Some(Self::FlatTop),
            _ => None,
        }
    }

    pub fn coefficients(self, size: usize) -> Vec<f64> {
        use std::f64::consts::PI;
        let n = size as f64;
        // Cửa sổ tuần hoàn (DFT-even): đúng cho phân tích phổ.
        let cosine_sum = |a: &[f64]| -> Vec<f64> {
            (0..size)
                .map(|i| {
                    let x = 2.0 * PI * i as f64 / n;
                    a.iter().enumerate().fold(0.0, |acc, (k, &ak)| {
                        let sign = if k % 2 == 0 { 1.0 } else { -1.0 };
                        acc + sign * ak * (k as f64 * x).cos()
                    })
                })
                .collect()
        };
        match self {
            Self::Rectangular => vec![1.0; size],
            Self::Hann => cosine_sum(&[0.5, 0.5]),
            Self::Hamming => cosine_sum(&[0.54, 0.46]),
            Self::BlackmanHarris => cosine_sum(&[0.35875, 0.48829, 0.14128, 0.01168]),
            Self::FlatTop => cosine_sum(&[0.215_578_95, 0.416_631_58, 0.277_263_158, 0.083_578_947, 0.006_947_368]),
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u8)]
pub enum Averaging {
    None = 0,
    /// Trung bình mũ, hệ số `exp_alpha` (0..1, nhỏ = mượt).
    Exponential = 1,
    /// Trung bình tuyến tính tích lũy tới khi reset.
    Linear = 2,
}

#[derive(Clone, Copy, Debug)]
pub struct PeakEstimate {
    pub frequency_hz: f64,
    /// Mức (dB, thang Amplitude) của đỉnh sau nội suy.
    pub level_db: f64,
    pub bin: usize,
}

/// Bộ phân tích phổ. Gọi `analyze` với ĐÚNG `size` mẫu (khung mới nhất).
pub struct SpectrumAnalyzer {
    size: usize,
    sample_rate: f64,
    window_kind: WindowKind,
    window: Vec<f64>,
    window_sum: f64,
    window_sq_sum: f64,
    fft: Arc<dyn RealToComplex<f64>>,
    input: Vec<f64>,
    output: Vec<Complex<f64>>,
    scratch: Vec<Complex<f64>>,
    /// Công suất trung bình mỗi bin (mean-square, tuyến tính).
    power: Vec<f64>,
    peak_hold: Vec<f64>,
    frames: u64,
    pub averaging: Averaging,
    pub exp_alpha: f64,
    offset_db: f64,
}

impl SpectrumAnalyzer {
    pub fn new(size: usize, sample_rate: f64, window: WindowKind, calibration_offset_db: f64) -> Self {
        assert!(
            size.is_power_of_two() && (64..=65_536).contains(&size),
            "kích thước FFT phải là lũy thừa 2 trong 64..65536"
        );
        let mut planner = RealFftPlanner::<f64>::new();
        let fft = planner.plan_fft_forward(size);
        let coefficients = window.coefficients(size);
        let window_sum = coefficients.iter().sum();
        let window_sq_sum = coefficients.iter().map(|w| w * w).sum();
        let bins = size / 2 + 1;
        SpectrumAnalyzer {
            size,
            sample_rate,
            window_kind: window,
            window: coefficients,
            window_sum,
            window_sq_sum,
            input: fft.make_input_vec(),
            output: fft.make_output_vec(),
            scratch: fft.make_scratch_vec(),
            fft,
            power: vec![0.0; bins],
            peak_hold: vec![0.0; bins],
            frames: 0,
            averaging: Averaging::Exponential,
            exp_alpha: 0.3,
            offset_db: calibration_offset_db,
        }
    }

    pub fn size(&self) -> usize {
        self.size
    }

    pub fn bins(&self) -> usize {
        self.size / 2 + 1
    }

    pub fn bin_hz(&self) -> f64 {
        self.sample_rate / self.size as f64
    }

    pub fn sample_rate(&self) -> f64 {
        self.sample_rate
    }

    pub fn set_calibration_offset_db(&mut self, offset_db: f64) {
        self.offset_db = offset_db;
    }

    /// Băng thông nhiễu tương đương của cửa sổ, tính theo số bin.
    pub fn enbw_bins(&self) -> f64 {
        self.size as f64 * self.window_sq_sum / (self.window_sum * self.window_sum)
    }

    pub fn reset(&mut self) {
        self.power.iter_mut().for_each(|p| *p = 0.0);
        self.peak_hold.iter_mut().for_each(|p| *p = 0.0);
        self.frames = 0;
    }

    pub fn analyze(&mut self, frame: &[f32]) {
        assert_eq!(frame.len(), self.size, "khung phải dài đúng kích thước FFT");
        // Bỏ thành phần một chiều (DC) của micro: không thì búp DC rò vào vài bin đầu và
        // kéo "tần số trội" xuống dưới 20 Hz.
        let mean = frame.iter().map(|&x| x as f64).sum::<f64>() / self.size as f64;
        for ((dst, &x), &w) in self.input.iter_mut().zip(frame).zip(&self.window) {
            *dst = (x as f64 - mean) * w;
        }
        self.fft
            .process_with_scratch(&mut self.input, &mut self.output, &mut self.scratch)
            .expect("độ dài bộ đệm FFT khớp kế hoạch");
        let norm = self.size as f64 * self.window_sq_sum;
        let last = self.output.len() - 1;
        self.frames += 1;
        let alpha = match self.averaging {
            Averaging::None => 1.0,
            Averaging::Exponential => {
                if self.frames == 1 {
                    1.0
                } else {
                    self.exp_alpha.clamp(1e-4, 1.0)
                }
            }
            Averaging::Linear => 1.0 / self.frames as f64,
        };
        for (k, value) in self.output.iter().enumerate() {
            let one_sided = if k == 0 || k == last { 1.0 } else { 2.0 };
            let p = one_sided * value.norm_sqr() / norm;
            self.power[k] += alpha * (p - self.power[k]);
            if self.power[k] > self.peak_hold[k] {
                self.peak_hold[k] = self.power[k];
            }
        }
    }

    /// Công suất (mean-square tuyến tính) mỗi bin, đã trung bình.
    pub fn power(&self) -> &[f64] {
        &self.power
    }

    fn amplitude_db_from_power(&self, p: f64) -> f64 {
        // Công suất bin đỉnh của một sin = ms_sin * (ENBW)^-1; nhân ENBW để đọc ra ms_sin.
        10.0 * (p * self.enbw_bins()).max(1e-30).log10() + self.offset_db
    }

    /// Phổ dB (thang Amplitude), áp trọng số tần số analog chính xác.
    pub fn spectrum_db(&self, weighting: Weighting, out: &mut Vec<f64>, peak_hold: bool) {
        let source = if peak_hold { &self.peak_hold } else { &self.power };
        out.clear();
        let bin_hz = self.bin_hz();
        out.extend(source.iter().enumerate().map(|(k, &p)| {
            let w = if weighting == Weighting::Z { 0.0 } else { analog_gain_db(weighting, k as f64 * bin_hz) };
            self.amplitude_db_from_power(p) + w
        }));
    }

    /// Tổng mean-square trong dải [lo, hi) Hz có cắt bin lẻ ở hai biên.
    pub fn band_power(&self, lo_hz: f64, hi_hz: f64, weighting: Weighting) -> f64 {
        let bin_hz = self.bin_hz();
        let mut total = 0.0;
        for (k, &p) in self.power.iter().enumerate() {
            let center = k as f64 * bin_hz;
            let bin_lo = center - bin_hz / 2.0;
            let bin_hi = center + bin_hz / 2.0;
            let overlap = (bin_hi.min(hi_hz) - bin_lo.max(lo_hz)).max(0.0) / bin_hz;
            if overlap > 0.0 {
                let gain = if weighting == Weighting::Z {
                    1.0
                } else {
                    10f64.powf(analog_gain_db(weighting, center.max(1e-9)) / 10.0)
                };
                total += overlap * p * gain;
            }
        }
        total
    }

    pub fn band_level_db(&self, lo_hz: f64, hi_hz: f64, weighting: Weighting) -> f64 {
        10.0 * self.band_power(lo_hz, hi_hz, weighting).max(1e-30).log10() + self.offset_db
    }

    /// Nửa độ rộng (bin) vùng quanh đỉnh dùng để ước lượng: phủ búp chính
    /// cộng một búp phụ, để năng lượng bỏ sót dưới 0,005 dB.
    fn lobe_half_width(&self) -> usize {
        match self.window_kind {
            WindowKind::Rectangular => 1,
            WindowKind::Hann | WindowKind::Hamming => 4,
            WindowKind::BlackmanHarris => 6,
            WindowKind::FlatTop => 7,
        }
    }

    /// Đỉnh mạnh nhất trong [min_hz, max_hz].
    ///
    /// Tần số = trọng tâm công suất quanh đỉnh. Theo công thức tổng Poisson, trọng
    /// tâm các mẫu |W(k - d)|^2 của một cửa sổ dài N KHÔNG lệch (tự tương quan của
    /// cửa sổ bằng 0 ở trễ N), nên sai số chỉ còn do cắt cụt búp phụ: < 1% bin
    /// với mọi cửa sổ, gồm cả đỉnh phẳng vốn rất tệ với nội suy parabol.
    /// Mức = tổng công suất quanh đỉnh (định lý Parseval) nên không chịu sai số
    /// "scalloping" của cửa sổ.
    pub fn dominant_peak(&self, min_hz: f64, max_hz: f64) -> Option<PeakEstimate> {
        let bin_hz = self.bin_hz();
        let last = self.power.len() - 1;
        let lo = ((min_hz / bin_hz).ceil() as usize).max(1);
        let hi = ((max_hz / bin_hz).floor() as usize).min(last - 1);
        if lo > hi {
            return None;
        }
        let (bin, &best) =
            self.power[lo..=hi].iter().enumerate().max_by(|a, b| a.1.total_cmp(b.1)).map(|(i, p)| (i + lo, p))?;
        if best <= 0.0 {
            return None;
        }
        if self.window_kind == WindowKind::Rectangular {
            // Cửa sổ chữ nhật: búp phụ quá dày cho trọng tâm, dùng nội suy Gauss.
            let a = self.power[bin - 1].max(1e-300).ln();
            let b = best.ln();
            let c = self.power[bin + 1].max(1e-300).ln();
            let denom = a - 2.0 * b + c;
            let delta = if denom.abs() > 1e-12 { (0.5 * (a - c) / denom).clamp(-0.5, 0.5) } else { 0.0 };
            return Some(PeakEstimate {
                frequency_hz: (bin as f64 + delta) * bin_hz,
                level_db: self.amplitude_db_from_power((b - 0.25 * (a - c) * delta).exp()),
                bin,
            });
        }
        let half = self.lobe_half_width();
        // Vùng trọng tâm không vượt khỏi dải đang tìm (tránh búp lân cận ngoài dải kéo lệch).
        let start = bin.saturating_sub(half).max(lo.saturating_sub(1)).max(1);
        let end = (bin + half).min(hi + 1).min(last - 1);
        let (mut total, mut moment) = (0.0, 0.0);
        for k in start..=end {
            total += self.power[k];
            moment += k as f64 * self.power[k];
        }
        Some(PeakEstimate {
            frequency_hz: moment / total * bin_hz,
            level_db: 10.0 * total.max(1e-30).log10() + self.offset_db,
            bin,
        })
    }
}
