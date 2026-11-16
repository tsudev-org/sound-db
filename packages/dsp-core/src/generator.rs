//! Bộ phát tín hiệu thử: sin, vuông, răng cưa, tam giác, ồn trắng, ồn hồng,
//! quét tần số logarit. Dùng để thử loa/tai nghe và tự kiểm máy đo.

use std::f64::consts::PI;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u8)]
pub enum Waveform {
    Sine = 0,
    Square = 1,
    Sawtooth = 2,
    Triangle = 3,
    WhiteNoise = 4,
    PinkNoise = 5,
    LogSweep = 6,
}

impl Waveform {
    pub fn from_index(index: u8) -> Option<Self> {
        match index {
            0 => Some(Self::Sine),
            1 => Some(Self::Square),
            2 => Some(Self::Sawtooth),
            3 => Some(Self::Triangle),
            4 => Some(Self::WhiteNoise),
            5 => Some(Self::PinkNoise),
            6 => Some(Self::LogSweep),
            _ => None,
        }
    }
}

pub struct SignalGenerator {
    sample_rate: f64,
    pub waveform: Waveform,
    pub frequency_hz: f64,
    /// Biên độ đỉnh 0..1.
    pub amplitude: f64,
    pub sweep_start_hz: f64,
    pub sweep_end_hz: f64,
    pub sweep_seconds: f64,
    phase: f64,
    elapsed: u64,
    rng: u64,
    pink: [f64; 7],
}

impl SignalGenerator {
    pub fn new(sample_rate: f64) -> Self {
        SignalGenerator {
            sample_rate,
            waveform: Waveform::Sine,
            frequency_hz: 1000.0,
            amplitude: 0.5,
            sweep_start_hz: 20.0,
            sweep_end_hz: 20_000.0,
            sweep_seconds: 10.0,
            phase: 0.0,
            elapsed: 0,
            rng: 0x9E37_79B9_7F4A_7C15,
            pink: [0.0; 7],
        }
    }

    pub fn reset(&mut self) {
        self.phase = 0.0;
        self.elapsed = 0;
        self.pink = [0.0; 7];
    }

    /// xorshift64* - đủ cho ồn thử, không dùng cho mật mã.
    fn next_uniform(&mut self) -> f64 {
        self.rng ^= self.rng >> 12;
        self.rng ^= self.rng << 25;
        self.rng ^= self.rng >> 27;
        let value = self.rng.wrapping_mul(0x2545_F491_4F6C_DD1D);
        (value >> 11) as f64 / (1u64 << 53) as f64 * 2.0 - 1.0
    }

    fn current_frequency(&self) -> f64 {
        if self.waveform != Waveform::LogSweep {
            return self.frequency_hz;
        }
        let t = (self.elapsed as f64 / self.sample_rate) % self.sweep_seconds.max(0.1);
        let ratio = self.sweep_end_hz / self.sweep_start_hz;
        self.sweep_start_hz * ratio.powf(t / self.sweep_seconds.max(0.1))
    }

    pub fn fill(&mut self, out: &mut [f32]) {
        let nyquist = self.sample_rate / 2.0;
        for sample in out.iter_mut() {
            let freq = self.current_frequency().clamp(0.0, nyquist);
            let value = match self.waveform {
                Waveform::Sine | Waveform::LogSweep => (2.0 * PI * self.phase).sin(),
                Waveform::Square => {
                    if self.phase < 0.5 {
                        1.0
                    } else {
                        -1.0
                    }
                }
                Waveform::Sawtooth => 2.0 * self.phase - 1.0,
                Waveform::Triangle => 1.0 - 4.0 * (self.phase - 0.5).abs(),
                Waveform::WhiteNoise => self.next_uniform(),
                Waveform::PinkNoise => {
                    // Bộ lọc Paul Kellet (sai số < 0,05 dB trên 9,2 Hz..fs/2).
                    let white = self.next_uniform();
                    let b = &mut self.pink;
                    b[0] = 0.99886 * b[0] + white * 0.055_517_9;
                    b[1] = 0.99332 * b[1] + white * 0.075_075_9;
                    b[2] = 0.96900 * b[2] + white * 0.153_852_0;
                    b[3] = 0.86650 * b[3] + white * 0.310_485_6;
                    b[4] = 0.55000 * b[4] + white * 0.532_952_2;
                    b[5] = -0.7616 * b[5] - white * 0.016_898_0;
                    let pink = b[0] + b[1] + b[2] + b[3] + b[4] + b[5] + b[6] + white * 0.5362;
                    b[6] = white * 0.115_926;
                    pink * 0.11
                }
            };
            *sample = (value * self.amplitude.clamp(0.0, 1.0)) as f32;
            self.phase = (self.phase + freq / self.sample_rate).fract();
            self.elapsed += 1;
        }
    }
}
