//! `Engine` gom mọi bộ phân tích quanh một vòng đệm mẫu, để các lớp vỏ
//! (WASM cho web, FFI cho bản gốc) chỉ cần đẩy mẫu vào và đọc kết quả ra.

use crate::level::{LevelSnapshot, SoundLevelMeter};
use crate::octave::{self, Band};
use crate::pitch::{PitchDetector, PitchEstimate};
use crate::spectrum::{PeakEstimate, SpectrumAnalyzer, WindowKind};
use crate::weighting::Weighting;

pub struct Engine {
    sample_rate: f64,
    meter: SoundLevelMeter,
    spectrum: SpectrumAnalyzer,
    pitch: PitchDetector,
    ring: Vec<f32>,
    ring_pos: usize,
    frame: Vec<f32>,
    third_bands: Vec<Band>,
    octave_bands: Vec<Band>,
}

/// Vòng đệm giữ đủ cho khung FFT dài nhất.
const RING_SIZE: usize = 65_536;
const PITCH_FRAME: usize = 4096;

impl Engine {
    pub fn new(sample_rate: f64, fft_size: usize, window: WindowKind, calibration_offset_db: f64) -> Self {
        let nyquist = sample_rate / 2.0;
        Engine {
            sample_rate,
            meter: SoundLevelMeter::new(sample_rate, calibration_offset_db),
            spectrum: SpectrumAnalyzer::new(fft_size, sample_rate, window, calibration_offset_db),
            pitch: PitchDetector::new(PITCH_FRAME, sample_rate),
            ring: vec![0.0; RING_SIZE],
            ring_pos: 0,
            frame: Vec::with_capacity(RING_SIZE),
            third_bands: octave::bands(3, 10.0, nyquist / 1.13),
            octave_bands: octave::bands(1, 15.0, nyquist / 1.42),
        }
    }

    pub fn sample_rate(&self) -> f64 {
        self.sample_rate
    }

    pub fn meter(&mut self) -> &mut SoundLevelMeter {
        &mut self.meter
    }

    pub fn analyzer(&mut self) -> &mut SpectrumAnalyzer {
        &mut self.spectrum
    }

    pub fn analyzer_ref(&self) -> &SpectrumAnalyzer {
        &self.spectrum
    }

    pub fn set_calibration_offset_db(&mut self, offset_db: f64) {
        self.meter.set_calibration_offset_db(offset_db);
        self.spectrum.set_calibration_offset_db(offset_db);
    }

    /// Đổi kích thước FFT/cửa sổ: dựng lại bộ phân tích phổ, giữ máy đo mức.
    pub fn configure_spectrum(&mut self, fft_size: usize, window: WindowKind) {
        let offset = self.meter.calibration_offset_db();
        let (averaging, alpha) = (self.spectrum.averaging, self.spectrum.exp_alpha);
        self.spectrum = SpectrumAnalyzer::new(fft_size, self.sample_rate, window, offset);
        self.spectrum.averaging = averaging;
        self.spectrum.exp_alpha = alpha;
    }

    pub fn push(&mut self, samples: &[f32]) {
        self.meter.process(samples);
        for &sample in samples {
            self.ring[self.ring_pos] = sample;
            self.ring_pos = (self.ring_pos + 1) % RING_SIZE;
        }
    }

    fn latest(&mut self, size: usize) {
        self.frame.clear();
        let start = (self.ring_pos + RING_SIZE - size) % RING_SIZE;
        if start + size <= RING_SIZE {
            self.frame.extend_from_slice(&self.ring[start..start + size]);
        } else {
            self.frame.extend_from_slice(&self.ring[start..]);
            self.frame.extend_from_slice(&self.ring[..size - (RING_SIZE - start)]);
        }
    }

    /// Phân tích khung mới nhất vào bộ trung bình phổ.
    pub fn analyze_spectrum(&mut self) {
        let size = self.spectrum.size();
        self.latest(size);
        let frame = std::mem::take(&mut self.frame);
        self.spectrum.analyze(&frame);
        self.frame = frame;
    }

    pub fn levels(&self) -> LevelSnapshot {
        self.meter.snapshot()
    }

    pub fn dominant_peak(&self, min_hz: f64, max_hz: f64) -> Option<PeakEstimate> {
        self.spectrum.dominant_peak(min_hz, max_hz)
    }

    pub fn detect_pitch(&mut self) -> Option<PitchEstimate> {
        self.latest(PITCH_FRAME);
        let frame = std::mem::take(&mut self.frame);
        let result = self.pitch.detect(&frame);
        self.frame = frame;
        result
    }

    pub fn bands(&self, fraction: u32) -> &[Band] {
        if fraction == 1 { &self.octave_bands } else { &self.third_bands }
    }

    pub fn band_levels(&self, fraction: u32, weighting: Weighting) -> Vec<f64> {
        self.bands(fraction).iter().map(|b| self.spectrum.band_level_db(b.lower_hz, b.upper_hz, weighting)).collect()
    }

    pub fn reset_session(&mut self) {
        self.meter.reset_session();
        self.spectrum.reset();
    }
}
