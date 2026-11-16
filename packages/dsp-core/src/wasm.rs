//! Lớp vỏ WebAssembly cho apps/web. Bật bằng feature `wasm`.
//! Hợp đồng dữ liệu (bố cục mảng phẳng) mô tả ở `LevelSnapshot::to_flat` và
//! được phía TypeScript giải mã trong `apps/web/src/lib/dsp.ts`.

use wasm_bindgen::prelude::*;

use crate::engine::Engine;
use crate::generator::{SignalGenerator, Waveform};
use crate::spectrum::{Averaging, WindowKind};
use crate::weighting::Weighting;

fn weighting(index: u8) -> Weighting {
    Weighting::from_index(index).unwrap_or(Weighting::A)
}

#[wasm_bindgen]
pub struct WasmEngine {
    inner: Engine,
    spectrum_buf: Vec<f64>,
}

#[wasm_bindgen]
impl WasmEngine {
    #[wasm_bindgen(constructor)]
    pub fn new(
        sample_rate: f64,
        fft_size: usize,
        window: u8,
        calibration_offset_db: f64,
    ) -> Result<WasmEngine, JsError> {
        if !(8000.0..=384_000.0).contains(&sample_rate) {
            return Err(JsError::new("tần số lấy mẫu ngoài khoảng 8-384 kHz"));
        }
        if !fft_size.is_power_of_two() || !(256..=65_536).contains(&fft_size) {
            return Err(JsError::new("kích thước FFT phải là lũy thừa 2 trong 256..65536"));
        }
        let window = WindowKind::from_index(window).unwrap_or(WindowKind::Hann);
        Ok(WasmEngine {
            inner: Engine::new(sample_rate, fft_size, window, calibration_offset_db),
            spectrum_buf: Vec::new(),
        })
    }

    pub fn push(&mut self, samples: &[f32]) {
        self.inner.push(samples);
    }

    #[wasm_bindgen(js_name = setCalibration)]
    pub fn set_calibration(&mut self, offset_db: f64) {
        self.inner.set_calibration_offset_db(offset_db);
    }

    #[wasm_bindgen(js_name = configureSpectrum)]
    pub fn configure_spectrum(
        &mut self,
        fft_size: usize,
        window: u8,
        averaging: u8,
        exp_alpha: f64,
    ) -> Result<(), JsError> {
        if !fft_size.is_power_of_two() || !(256..=65_536).contains(&fft_size) {
            return Err(JsError::new("kích thước FFT phải là lũy thừa 2 trong 256..65536"));
        }
        self.inner.configure_spectrum(fft_size, WindowKind::from_index(window).unwrap_or(WindowKind::Hann));
        let analyzer = self.inner.analyzer();
        analyzer.averaging = match averaging {
            0 => Averaging::None,
            2 => Averaging::Linear,
            _ => Averaging::Exponential,
        };
        analyzer.exp_alpha = exp_alpha.clamp(0.0001, 1.0);
        Ok(())
    }

    /// 61 số theo `LevelSnapshot::to_flat`.
    pub fn levels(&self) -> Vec<f64> {
        self.inner.levels().to_flat()
    }

    /// Phân tích khung mới nhất rồi trả phổ dB (f32 cho nhẹ).
    pub fn spectrum(&mut self, weighting_index: u8, peak_hold: bool) -> Vec<f32> {
        self.inner.analyze_spectrum();
        let mut buf = std::mem::take(&mut self.spectrum_buf);
        self.inner.analyzer_ref().spectrum_db(weighting(weighting_index), &mut buf, peak_hold);
        let out = buf.iter().map(|&v| v as f32).collect();
        self.spectrum_buf = buf;
        out
    }

    /// [tần số Hz, mức dB] của đỉnh mạnh nhất; mảng rỗng nếu không có.
    #[wasm_bindgen(js_name = dominantPeak)]
    pub fn dominant_peak(&self, min_hz: f64, max_hz: f64) -> Vec<f64> {
        self.inner.dominant_peak(min_hz, max_hz).map(|p| vec![p.frequency_hz, p.level_db]).unwrap_or_default()
    }

    /// [tần số Hz, độ rõ]; mảng rỗng nếu không tuần hoàn.
    pub fn pitch(&mut self) -> Vec<f64> {
        self.inner.detect_pitch().map(|p| vec![p.frequency_hz, p.clarity]).unwrap_or_default()
    }

    #[wasm_bindgen(js_name = bandCenters)]
    pub fn band_centers(&self, fraction: u32) -> Vec<f64> {
        self.inner.bands(if fraction == 1 { 1 } else { 3 }).iter().map(|b| b.nominal_hz).collect()
    }

    #[wasm_bindgen(js_name = bandLevels)]
    pub fn band_levels(&self, fraction: u32, weighting_index: u8) -> Vec<f64> {
        self.inner.band_levels(if fraction == 1 { 1 } else { 3 }, weighting(weighting_index))
    }

    #[wasm_bindgen(js_name = binHz)]
    pub fn bin_hz(&self) -> f64 {
        self.inner.analyzer_ref().bin_hz()
    }

    #[wasm_bindgen(js_name = resetSession)]
    pub fn reset_session(&mut self) {
        self.inner.reset_session();
    }
}

#[wasm_bindgen]
pub struct WasmGenerator {
    inner: SignalGenerator,
}

#[wasm_bindgen]
impl WasmGenerator {
    #[wasm_bindgen(constructor)]
    pub fn new(sample_rate: f64) -> WasmGenerator {
        WasmGenerator { inner: SignalGenerator::new(sample_rate) }
    }

    pub fn configure(
        &mut self,
        waveform: u8,
        frequency_hz: f64,
        amplitude: f64,
        sweep_start: f64,
        sweep_end: f64,
        sweep_seconds: f64,
    ) {
        self.inner.waveform = Waveform::from_index(waveform).unwrap_or(Waveform::Sine);
        self.inner.frequency_hz = frequency_hz.clamp(1.0, 96_000.0);
        self.inner.amplitude = amplitude.clamp(0.0, 1.0);
        self.inner.sweep_start_hz = sweep_start.clamp(1.0, 96_000.0);
        self.inner.sweep_end_hz = sweep_end.clamp(1.0, 96_000.0);
        self.inner.sweep_seconds = sweep_seconds.clamp(0.1, 600.0);
    }

    pub fn fill(&mut self, out: &mut [f32]) {
        self.inner.fill(out);
    }
}

/// Đáp ứng trọng số analog (dB) - để vẽ đường cong A/C trên giao diện.
#[wasm_bindgen(js_name = weightingGainDb)]
pub fn weighting_gain_db(weighting_index: u8, freq_hz: f64) -> f64 {
    crate::weighting::analog_gain_db(weighting(weighting_index), freq_hz)
}
