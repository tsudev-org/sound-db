# ADR-0001: Một monorepo cho lõi DSP, app 5 nền tảng, website và máy chủ

- **Trạng thái**: ĐÃ CHẤP NHẬN
- **Ngày**: 17/11/2026
- **Người quyết định**: agent-sound theo uỷ quyền của chủ dự án
- **Liên quan**: `docs/ARCHITECTURE.md` mục 2

## 1. Bối cảnh

Chủ dự án yêu cầu một máy đo âm thanh chính xác trên Android, iOS, Windows, Linux, macOS, kèm website và đồng bộ
theo tài khoản tsudev. Ràng buộc: 0 đồng, bảo mật mặc định, con số đo phải giống nhau trên mọi nền tảng.

## 2. Các phương án đã cân nhắc

| Phương án | Ưu | Nhược |
| --- | --- | --- |
| A. Nhiều repo (app, web, api) | tách quyền | hợp đồng dữ liệu và thuật toán trôi lệch giữa repo, không cổng nào bắt |
| B. Monorepo, Flutter cho mọi nền tảng app, Rust làm lõi tham chiếu | một PR đổi thuật toán + vector + bản Dart cùng lúc | công cụ đa ngôn ngữ trong một CI |
| C. App gốc từng nền tảng | trải nghiệm gốc tối đa | 5 mã nguồn, không khả thi để giữ cùng con số |

## 3. Quyết định

Chọn **B**. Lõi DSP viết một lần bằng Rust và là nguồn chân lý về độ chính xác; mọi bản cài đặt khác chứng minh
khớp bằng `conformance/vectors.json`.

## 4. Hệ quả

- Tích cực: một nơi duy nhất định nghĩa "đúng"; web dùng thẳng Rust qua WebAssembly.
- Tiêu cực: CI cần Rust, Flutter, Node; app hiện chạy bản Dart (ADR-0002).

## 5. Đường lùi

Tách repo bất kỳ lúc nào: các thư mục đã có ranh giới build riêng.
