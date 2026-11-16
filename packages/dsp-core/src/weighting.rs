//! Lọc trọng số tần số A, C, Z theo IEC 61672-1:2013.
//!
//! Hai đường dùng chung một bộ cực/zero analog chuẩn:
//! - `Cascade`: bộ lọc IIR số (biến đổi song tuyến tính có nắn trước tần số
//!   cực) chạy trên miền thời gian, dùng cho máy đo mức âm.
//! - `analog_gain_db`: đáp ứng analog chính xác, dùng để gán trọng số cho từng
//!   bin phổ FFT (không chịu sai số nén tần của biến đổi song tuyến tính).

use std::f64::consts::PI;

/// Tần số cực của IEC 61672-1 phụ lục E (Hz).
pub const F1: f64 = 20.598_997_057_568_145;
pub const F2: f64 = 107.652_646_552_734_3;
pub const F3: f64 = 737.862_234_664_590_1;
pub const F4: f64 = 12_194.217_147_998_012;

/// Đường trọng số tần số.
#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
#[repr(u8)]
pub enum Weighting {
    A = 0,
    C = 1,
    Z = 2,
}

impl Weighting {
    pub const ALL: [Weighting; 3] = [Weighting::A, Weighting::C, Weighting::Z];

    pub fn from_index(index: u8) -> Option<Self> {
        match index {
            0 => Some(Weighting::A),
            1 => Some(Weighting::C),
            2 => Some(Weighting::Z),
            _ => None,
        }
    }

    pub fn label(self) -> &'static str {
        match self {
            Weighting::A => "A",
            Weighting::C => "C",
            Weighting::Z => "Z",
        }
    }
}

/// Độ lợi analog (dB) của đường trọng số ở tần số `freq_hz`, đã chuẩn hóa 0 dB
/// tại 1 kHz đúng như IEC 61672-1 (hằng A1000 = -2.000 dB, C1000 = -0.062 dB).
pub fn analog_gain_db(weighting: Weighting, freq_hz: f64) -> f64 {
    if freq_hz <= 0.0 {
        return match weighting {
            Weighting::Z => 0.0,
            _ => f64::NEG_INFINITY,
        };
    }
    match weighting {
        Weighting::Z => 0.0,
        Weighting::C => c_raw_db(freq_hz) - c_raw_db(1000.0),
        Weighting::A => a_raw_db(freq_hz) - a_raw_db(1000.0),
    }
}

fn c_raw_db(f: f64) -> f64 {
    let f2 = f * f;
    let num = F4 * F4 * f2;
    let den = (f2 + F1 * F1) * (f2 + F4 * F4);
    20.0 * (num / den).log10()
}

fn a_raw_db(f: f64) -> f64 {
    let f2 = f * f;
    let num = F4 * F4 * f2 * f2;
    let den = (f2 + F1 * F1) * ((f2 + F2 * F2) * (f2 + F3 * F3)).sqrt() * (f2 + F4 * F4);
    20.0 * (num / den).log10()
}

/// Một khâu bậc hai (biquad) dạng trực tiếp II chuyển vị, tính bằng f64.
#[derive(Clone, Debug)]
pub struct Biquad {
    b0: f64,
    b1: f64,
    b2: f64,
    a1: f64,
    a2: f64,
    z1: f64,
    z2: f64,
}

impl Biquad {
    /// Biến đổi song tuyến tính của khâu analog
    /// `(b0 s^2 + b1 s + b2) / (a0 s^2 + a1 s + a2)`.
    fn from_analog(b: [f64; 3], a: [f64; 3], sample_rate: f64) -> Self {
        let k = 2.0 * sample_rate;
        let k2 = k * k;
        let nb0 = b[0] * k2 + b[1] * k + b[2];
        let nb1 = -2.0 * b[0] * k2 + 2.0 * b[2];
        let nb2 = b[0] * k2 - b[1] * k + b[2];
        let na0 = a[0] * k2 + a[1] * k + a[2];
        let na1 = -2.0 * a[0] * k2 + 2.0 * a[2];
        let na2 = a[0] * k2 - a[1] * k + a[2];
        Biquad { b0: nb0 / na0, b1: nb1 / na0, b2: nb2 / na0, a1: na1 / na0, a2: na2 / na0, z1: 0.0, z2: 0.0 }
    }

    #[inline]
    pub fn process(&mut self, x: f64) -> f64 {
        let y = self.b0 * x + self.z1;
        self.z1 = self.b1 * x - self.a1 * y + self.z2;
        self.z2 = self.b2 * x - self.a2 * y;
        y
    }

    /// |H(e^{jw})| của khâu số.
    fn magnitude(&self, freq_hz: f64, sample_rate: f64) -> f64 {
        let w = 2.0 * PI * freq_hz / sample_rate;
        let (c1, s1) = (w.cos(), w.sin());
        let (c2, s2) = ((2.0 * w).cos(), (2.0 * w).sin());
        let nr = self.b0 + self.b1 * c1 + self.b2 * c2;
        let ni = -(self.b1 * s1 + self.b2 * s2);
        let dr = 1.0 + self.a1 * c1 + self.a2 * c2;
        let di = -(self.a1 * s1 + self.a2 * s2);
        ((nr * nr + ni * ni) / (dr * dr + di * di)).sqrt()
    }

    /// Thông thấp bậc hai khớp biên độ (M. Vicanek, "Matched Second Order
    /// Digital Filters", 2016): cực đặt bằng ánh xạ z = e^(sT) chính xác, tử số
    /// chọn để |H| khớp analog tại DC và tại tần số cực `f0`. Không ép zero về
    /// Nyquist như biến đổi song tuyến tính nên không méo dải cao.
    fn matched_lowpass(f0: f64, q: f64, sample_rate: f64) -> Self {
        let w0 = 2.0 * PI * f0 / sample_rate;
        let zeta = 1.0 / (2.0 * q);
        let (a1, a2) = if zeta <= 1.0 {
            let damped = (1.0 - zeta * zeta).sqrt() * w0;
            (-2.0 * (-zeta * w0).exp() * damped.cos(), (-2.0 * zeta * w0).exp())
        } else {
            let spread = (zeta * zeta - 1.0).sqrt() * w0;
            (-2.0 * (-zeta * w0).exp() * spread.cosh(), (-2.0 * zeta * w0).exp())
        };
        let big_a0 = (1.0 + a1 + a2).powi(2);
        let big_a1 = (1.0 - a1 + a2).powi(2);
        let big_a2 = -4.0 * a2;
        let phi1 = (w0 / 2.0).sin().powi(2);
        let phi0 = 1.0 - phi1;
        let phi2 = 4.0 * phi0 * phi1;
        let r1 = (big_a0 * phi0 + big_a1 * phi1 + big_a2 * phi2) * q * q;
        let big_b0 = big_a0;
        let big_b1 = ((r1 - big_b0 * phi0) / phi1).max(0.0);
        let b0 = 0.5 * (big_b0.sqrt() + big_b1.sqrt());
        let b1 = big_b0.sqrt() - b0;
        Biquad { b0, b1, b2: 0.0, a1, a2, z1: 0.0, z2: 0.0 }
    }

    fn reset(&mut self) {
        self.z1 = 0.0;
        self.z2 = 0.0;
    }
}

/// Chuỗi biquad thực hiện một đường trọng số trên miền thời gian.
#[derive(Clone, Debug)]
pub struct Cascade {
    sections: Vec<Biquad>,
    gain: f64,
    weighting: Weighting,
}

impl Cascade {
    pub fn new(weighting: Weighting, sample_rate: f64) -> Self {
        assert!(sample_rate >= 8000.0, "tần số lấy mẫu quá thấp: {sample_rate}");
        let w1 = 2.0 * PI * F1;
        let w2 = 2.0 * PI * F2;
        let w3 = 2.0 * PI * F3;
        let hp1 = Biquad::from_analog([1.0, 0.0, 0.0], [1.0, 2.0 * w1, w1 * w1], sample_rate);
        // Cực kép 12,2 kHz nằm gần Nyquist: song tuyến tính làm méo dải cao tới
        // gần 1 dB, nên khâu này dùng thiết kế khớp biên độ (Q = 0,5 = cực kép).
        let lp4 = Biquad::matched_lowpass(F4, 0.5, sample_rate);
        let sections = match weighting {
            Weighting::Z => Vec::new(),
            Weighting::C => vec![hp1, lp4],
            Weighting::A => {
                let mid = Biquad::from_analog([1.0, 0.0, 0.0], [1.0, w2 + w3, w2 * w3], sample_rate);
                vec![hp1, mid, lp4]
            }
        };
        let mut cascade = Cascade { sections, gain: 1.0, weighting };
        // Chuẩn hóa đúng giá trị chuẩn tại 1 kHz (0 dB).
        let at_1k = cascade.raw_magnitude(1000.0, sample_rate);
        cascade.gain = if at_1k > 0.0 { 1.0 / at_1k } else { 1.0 };
        cascade
    }

    pub fn weighting(&self) -> Weighting {
        self.weighting
    }

    fn raw_magnitude(&self, freq_hz: f64, sample_rate: f64) -> f64 {
        self.sections.iter().map(|s| s.magnitude(freq_hz, sample_rate)).product()
    }

    /// Đáp ứng biên độ (dB) của bộ lọc số - dùng cho kiểm thử đối chiếu IEC.
    pub fn response_db(&self, freq_hz: f64, sample_rate: f64) -> f64 {
        20.0 * (self.gain * self.raw_magnitude(freq_hz, sample_rate)).log10()
    }

    #[inline]
    pub fn process(&mut self, x: f64) -> f64 {
        let mut y = x * self.gain;
        for section in &mut self.sections {
            y = section.process(y);
        }
        y
    }

    pub fn reset(&mut self) {
        for section in &mut self.sections {
            section.reset();
        }
    }
}
