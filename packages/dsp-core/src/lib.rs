//! Lõi xử lý tín hiệu âm thanh của Sound Db.
//!
//! Đây là **bản tham chiếu** về độ chính xác của cả hệ: bản Dart trong
//! `packages/dsp-dart` phải ra cùng con số trên bộ vector đối chiếu
//! `conformance/vectors.json` mà crate này sinh ra (xem `docs/adr/0002`).

#![cfg_attr(not(feature = "wasm"), forbid(unsafe_code))]

pub mod engine;
pub mod generator;
pub mod level;
pub mod octave;
pub mod pitch;
pub mod spectrum;
pub mod weighting;

#[cfg(feature = "wasm")]
pub mod wasm;

pub use engine::Engine;
pub use level::{LevelSnapshot, SoundLevelMeter, TimeWeighting};
pub use spectrum::{Averaging, SpectrumAnalyzer, WindowKind};
pub use weighting::Weighting;
