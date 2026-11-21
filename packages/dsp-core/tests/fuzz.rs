//! Fuzz có hạt giống cố định: đẩy khối mẫu bất thường (độ dài lẻ, biên độ cực lớn, xung, im lặng tuyệt đối, NaN/Inf)
//! vào toàn bộ đường đo qua API công khai. Micro, tệp WAV và cầu nối WASM đều là dữ liệu vào không tin được, nên lõi
//! KHÔNG được panic. NaN trong snapshot là hợp đồng "chưa có dữ liệu" (`LevelSnapshot`), nên chỉ kiểm: đã có mẫu
//! hữu hạn thì `leq` không còn là NaN.

use sounddb_dsp::Engine;
use sounddb_dsp::spectrum::WindowKind;
use sounddb_dsp::weighting::Weighting;

/// xorshift64* - đủ cho fuzz tất định, không cần crate ngoài.
struct Rng(u64);

impl Rng {
    fn next(&mut self) -> u64 {
        self.0 ^= self.0 >> 12;
        self.0 ^= self.0 << 25;
        self.0 ^= self.0 >> 27;
        self.0.wrapping_mul(0x2545_F491_4F6C_DD1D)
    }
    fn below(&mut self, n: u64) -> u64 {
        self.next() % n
    }
    fn unit(&mut self) -> f32 {
        (self.next() >> 40) as f32 / (1u64 << 24) as f32 * 2.0 - 1.0
    }
}

const RATES: [f64; 5] = [8_000.0, 16_000.0, 44_100.0, 48_000.0, 96_000.0];
const FFT: [usize; 4] = [256, 1024, 4096, 16_384];
const WINDOWS: [WindowKind; 5] =
    [WindowKind::Rectangular, WindowKind::Hann, WindowKind::Hamming, WindowKind::BlackmanHarris, WindowKind::FlatTop];

/// Một khối mẫu HỮU HẠN theo một trong vài hình dạng hay làm hỏng bộ lọc và FFT.
fn finite_block(rng: &mut Rng) -> Vec<f32> {
    let len = match rng.below(4) {
        0 => 0,
        1 => 1 + rng.below(7) as usize,
        2 => rng.below(4_096) as usize,
        _ => 16_384 + rng.below(9_000) as usize,
    };
    let shape = rng.below(6);
    (0..len)
        .map(|i| match shape {
            0 => 0.0,
            1 => rng.unit(),
            2 => rng.unit() * f32::MAX,
            3 => {
                if i % 2 == 0 {
                    f32::MAX
                } else {
                    -f32::MAX
                }
            }
            4 => {
                if i == 0 {
                    1.0
                } else {
                    0.0
                }
            }
            _ => rng.unit() * 1e-30,
        })
        .collect()
}

fn exercise(engine: &mut Engine) -> Vec<f64> {
    engine.analyze_spectrum();
    let mut out = engine.levels().to_flat();
    if let Some(peak) = engine.dominant_peak(20.0, 20_000.0) {
        out.push(peak.frequency_hz);
    }
    if let Some(pitch) = engine.detect_pitch() {
        out.push(pitch.frequency_hz);
    }
    for fraction in [1, 3] {
        for weighting in [Weighting::A, Weighting::C, Weighting::Z] {
            out.extend(engine.band_levels(fraction, weighting));
        }
    }
    out
}

#[test]
fn finite_garbage_never_panics_and_leq_is_defined() {
    for seed in 1..=40u64 {
        let mut rng = Rng(seed.wrapping_mul(0x9E37_79B9_7F4A_7C15) | 1);
        let rate = RATES[rng.below(RATES.len() as u64) as usize];
        let fft = FFT[rng.below(FFT.len() as u64) as usize];
        let window = WINDOWS[rng.below(WINDOWS.len() as u64) as usize];
        let mut engine = Engine::new(rate, fft, window, rng.unit() as f64 * 30.0);
        let mut pushed = 0usize;
        for _ in 0..6 {
            let block = finite_block(&mut rng);
            pushed += block.len();
            engine.push(&block);
            exercise(&mut engine);
            if pushed > 0 {
                for (w, leq) in engine.levels().leq.iter().enumerate() {
                    assert!(!leq.is_nan(), "seed {seed}: leq[{w}] NaN sau {pushed} mẫu hữu hạn (fs={rate}, fft={fft})");
                }
            }
        }
        engine.configure_spectrum(FFT[rng.below(FFT.len() as u64) as usize], window);
        exercise(&mut engine);
    }
}

#[test]
fn non_finite_samples_never_panic() {
    let specials = [f32::NAN, f32::INFINITY, f32::NEG_INFINITY, f32::MIN_POSITIVE, -0.0];
    for seed in 1..=20u64 {
        let mut rng = Rng(seed | 1);
        let mut engine = Engine::new(48_000.0, FFT[rng.below(FFT.len() as u64) as usize], WindowKind::Hann, 0.0);
        let len = 1 + rng.below(20_000) as usize;
        let block: Vec<f32> = (0..len)
            .map(|_| if rng.below(10) == 0 { specials[rng.below(specials.len() as u64) as usize] } else { rng.unit() })
            .collect();
        engine.push(&block);
        exercise(&mut engine);
    }
}
