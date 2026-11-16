//! Dải octave phân số theo IEC 61260-1:2014 (hệ cơ số 10, G = 10^(3/10)).
//!
//! Tần số giữa chính xác: `fm = 1000 * G^(x/b)` (b lẻ). Tên dải dùng tần số
//! danh định của IEC 61260-1 phụ lục E. Mức dải được tính bằng cách cộng công
//! suất các bin FFT (xem `SpectrumAnalyzer::band_power`): đúng cho tín hiệu dừng;
//! dải thấp cần FFT đủ dài để có ít nhất vài bin trong dải - xem `min_fft_size`.

/// Tỷ số octave hệ cơ số 10.
pub const G: f64 = 1.995_262_314_968_879_6; // 10^(3/10)

/// Tần số danh định một phần ba octave từ 10 Hz tới 20 kHz (IEC 61260-1).
const NOMINAL_THIRD: [f64; 34] = [
    10.0, 12.5, 16.0, 20.0, 25.0, 31.5, 40.0, 50.0, 63.0, 80.0, 100.0, 125.0, 160.0, 200.0, 250.0, 315.0, 400.0, 500.0,
    630.0, 800.0, 1000.0, 1250.0, 1600.0, 2000.0, 2500.0, 3150.0, 4000.0, 5000.0, 6300.0, 8000.0, 10_000.0, 12_500.0,
    16_000.0, 20_000.0,
];

#[derive(Clone, Copy, Debug, PartialEq)]
pub struct Band {
    pub nominal_hz: f64,
    pub center_hz: f64,
    pub lower_hz: f64,
    pub upper_hz: f64,
}

/// Danh sách dải 1/`fraction` octave (fraction = 1 hoặc 3) có tần số giữa
/// trong [min_hz, max_hz].
pub fn bands(fraction: u32, min_hz: f64, max_hz: f64) -> Vec<Band> {
    assert!(fraction == 1 || fraction == 3, "chỉ hỗ trợ 1/1 và 1/3 octave");
    let b = fraction as f64;
    let half = G.powf(1.0 / (2.0 * b));
    let mut out = Vec::new();
    // 1/1: x = -6..4 (16 Hz..16 kHz); 1/3: x = -30..13 (10 Hz..20 kHz).
    let range = if fraction == 1 { -6i32..=4 } else { -30i32..=13 };
    for x in range {
        let center = 1000.0 * G.powf(x as f64 / b);
        let label = nominal(center);
        // So theo tần số danh định: dải "20 Hz" có tần số giữa thật 19,95 Hz.
        if label < min_hz || label > max_hz {
            continue;
        }
        out.push(Band { nominal_hz: label, center_hz: center, lower_hz: center / half, upper_hz: center * half });
    }
    out
}

/// Tần số danh định gần nhất (theo dãy 1/3 octave, lặp theo thập phân).
pub fn nominal(center_hz: f64) -> f64 {
    let mut best = NOMINAL_THIRD[0];
    let mut best_err = f64::INFINITY;
    for &candidate in &NOMINAL_THIRD {
        let err = (candidate.ln() - center_hz.ln()).abs();
        if err < best_err {
            best_err = err;
            best = candidate;
        }
    }
    best
}

/// Kích thước FFT tối thiểu để dải thấp nhất có ít nhất `min_bins` bin.
pub fn min_fft_size(lowest: &Band, sample_rate: f64, min_bins: f64) -> usize {
    let width = lowest.upper_hz - lowest.lower_hz;
    let needed = (min_bins * sample_rate / width).ceil() as usize;
    needed.next_power_of_two().clamp(64, 65_536)
}
