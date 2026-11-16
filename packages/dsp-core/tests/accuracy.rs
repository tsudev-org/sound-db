//! Kiểm độ chính xác của lõi DSP so với giá trị chuẩn IEC và tín hiệu tổng hợp.

use std::f64::consts::PI;

use sounddb_dsp::level::{NIOSH, OSHA, SoundLevelMeter};
use sounddb_dsp::octave;
use sounddb_dsp::pitch::{PitchDetector, note_info};
use sounddb_dsp::spectrum::{Averaging, SpectrumAnalyzer, WindowKind};
use sounddb_dsp::weighting::{Cascade, Weighting, analog_gain_db};

const FS: f64 = 48_000.0;

fn sine(freq: f64, amplitude: f64, seconds: f64, fs: f64) -> Vec<f32> {
    let n = (seconds * fs) as usize;
    (0..n).map(|i| (amplitude * (2.0 * PI * freq * i as f64 / fs).sin()) as f32).collect()
}

/// Giá trị danh định IEC 61672-1:2013 bảng 3 (làm tròn 0,1 dB).
#[test]
fn analog_curves_match_iec_table() {
    // Bảng IEC cho giá trị tại tần số giữa CHÍNH XÁC 1000 * G^(x/3), không tại số danh định.
    let exact = |nominal: f64| {
        octave::bands(3, 10.0, 20_000.0).into_iter().find(|b| b.nominal_hz == nominal).unwrap().center_hz
    };
    let a = [
        (31.5, -39.4),
        (63.0, -26.2),
        (100.0, -19.1),
        (250.0, -8.6),
        (500.0, -3.2),
        (1000.0, 0.0),
        (2000.0, 1.2),
        (4000.0, 1.0),
        (8000.0, -1.1),
        (10_000.0, -2.5),
        (16_000.0, -6.6),
    ];
    for (f, expected) in a {
        let got = analog_gain_db(Weighting::A, exact(f));
        assert!((got - expected).abs() < 0.06, "A({f}) = {got:.3}, chuẩn {expected}");
    }
    let c =
        [(31.5, -3.0), (63.0, -0.8), (100.0, -0.3), (1000.0, 0.0), (4000.0, -0.8), (8000.0, -3.0), (16_000.0, -8.5)];
    for (f, expected) in c {
        let got = analog_gain_db(Weighting::C, exact(f));
        assert!((got - expected).abs() < 0.06, "C({f}) = {got:.3}, chuẩn {expected}");
    }
}

/// Bộ lọc số phải bám đường analog: <0,1 dB tới 4 kHz, trong dung sai cấp 1 ở dải cao.
#[test]
fn digital_filters_track_analog_curves() {
    for &fs in &[44_100.0, 48_000.0, 96_000.0] {
        for weighting in [Weighting::A, Weighting::C] {
            let cascade = Cascade::new(weighting, fs);
            let mut f: f64 = 10.0;
            while f <= 16_000.0 {
                let digital = cascade.response_db(f, fs);
                let analog = analog_gain_db(weighting, f);
                let diff = digital - analog;
                // Chặt hơn dung sai cấp 1 của IEC (±1 dB ở 4-8 kHz) hàng chục lần.
                let (plus, minus) = if f <= 12_600.0 { (0.05, 0.05) } else { (0.5, 0.5) };
                assert!(diff <= plus && diff >= -minus, "{:?} fs={fs} f={f:.1}: lệch {diff:.3} dB", weighting);
                f *= 1.0592537; // 1/12 octave
            }
        }
    }
}

#[test]
fn full_scale_sine_reads_minus_3db() {
    let mut meter = SoundLevelMeter::new(FS, 0.0);
    let signal = sine(1000.0, 1.0, 9.0, FS);
    // Giây đầu chứa quá độ khởi động của bộ lọc (vọt đỉnh ~0,15 dB): bỏ khỏi phiên.
    meter.process(&signal[..FS as usize]);
    meter.reset_session();
    meter.process(&signal[FS as usize..]);
    let snap = meter.snapshot();
    for w in 0..3 {
        assert!((snap.leq[w] + 3.0103).abs() < 0.02, "Leq[{w}] = {}", snap.leq[w]);
        assert!((snap.instant[w][1] + 3.0103).abs() < 0.05, "LS[{w}] = {}", snap.instant[w][1]);
        assert!((snap.peak[w] - 0.0).abs() < 0.05, "Lpeak[{w}] = {}", snap.peak[w]);
    }
}

#[test]
fn calibration_offset_and_a_weighting_at_100hz() {
    let mut meter = SoundLevelMeter::new(FS, 94.0 + 3.0103);
    meter.process(&sine(100.0, 1.0, 4.0, FS));
    let snap = meter.snapshot();
    assert!((snap.leq[2] - 94.0).abs() < 0.02, "LZeq = {}", snap.leq[2]);
    assert!((snap.leq[0] - (94.0 - 19.145)).abs() < 0.1, "LAeq = {}", snap.leq[0]);
}

/// IEC 61672-1 mục 5.9: đáp ứng chùm xung 1 kHz.
#[test]
fn fast_time_weighting_toneburst() {
    // Xung 200 ms với F: Lmax thấp hơn mức ổn định 1,0 dB (±0,5 cấp 1 - kiểm chặt 0,2).
    let mut signal = sine(4000.0, 1.0, 0.2, FS);
    signal.extend(std::iter::repeat_n(0.0f32, (FS * 1.5) as usize));
    let mut meter = SoundLevelMeter::new(FS, 0.0);
    meter.process(&signal);
    let lafmax = meter.snapshot().max[2][0];
    let steady = -3.0103;
    assert!(((lafmax - steady) - (-1.0)).abs() < 0.2, "LFmax lệch {:.3} dB", lafmax - steady);
    // S, xung 500 ms: -4,1 dB.
    let mut signal = sine(4000.0, 1.0, 0.5, FS);
    signal.extend(std::iter::repeat_n(0.0f32, (FS * 4.0) as usize));
    let mut meter = SoundLevelMeter::new(FS, 0.0);
    meter.process(&signal);
    let lasmax = meter.snapshot().max[2][1];
    assert!(((lasmax - steady) - (-4.1)).abs() < 0.2, "LSmax lệch {:.3} dB", lasmax - steady);
}

#[test]
fn percentiles_and_dose() {
    // 10 s ở -20 dBFS rồi 10 s ở -40 dBFS, offset để thành 95/75 dB.
    let offset = 115.0 + 3.0103;
    let mut signal = sine(1000.0, 0.1, 10.0, FS);
    signal.extend(sine(1000.0, 0.01, 10.0, FS));
    let mut meter = SoundLevelMeter::new(FS, offset);
    meter.process(&signal);
    let snap = meter.snapshot();
    assert!((snap.percentiles[2] - 95.0).abs() < 0.3, "LAF10 = {}", snap.percentiles[2]);
    assert!((snap.percentiles[4] - 75.0).abs() < 0.3, "LAF90 = {}", snap.percentiles[4]);
    assert!((NIOSH.twa_db(100.0) - 85.0).abs() < 1e-9);
    assert!((OSHA.twa_db(50.0) - 85.0).abs() < 1e-9);
}

#[test]
fn noise_dose_steady_exposure() {
    // 120 s ổn định ở 95 dBA: NIOSH cho phép 47,6 phút, OSHA 4 giờ.
    let mut meter = SoundLevelMeter::new(FS, 95.0 + 3.0103);
    meter.process(&sine(1000.0, 1.0, 120.0, FS));
    let snap = meter.snapshot();
    let expected_niosh = 100.0 * 120.0 / NIOSH.allowed_seconds(95.0);
    let expected_osha = 100.0 * 120.0 / OSHA.allowed_seconds(95.0);
    // Sai lệch còn lại do bộ dò S cần ~1 s để lên tới mức.
    assert!(
        (snap.dose_niosh_percent / expected_niosh - 1.0).abs() < 0.015,
        "NIOSH {} vs {expected_niosh}",
        snap.dose_niosh_percent
    );
    assert!(
        (snap.dose_osha_percent / expected_osha - 1.0).abs() < 0.015,
        "OSHA {} vs {expected_osha}",
        snap.dose_osha_percent
    );
}

#[test]
fn spectrum_amplitude_and_peak_frequency() {
    for window in [WindowKind::Hann, WindowKind::Hamming, WindowKind::BlackmanHarris, WindowKind::FlatTop] {
        for &freq in &[97.3, 440.0, 1000.0, 3333.3, 12_345.6] {
            let mut analyzer = SpectrumAnalyzer::new(8192, FS, window, 0.0);
            analyzer.averaging = Averaging::None;
            let frame = sine(freq, 0.5, 8192.0 / FS, FS);
            analyzer.analyze(&frame);
            let peak = analyzer.dominant_peak(20.0, 20_000.0).expect("có đỉnh");
            let bin = analyzer.bin_hz();
            assert!(
                (peak.frequency_hz - freq).abs() < 0.01 * bin,
                "{window:?} {freq}: {} (bin {bin:.2})",
                peak.frequency_hz
            );
            let expected = 20.0 * (0.5 / 2f64.sqrt()).log10();
            assert!((peak.level_db - expected).abs() < 0.02, "{window:?} {freq}: mức {} vs {expected}", peak.level_db);
        }
    }
}

#[test]
fn band_power_preserves_energy() {
    let mut analyzer = SpectrumAnalyzer::new(16_384, FS, WindowKind::Hann, 0.0);
    analyzer.averaging = Averaging::None;
    analyzer.analyze(&sine(1000.0, 1.0, 16_384.0 / FS, FS));
    let bands = octave::bands(3, 20.0, 20_000.0);
    let k1 = bands.iter().find(|b| b.nominal_hz == 1000.0).expect("dải 1 kHz");
    let level = analyzer.band_level_db(k1.lower_hz, k1.upper_hz, Weighting::Z);
    assert!((level + 3.0103).abs() < 0.05, "dải 1 kHz = {level}");
    let neighbour = bands.iter().find(|b| b.nominal_hz == 1250.0).unwrap();
    assert!(analyzer.band_level_db(neighbour.lower_hz, neighbour.upper_hz, Weighting::Z) < -40.0);
}

#[test]
fn octave_band_layout() {
    let thirds = octave::bands(3, 20.0, 20_000.0);
    assert_eq!(thirds.len(), 31);
    assert_eq!(thirds.first().unwrap().nominal_hz, 20.0);
    assert_eq!(thirds.last().unwrap().nominal_hz, 20_000.0);
    let octaves = octave::bands(1, 15.0, 16_500.0);
    let names: Vec<f64> = octaves.iter().map(|b| b.nominal_hz).collect();
    assert_eq!(names, vec![16.0, 31.5, 63.0, 125.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0, 16_000.0]);
}

#[test]
fn pitch_detection_accuracy() {
    let mut detector = PitchDetector::new(4096, FS);
    for &freq in &[55.0, 82.41, 110.0, 261.63, 440.0, 987.77, 2093.0] {
        // Sóng có họa âm (răng cưa thô) để thử độ bền với hài.
        let frame: Vec<f32> = (0..4096)
            .map(|i| {
                let t = i as f64 / FS;
                (0.6 * (2.0 * PI * freq * t).sin()
                    + 0.3 * (4.0 * PI * freq * t).sin()
                    + 0.15 * (6.0 * PI * freq * t).sin()) as f32
            })
            .collect();
        let estimate = detector.detect(&frame).expect("có cao độ");
        let cents = 1200.0 * (estimate.frequency_hz / freq).log2();
        assert!(cents.abs() < 1.0, "{freq} Hz: đo {} ({cents:.2} cent)", estimate.frequency_hz);
        assert!(estimate.clarity > 0.9);
    }
    let note = note_info(440.0, 440.0).unwrap();
    assert_eq!((note.midi, note.octave, note.pitch_class), (69, 4, 9));
    let note = note_info(261.63, 440.0).unwrap();
    assert_eq!((note.midi, note.octave, note.pitch_class), (60, 4, 0));
}

#[test]
fn pitch_rejects_noise_and_silence() {
    let mut detector = PitchDetector::new(4096, FS);
    assert!(detector.detect(&vec![0.0; 4096]).is_none());
}
