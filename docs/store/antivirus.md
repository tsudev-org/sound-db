# Sổ antivirus / báo nhầm - Sound Db

Chuẩn: `.standards/docs/DISTRIBUTION_TRUST.md` mục 3, 3.1. Job VirusTotal chạy trong workflow phát hành
(`tsudev-org/.github/.github/workflows/virustotal.yml`); cờ mới ⇒ nộp báo nhầm cho hãng trong ≤ 48 giờ theo phiếu điều
phối `~/projects/logs/handover/20261122-AV1_bao-nham-antivirus-toan-he.md`.

| Ngày | Bản | Tệp | Kết quả | Việc đã làm |
| --- | --- | --- | --- | --- |
| 23/11/2026 | v26.11.2301 | 10 tệp (tên cũ + tên chuẩn `{os}-{arch}`) | 0/73 mỗi tệp - sạch (job `virustotal` của Release, ghi trong ghi chú Release) | Không cần nộp |
| 22/11/2026 | v26.11.1705 | `sound-db_26.11.1705_arm64-setup.apk`, `_x64-setup.apk`, `_universal-macos.zip`, `_x64-windows.zip` | 0+0/74 mỗi tệp - sạch | Không cần nộp (phiếu AV1) |
