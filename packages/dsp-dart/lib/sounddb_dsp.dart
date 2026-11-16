/// Lõi xử lý tín hiệu âm thanh của Sound Db (bản Dart).
///
/// Bản tham chiếu là crate Rust `packages/dsp-core`; mọi con số ở đây phải
/// khớp `conformance/vectors.json` (xem `test/conformance_test.dart`).
library;

export 'src/engine.dart';
export 'src/fft.dart';
export 'src/generator.dart';
export 'src/level.dart';
export 'src/octave.dart';
export 'src/pitch.dart';
export 'src/spectrum.dart';
export 'src/weighting.dart';
