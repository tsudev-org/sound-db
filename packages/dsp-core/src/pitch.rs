//! Dò cao độ bằng phương pháp McLeod (MPM, hàm chênh lệch bình phương chuẩn
//! hóa - NSDF), tự tương quan tính bằng FFT nên O(N log N).

use std::sync::Arc;

use realfft::{ComplexToReal, RealFftPlanner, RealToComplex, num_complex::Complex};

#[derive(Clone, Copy, Debug, PartialEq)]
pub struct PitchEstimate {
    pub frequency_hz: f64,
    /// Độ rõ 0..1 (giá trị NSDF tại đỉnh). Dưới ~0,8 là tín hiệu không tuần hoàn.
    pub clarity: f64,
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub struct NoteInfo {
    /// Số MIDI (69 = A4).
    pub midi: i32,
    /// Lệch so với nốt gần nhất, cent (-50..50).
    pub cents: f64,
    pub octave: i32,
    /// 0 = C .. 11 = B.
    pub pitch_class: u8,
}

const NOTE_NAMES: [&str; 12] = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];

pub fn note_name(pitch_class: u8) -> &'static str {
    NOTE_NAMES[(pitch_class % 12) as usize]
}

pub fn note_info(frequency_hz: f64, a4_hz: f64) -> Option<NoteInfo> {
    if frequency_hz.is_nan() || a4_hz.is_nan() || frequency_hz <= 0.0 || a4_hz <= 0.0 {
        return None;
    }
    let exact = 69.0 + 12.0 * (frequency_hz / a4_hz).log2();
    let midi = exact.round();
    let midi_i = midi as i32;
    Some(NoteInfo {
        midi: midi_i,
        cents: (exact - midi) * 100.0,
        octave: midi_i.div_euclid(12) - 1,
        pitch_class: midi_i.rem_euclid(12) as u8,
    })
}

pub struct PitchDetector {
    size: usize,
    sample_rate: f64,
    forward: Arc<dyn RealToComplex<f64>>,
    inverse: Arc<dyn ComplexToReal<f64>>,
    buffer: Vec<f64>,
    spectrum: Vec<Complex<f64>>,
    acf: Vec<f64>,
    nsdf: Vec<f64>,
    pub min_hz: f64,
    pub max_hz: f64,
    /// Tỷ lệ so với đỉnh cao nhất để chọn đỉnh khóa (MPM khuyến nghị 0,8-0,93).
    pub threshold: f64,
}

impl PitchDetector {
    pub fn new(size: usize, sample_rate: f64) -> Self {
        assert!(size >= 64, "khung dò cao độ quá ngắn");
        let mut planner = RealFftPlanner::<f64>::new();
        let padded = (2 * size).next_power_of_two();
        let forward = planner.plan_fft_forward(padded);
        let inverse = planner.plan_fft_inverse(padded);
        PitchDetector {
            size,
            sample_rate,
            buffer: forward.make_input_vec(),
            spectrum: forward.make_output_vec(),
            acf: inverse.make_output_vec(),
            nsdf: vec![0.0; size],
            forward,
            inverse,
            min_hz: 30.0,
            max_hz: 5000.0,
            threshold: 0.9,
        }
    }

    pub fn size(&self) -> usize {
        self.size
    }

    pub fn detect(&mut self, frame: &[f32]) -> Option<PitchEstimate> {
        assert_eq!(frame.len(), self.size, "khung phải dài đúng kích thước bộ dò");
        let n = self.size;
        self.buffer.iter_mut().for_each(|v| *v = 0.0);
        let mean = frame.iter().map(|&x| x as f64).sum::<f64>() / n as f64;
        for (dst, &x) in self.buffer.iter_mut().zip(frame) {
            *dst = x as f64 - mean;
        }
        let energy: f64 = self.buffer[..n].iter().map(|x| x * x).sum();
        if energy < 1e-12 {
            return None;
        }
        self.forward.process(&mut self.buffer, &mut self.spectrum).ok()?;
        for c in &mut self.spectrum {
            *c = Complex::new(c.norm_sqr(), 0.0);
        }
        self.inverse.process(&mut self.spectrum, &mut self.acf).ok()?;
        let scale = 1.0 / self.acf.len() as f64;
        // m(tau) = sum_{j<n-tau} x_j^2 + x_{j+tau}^2, tính tăng dần.
        let squares: Vec<f64> = frame.iter().map(|&x| (x as f64 - mean).powi(2)).collect();
        let mut m = 2.0 * energy;
        for tau in 0..n {
            if tau > 0 {
                m -= squares[n - tau] + squares[tau - 1];
            }
            self.nsdf[tau] = if m > 1e-12 { 2.0 * self.acf[tau] * scale / m } else { 0.0 };
        }
        let min_tau = ((self.sample_rate / self.max_hz).floor() as usize).max(2);
        let max_tau = ((self.sample_rate / self.min_hz).ceil() as usize).min(n - 2);
        if min_tau >= max_tau {
            return None;
        }
        // Các đỉnh khóa: cực đại lớn nhất giữa hai lần cắt 0 đi lên/xuống.
        let mut key_maxima: Vec<usize> = Vec::new();
        let mut tau = 1;
        while tau < max_tau && self.nsdf[tau] > 0.0 {
            tau += 1; // bỏ vùng dương đầu tiên quanh tau = 0
        }
        while tau < max_tau {
            if self.nsdf[tau] > 0.0 {
                let mut best = tau;
                while tau < max_tau && self.nsdf[tau] > 0.0 {
                    if self.nsdf[tau] > self.nsdf[best] {
                        best = tau;
                    }
                    tau += 1;
                }
                if best >= min_tau {
                    key_maxima.push(best);
                }
            }
            tau += 1;
        }
        let highest = key_maxima.iter().map(|&t| self.nsdf[t]).fold(0.0, f64::max);
        if highest <= 0.0 {
            return None;
        }
        let chosen = *key_maxima.iter().find(|&&t| self.nsdf[t] >= self.threshold * highest)?;
        let (a, b, c) = (self.nsdf[chosen - 1], self.nsdf[chosen], self.nsdf[chosen + 1]);
        let denom = a - 2.0 * b + c;
        let delta = if denom.abs() > 1e-12 { (0.5 * (a - c) / denom).clamp(-0.5, 0.5) } else { 0.0 };
        let refined_tau = chosen as f64 + delta;
        let clarity = (b - 0.25 * (a - c) * delta).min(1.0);
        Some(PitchEstimate { frequency_hz: self.sample_rate / refined_tau, clarity })
    }
}
