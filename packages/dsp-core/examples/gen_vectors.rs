//! Sinh `conformance/vectors.json`: bộ vector đối chiếu mà MỌI bản cài đặt DSP
//! khác (Dart trong apps/app) phải tái tạo được. Tín hiệu vào được mô tả bằng
//! tham số (tổng các sin) để bên kia tự sinh lại đúng từng mẫu, không phải
//! chở hàng triệu mẫu trong tệp.
//!
//! Chạy: `cargo run -p sounddb-dsp --example gen_vectors > conformance/vectors.json`

use std::f64::consts::PI;

use serde_json::{Value, json};
use sounddb_dsp::level::SoundLevelMeter;
use sounddb_dsp::octave;
use sounddb_dsp::pitch::PitchDetector;
use sounddb_dsp::spectrum::{Averaging, SpectrumAnalyzer, WindowKind};
use sounddb_dsp::weighting::{Cascade, Weighting};

/// Sinh tín hiệu đúng như phía Dart: tính bằng f64, ép về f32 ở cuối.
fn render(tones: &[(f64, f64)], seconds: f64, fs: f64) -> Vec<f32> {
    let n = (seconds * fs).round() as usize;
    (0..n)
        .map(|i| {
            let t = i as f64 / fs;
            tones.iter().map(|&(f, a)| a * (2.0 * PI * f * t).sin()).sum::<f64>() as f32
        })
        .collect()
}

fn finite(v: f64) -> Value {
    if v.is_finite() { json!(v) } else { Value::Null }
}

fn main() {
    let mut filters = Vec::new();
    for fs in [44_100.0, 48_000.0] {
        for weighting in [Weighting::A, Weighting::C] {
            let cascade = Cascade::new(weighting, fs);
            let freqs: Vec<f64> = (0..40).map(|i| 12.5 * 1.25f64.powi(i)).filter(|&f| f < fs / 2.0).collect();
            let response: Vec<f64> = freqs.iter().map(|&f| cascade.response_db(f, fs)).collect();
            filters.push(json!({"fs": fs, "weighting": weighting.label(), "freqs": freqs, "response_db": response}));
        }
    }

    let meter_cases = [
        (vec![(1000.0, 0.5)], 3.0, 48_000.0, 100.0),
        (vec![(63.0, 0.3), (4000.0, 0.2)], 4.0, 48_000.0, 94.0),
        (vec![(250.0, 0.05), (8000.0, 0.4)], 2.5, 44_100.0, 110.0),
    ];
    let meters: Vec<Value> = meter_cases
        .iter()
        .map(|(tones, seconds, fs, offset)| {
            let mut meter = SoundLevelMeter::new(*fs, *offset);
            meter.process(&render(tones, *seconds, *fs));
            let flat: Vec<Value> = meter.snapshot().to_flat().into_iter().map(finite).collect();
            json!({"tones": tones, "seconds": seconds, "fs": fs, "offset_db": offset, "snapshot": flat})
        })
        .collect();

    let mut spectra = Vec::new();
    for (window, name) in
        [(WindowKind::Hann, "hann"), (WindowKind::BlackmanHarris, "blackman_harris"), (WindowKind::FlatTop, "flat_top")]
    {
        for (size, tones) in [(4096usize, vec![(1234.5, 0.5)]), (16_384, vec![(97.0, 0.3), (5000.0, 0.1)])] {
            let fs = 48_000.0;
            let mut analyzer = SpectrumAnalyzer::new(size, fs, window, 0.0);
            analyzer.averaging = Averaging::None;
            analyzer.analyze(&render(&tones, size as f64 / fs, fs));
            let peak = analyzer.dominant_peak(20.0, 20_000.0).unwrap();
            let bands = octave::bands(3, 20.0, 20_000.0);
            let band_levels: Vec<Value> =
                bands.iter().map(|b| finite(analyzer.band_level_db(b.lower_hz, b.upper_hz, Weighting::A))).collect();
            spectra.push(json!({
                "window": name, "size": size, "fs": fs, "tones": tones,
                "peak_hz": peak.frequency_hz, "peak_db": peak.level_db,
                "third_octave_nominal": bands.iter().map(|b| b.nominal_hz).collect::<Vec<_>>(),
                "third_octave_a_db": band_levels,
            }));
        }
    }

    let fs = 48_000.0;
    let mut detector = PitchDetector::new(4096, fs);
    let pitches: Vec<Value> = [82.41, 196.0, 440.0, 1318.5]
        .iter()
        .map(|&f| {
            let tones = vec![(f, 0.6), (2.0 * f, 0.3), (3.0 * f, 0.15)];
            let estimate = detector.detect(&render(&tones, 4096.0 / fs, fs)).unwrap();
            json!({"tones": tones, "fs": fs, "size": 4096, "frequency_hz": estimate.frequency_hz, "clarity": estimate.clarity})
        })
        .collect();

    let doc = json!({
        "schema": 1,
        "generator": "sounddb-dsp examples/gen_vectors.rs",
        "tolerance_db": 0.01,
        "tolerance_hz_relative": 1e-4,
        "filters": filters,
        "meters": meters,
        "spectra": spectra,
        "pitches": pitches,
    });
    println!("{}", serde_json::to_string_pretty(&doc).unwrap());
}
