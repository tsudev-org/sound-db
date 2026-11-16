# ADR-0002: Lõi DSP Rust là tham chiếu; app Flutter chạy bản Dart khớp vector đối chiếu

- **Trạng thái**: ĐÃ CHẤP NHẬN
- **Ngày**: 17/11/2026
- **Người quyết định**: agent-sound
- **Liên quan**: `packages/dsp-core`, `packages/dsp-dart`, `conformance/vectors.json`

## 1. Bối cảnh

Gọi Rust từ Flutter qua FFI cần dựng thư viện gốc cho 5 nền tảng × nhiều kiến trúc (Android NDK 4 ABI, iOS
xcframework, macOS universal, Windows MSVC, Linux), mỗi cái một chuỗi công cụ và một điểm hỏng trong CI. Khối
lượng tính toán của máy đo nhỏ (FFT 8192 điểm ~20 lần/giây, 6 bộ lọc IIR ở 48 kHz) - Dart AOT dư sức.

## 2. Các phương án đã cân nhắc

| Phương án | Ưu | Nhược |
| --- | --- | --- |
| A. Rust qua FFI (flutter_rust_bridge/cargokit) | một mã nguồn thuật toán | 5 chuỗi công cụ gốc, bản dựng chậm, rủi ro CI cao |
| B. Dart thuần, không tham chiếu | đơn giản | không ai chứng minh được con số đúng/giống web |
| C. Rust tham chiếu + WASM cho web + bản Dart cho app, khớp vector | bản dựng app thuần Dart; sai khác bị bắt tự động | thuật toán có hai bản |

## 3. Quyết định

Chọn **C**. Bản Rust có bộ test độ chính xác theo IEC (12 test); `examples/gen_vectors.rs` sinh vector (đáp ứng bộ
lọc, 46 số ảnh chụp mức âm, đỉnh phổ, dải 1/3 octave, cao độ) từ tín hiệu mô tả bằng tham số; bản Dart phải tái
tạo trong dung sai 0,01 dB / 1e-4 tương đối. Đổi thuật toán mà không sửa cả hai bản ⇒ test Dart đỏ.

## 4. Hệ quả

- Tích cực: app dựng bằng Flutter thuần cho mọi nền tảng; web và app được chứng minh cùng con số.
- Tiêu cực: sửa thuật toán phải sửa hai nơi trong cùng PR (ghi ở AGENTS.md B.5).

## 5. Đường lùi

Khi cần hiệu năng cao hơn (ví dụ phân tích FFT 65536 điểm thời gian thực trên máy yếu): chuyển app sang Rust qua
FFI; vector đối chiếu giữ nguyên làm cổng kiểm.
