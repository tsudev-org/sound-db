//! Máy đo mức âm (sound level meter) theo IEC 61672-1.
//!
//! Tính SONG SONG cả ba trọng số tần số A, C, Z, mỗi cái đủ ba trọng số thời
//! gian F (125 ms), S (1 s), I (lên 35 ms, xuống 1,5 s), cộng Leq, Lmax/Lmin,
//! Lpeak. Thêm thống kê phân vị LAFn, SEL và liều tiếp xúc tiếng ồn
//! (NIOSH REL 85 dBA/3 dB, OSHA PEL 90 dBA/5 dB).
//!
//! Đơn vị đầu vào: mẫu PCM chuẩn hóa [-1, 1]. Mức ra là dB với
//! `calibration_offset_db` cộng thêm: `L = 10 log10(mean square) + offset`.
//! Không hiệu chuẩn thì con số là dBFS cộng offset mặc định, KHÔNG phải dB SPL
//! đáng tin - giao diện phải nói rõ điều đó.

use crate::weighting::{Cascade, Weighting};

/// Hằng thời gian chuẩn (giây).
pub const TAU_FAST: f64 = 0.125;
pub const TAU_SLOW: f64 = 1.0;
pub const TAU_IMPULSE_RISE: f64 = 0.035;
pub const TAU_IMPULSE_DECAY: f64 = 1.5;

/// Chu kỳ lấy mẫu thống kê (giây): Lmax/Lmin, phân vị, liều tiếp xúc.
pub const STAT_INTERVAL_S: f64 = 0.01;

/// Mức sàn để tránh log(0) (dB tương đối, trước offset).
const FLOOR_MS: f64 = 1e-20;

/// Histogram phân vị: 0,1 dB mỗi ô, phủ -50..250 dB sau hiệu chuẩn.
const HIST_MIN_DB: f64 = -50.0;
const HIST_STEP_DB: f64 = 0.1;
const HIST_BINS: usize = 3000;

/// Trọng số thời gian.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u8)]
pub enum TimeWeighting {
    Fast = 0,
    Slow = 1,
    Impulse = 2,
}

/// Tiêu chuẩn tính liều tiếp xúc.
#[derive(Clone, Copy, Debug)]
pub struct DoseCriterion {
    /// Mức tiêu chí cho 8 giờ (dBA).
    pub criterion_db: f64,
    /// Hệ số trao đổi (dB): tăng chừng này thì thời gian cho phép giảm một nửa.
    pub exchange_rate_db: f64,
    /// Mức ngưỡng: dưới mức này không tính liều.
    pub threshold_db: f64,
}

pub const NIOSH: DoseCriterion = DoseCriterion { criterion_db: 85.0, exchange_rate_db: 3.0, threshold_db: 80.0 };
pub const OSHA: DoseCriterion = DoseCriterion { criterion_db: 90.0, exchange_rate_db: 5.0, threshold_db: 80.0 };

impl DoseCriterion {
    /// Thời gian tiếp xúc cho phép (giây) ở mức `level_db`.
    pub fn allowed_seconds(&self, level_db: f64) -> f64 {
        8.0 * 3600.0 / 2f64.powf((level_db - self.criterion_db) / self.exchange_rate_db)
    }

    /// Mức trung bình theo thời gian 8 giờ (TWA) tương ứng với liều `dose_percent`.
    pub fn twa_db(&self, dose_percent: f64) -> f64 {
        if dose_percent <= 0.0 {
            return f64::NEG_INFINITY;
        }
        self.criterion_db + self.exchange_rate_db * (dose_percent / 100.0).log2()
    }
}

#[derive(Clone, Debug)]
struct Detector {
    filter: Cascade,
    fast: f64,
    slow: f64,
    impulse: f64,
    sum_sq: f64,
    peak_abs: f64,
    max_ms: [f64; 3],
    min_ms: [f64; 3],
}

impl Detector {
    fn new(weighting: Weighting, sample_rate: f64) -> Self {
        Detector {
            filter: Cascade::new(weighting, sample_rate),
            fast: 0.0,
            slow: 0.0,
            impulse: 0.0,
            sum_sq: 0.0,
            peak_abs: 0.0,
            max_ms: [0.0; 3],
            min_ms: [f64::INFINITY; 3],
        }
    }

    fn reset_stats(&mut self) {
        self.sum_sq = 0.0;
        self.peak_abs = 0.0;
        self.max_ms = [0.0; 3];
        self.min_ms = [f64::INFINITY; 3];
    }
}

/// Ảnh chụp mức âm tại một thời điểm. Mọi mức đã cộng offset hiệu chuẩn.
#[derive(Clone, Debug, Default, PartialEq)]
pub struct LevelSnapshot {
    /// `[trọng số tần số][trọng số thời gian]`, trọng số tần số theo thứ tự A, C, Z.
    pub instant: [[f64; 3]; 3],
    pub leq: [f64; 3],
    pub max: [[f64; 3]; 3],
    pub min: [[f64; 3]; 3],
    pub peak: [f64; 3],
    /// LAF1, LAF5, LAF10, LAF50, LAF90, LAF95, LAF99.
    pub percentiles: [f64; 7],
    /// Mức phơi nhiễm âm thanh LAE (SEL).
    pub sel_a: f64,
    pub dose_niosh_percent: f64,
    pub dose_osha_percent: f64,
    pub twa_niosh: f64,
    pub twa_osha: f64,
    pub elapsed_s: f64,
}

pub const PERCENTILES: [f64; 7] = [1.0, 5.0, 10.0, 50.0, 90.0, 95.0, 99.0];

/// Máy đo mức âm chạy theo luồng.
#[derive(Clone, Debug)]
pub struct SoundLevelMeter {
    sample_rate: f64,
    offset_db: f64,
    detectors: [Detector; 3],
    alpha_fast: f64,
    alpha_slow: f64,
    alpha_imp_rise: f64,
    alpha_imp_decay: f64,
    samples: u64,
    stat_period: u64,
    stat_counter: u64,
    histogram: Vec<u32>,
    histogram_count: u64,
    dose_niosh: f64,
    dose_osha: f64,
}

fn alpha(tau: f64, sample_rate: f64) -> f64 {
    1.0 - (-1.0 / (tau * sample_rate)).exp()
}

fn to_db(ms: f64, offset_db: f64) -> f64 {
    10.0 * ms.max(FLOOR_MS).log10() + offset_db
}

impl SoundLevelMeter {
    pub fn new(sample_rate: f64, calibration_offset_db: f64) -> Self {
        let detectors = Weighting::ALL.map(|w| Detector::new(w, sample_rate));
        SoundLevelMeter {
            sample_rate,
            offset_db: calibration_offset_db,
            detectors,
            alpha_fast: alpha(TAU_FAST, sample_rate),
            alpha_slow: alpha(TAU_SLOW, sample_rate),
            alpha_imp_rise: alpha(TAU_IMPULSE_RISE, sample_rate),
            alpha_imp_decay: alpha(TAU_IMPULSE_DECAY, sample_rate),
            samples: 0,
            stat_period: ((STAT_INTERVAL_S * sample_rate).round() as u64).max(1),
            stat_counter: 0,
            histogram: vec![0; HIST_BINS],
            histogram_count: 0,
            dose_niosh: 0.0,
            dose_osha: 0.0,
        }
    }

    pub fn sample_rate(&self) -> f64 {
        self.sample_rate
    }

    pub fn calibration_offset_db(&self) -> f64 {
        self.offset_db
    }

    /// Đổi offset hiệu chuẩn. Thống kê đã tích lũy vẫn giữ (chúng lưu ở thang
    /// tuyến tính chưa cộng offset, trừ histogram và liều - nên đặt lại phiên).
    pub fn set_calibration_offset_db(&mut self, offset_db: f64) {
        self.offset_db = offset_db;
    }

    /// Xóa Leq, Lmax/Lmin, Lpeak, phân vị và liều; giữ trạng thái bộ lọc.
    pub fn reset_session(&mut self) {
        for detector in &mut self.detectors {
            detector.reset_stats();
        }
        self.samples = 0;
        self.stat_counter = 0;
        self.histogram.iter_mut().for_each(|bin| *bin = 0);
        self.histogram_count = 0;
        self.dose_niosh = 0.0;
        self.dose_osha = 0.0;
    }

    pub fn process(&mut self, block: &[f32]) {
        for &sample in block {
            self.process_sample(sample as f64);
        }
    }

    pub fn process_f64(&mut self, block: &[f64]) {
        for &sample in block {
            self.process_sample(sample);
        }
    }

    #[inline]
    fn process_sample(&mut self, x: f64) {
        let (af, as_, air, aid) = (self.alpha_fast, self.alpha_slow, self.alpha_imp_rise, self.alpha_imp_decay);
        for detector in &mut self.detectors {
            let y = detector.filter.process(x);
            let sq = y * y;
            detector.fast += af * (sq - detector.fast);
            detector.slow += as_ * (sq - detector.slow);
            let ai = if sq > detector.impulse { air } else { aid };
            detector.impulse += ai * (sq - detector.impulse);
            detector.sum_sq += sq;
            let abs = y.abs();
            if abs > detector.peak_abs {
                detector.peak_abs = abs;
            }
        }
        self.samples += 1;
        self.stat_counter += 1;
        if self.stat_counter >= self.stat_period {
            self.stat_counter = 0;
            self.update_stats();
        }
    }

    fn update_stats(&mut self) {
        // Bỏ 0,5 s đầu: bộ dò S chưa ổn định nên Lmin bị kéo xuống giả.
        let settled = self.samples as f64 >= 0.5 * self.sample_rate;
        for detector in &mut self.detectors {
            let values = [detector.fast, detector.slow, detector.impulse];
            for (index, &value) in values.iter().enumerate() {
                if value > detector.max_ms[index] {
                    detector.max_ms[index] = value;
                }
                if settled && value < detector.min_ms[index] {
                    detector.min_ms[index] = value;
                }
            }
        }
        let laf = to_db(self.detectors[0].fast, self.offset_db);
        let bin = ((laf - HIST_MIN_DB) / HIST_STEP_DB).floor().clamp(0.0, (HIST_BINS - 1) as f64) as usize;
        self.histogram[bin] += 1;
        self.histogram_count += 1;
        let las = to_db(self.detectors[0].slow, self.offset_db);
        let dt = self.stat_period as f64 / self.sample_rate;
        if las >= NIOSH.threshold_db {
            self.dose_niosh += 100.0 * dt / NIOSH.allowed_seconds(las);
        }
        if las >= OSHA.threshold_db {
            self.dose_osha += 100.0 * dt / OSHA.allowed_seconds(las);
        }
    }

    /// Mức LAFn: mức bị vượt trong n% thời gian đo.
    pub fn percentile(&self, exceeded_percent: f64) -> f64 {
        if self.histogram_count == 0 {
            return f64::NAN;
        }
        let target = (self.histogram_count as f64 * exceeded_percent / 100.0).ceil().max(1.0) as u64;
        let mut cumulative = 0u64;
        for (index, &count) in self.histogram.iter().enumerate().rev() {
            cumulative += count as u64;
            if cumulative >= target {
                return HIST_MIN_DB + (index as f64 + 0.5) * HIST_STEP_DB;
            }
        }
        HIST_MIN_DB
    }

    pub fn snapshot(&self) -> LevelSnapshot {
        let off = self.offset_db;
        let mut snap = LevelSnapshot { elapsed_s: self.samples as f64 / self.sample_rate, ..Default::default() };
        for (w, detector) in self.detectors.iter().enumerate() {
            snap.instant[w] = [to_db(detector.fast, off), to_db(detector.slow, off), to_db(detector.impulse, off)];
            snap.leq[w] = if self.samples > 0 { to_db(detector.sum_sq / self.samples as f64, off) } else { f64::NAN };
            for t in 0..3 {
                snap.max[w][t] = if detector.max_ms[t] > 0.0 { to_db(detector.max_ms[t], off) } else { f64::NAN };
                snap.min[w][t] = if detector.min_ms[t].is_finite() { to_db(detector.min_ms[t], off) } else { f64::NAN };
            }
            snap.peak[w] =
                if detector.peak_abs > 0.0 { to_db(detector.peak_abs * detector.peak_abs, off) } else { f64::NAN };
        }
        for (index, &p) in PERCENTILES.iter().enumerate() {
            snap.percentiles[index] = self.percentile(p);
        }
        snap.sel_a = if self.samples > 0 { snap.leq[0] + 10.0 * snap.elapsed_s.log10() } else { f64::NAN };
        snap.dose_niosh_percent = self.dose_niosh;
        snap.dose_osha_percent = self.dose_osha;
        snap.twa_niosh = NIOSH.twa_db(self.dose_niosh);
        snap.twa_osha = OSHA.twa_db(self.dose_osha);
        snap
    }
}

impl LevelSnapshot {
    /// Bố cục phẳng cố định để truyền qua WASM/FFI. Thứ tự (61 số):
    /// instant[3][3], leq[3], max[3][3], min[3][3], peak[3], percentiles[7],
    /// sel_a, dose_niosh, dose_osha, twa_niosh, twa_osha, elapsed_s.
    /// THAY ĐỔI THỨ TỰ = thay đổi phá vỡ hợp đồng với apps/web.
    pub const FLAT_LEN: usize = 9 + 3 + 9 + 9 + 3 + 7 + 6;

    pub fn to_flat(&self) -> Vec<f64> {
        let mut out = Vec::with_capacity(Self::FLAT_LEN);
        self.instant.iter().for_each(|row| out.extend_from_slice(row));
        out.extend_from_slice(&self.leq);
        self.max.iter().for_each(|row| out.extend_from_slice(row));
        self.min.iter().for_each(|row| out.extend_from_slice(row));
        out.extend_from_slice(&self.peak);
        out.extend_from_slice(&self.percentiles);
        out.extend_from_slice(&[
            self.sel_a,
            self.dose_niosh_percent,
            self.dose_osha_percent,
            self.twa_niosh,
            self.twa_osha,
            self.elapsed_s,
        ]);
        out
    }
}
