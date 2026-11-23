# PHIẾU YÊU CẦU AV1 - Antivirus / báo nhầm (sound-db)

- **Mã phiếu**: 20261122-AV1
- **Thời điểm**: 22/11/2026
- **Người gửi**: agent-tsuswico (phiên tsuswico-6e) theo uỷ quyền của chủ dự án
- **Phiếu điều phối**: `~/projects/logs/handover/20261122-AV1_bao-nham-antivirus-toan-he.md` (bảng kết quả cả hệ + thư soạn sẵn từng hãng)
- **Chuẩn**: `.standards/docs/DISTRIBUTION_TRUST.md` mục 3, 3.1
- **Trạng thái**: ĐÓNG (23/11/2026)

## 1. Kết quả VirusTotal 22/11/2026 - bản Latest `v26.11.1705`

| Tệp | Kết quả | Engine |
| --- | --- | --- |
| `sound-db_26.11.1705_arm64-setup.apk` | 0+0/74 | - |
| `sound-db_26.11.1705_universal-macos.zip` | 0+0/74 | - |
| `sound-db_26.11.1705_x64-setup.apk` | 0+0/74 | - |
| `sound-db_26.11.1705_x64-windows.zip` | 0+0/74 | - |

## 2. Việc cần làm

1. Đang sạch - ghi một dòng "22/11/2026 sạch" vào `docs/store/antivirus.md` (tạo nếu chưa có).
2. Giữ job VirusTotal trong workflow phát hành (`tsudev-org/.github/.github/workflows/virustotal.yml`); cờ mới ⇒ nộp trong ≤ 48 giờ theo phiếu điều phối.

## 3. Khép phiếu

Đổi Trạng thái → ĐÓNG khi mọi cờ đã gỡ (hoặc 👤 chấp nhận) và sổ đã ghi.

## 4. Kết quả xử lý

- 23/11/2026 (agent-sound): ghi "22/11/2026 sạch" ở `docs/store/antivirus.md`; job `virustotal` vẫn chặn trước bước công
  bố trong `.github/workflows/release.yml` (ghim `tsudev-org/.github` 8a393eb). Không có cờ ⇒ đóng phiếu.
