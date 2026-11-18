# Phương pháp đo và giới hạn - Sound Db

## 1. Chuỗi xử lý

```
micro (PCM16, 48 kHz, 1 kênh, tắt AGC/khử vọng/khử ồn)
  ├─ bộ lọc trọng số A / C / Z (IIR, f64) ─ bình phương ─ F 125 ms / S 1 s / I 35 ms lên 1,5 s xuống
  │                                         ├─ tích lũy năng lượng ⇒ Leq, SEL, LAeq từng giây
  │                                         ├─ mỗi 10 ms: Lmax/Lmin, histogram 0,1 dB ⇒ LAF1..LAF99
  │                                         └─ LAS ⇒ liều NIOSH / OSHA
  └─ vòng đệm 65536 mẫu ─ bỏ DC ─ cửa sổ ─ FFT ─ công suất/bin (bù ENBW) ─ trung bình mũ
                           ├─ phổ dB (thang biên độ: sin đọc đúng mức RMS) + giữ đỉnh
                           ├─ tần số trội: trọng tâm công suất quanh đỉnh; mức: tổng Parseval
                           ├─ dải 1/1, 1/3 octave: cộng công suất bin có cắt bin lẻ ở biên
                           └─ khung 4096 mẫu ─ McLeod NSDF ⇒ cao độ + độ rõ
L = 10·log10(trung bình bình phương) + offset hiệu chuẩn
```

## 2. Độ chính xác đã kiểm (tự động, `packages/dsp-core/tests/accuracy.rs`)

| Hạng mục | Kết quả | Tham chiếu |
| --- | --- | --- |
| Đường A, C analog so bảng IEC 61672-1 tại tần số giữa chính xác | lệch < 0,06 dB (bảng làm tròn 0,1) | IEC 61672-1:2013 bảng 3 |
| Bộ lọc số so analog, fs 44,1/48/96 kHz | < 0,05 dB tới 12,5 kHz; < 0,5 dB tới 16 kHz | dung sai cấp 1: ±1 dB trở lên |
| Sin đầy thang 1 kHz | Leq = -3,01 dBFS ± 0,02 | |
| Chùm xung 4 kHz 200 ms, trọng số F | LFmax - L ổn định = -1,0 ± 0,2 dB | IEC 61672-1 mục 5.9 |
| Chùm xung 500 ms, trọng số S | -4,1 ± 0,2 dB | như trên |
| LAF10 / LAF90 tín hiệu hai mức | ± 0,3 dB | |
| Liều NIOSH / OSHA 120 s ở 95 dBA | lệch < 1,5 % | NIOSH REL, OSHA 1910.95 |
| Tần số trội (Hann, Hamming, BH, đỉnh phẳng) | sai số < 1 % bin; mức ± 0,02 dB | |
| Cao độ âm có họa âm 55 Hz - 2,1 kHz | < 1 cent | |
| Dải 1/3 octave giữ năng lượng | ± 0,05 dB | IEC 61260-1 |
| Đầu-cuối trên trình duyệt (Chromium, micro giả nạp tông 1 kHz -20 dBFS) | LZeq 77,0 dB (lý thuyết 76,99), tần số trội 1,000 kHz | |

## 3. Hiệu chuẩn

Offset = mức chuẩn - (mức đo được - offset cũ). Ba cách: máy hiệu chuẩn 94/114 dB tại 1 kHz (LZeq 10 giây), máy đo
chuẩn đặt cạnh (LAeq 10 giây), nhập tay. Chưa hiệu chuẩn: offset ước lượng 120 dB (micro điện thoại điển hình), giao
diện cảnh báo rõ.

## 4. Giới hạn không vượt được bằng phần mềm

- Micro MEMS điện thoại: đáp ứng tần số không phẳng (thường kém dưới 50-100 Hz và trên 10 kHz), bão hòa 100-120 dB,
  sàn ồn 30-40 dBA. Hiệu chuẩn một điểm (1 kHz) không sửa được độ cong tần số.
- Một số máy Android vẫn xử lý âm thanh ở phần cứng dù chọn nguồn `UNPROCESSED`.
- Vì vậy Sound Db là công cụ khảo sát/theo dõi; phép đo có giá trị pháp lý cần máy đo đã kiểm định.

## 5. Đối chiếu với các ứng dụng tham khảo

Chủ dự án nêu 16 ứng dụng đo âm thanh phổ biến (Sound Meter, Decibel X PRO, Spectroid, Máy đo mức âm thanh HQ PRO,
Thước đo âm thanh Đề-xi-ben, Máy đo âm thanh HD, ...). Nhóm tính năng chung của chúng và vị trí trong Sound Db:

| Nhóm tính năng | Sound Db |
| --- | --- |
| Đồng hồ dB lớn, Min/Avg/Max, đồ thị theo thời gian | Đo mức: LxF/S/I, Leq, Lmax/Lmin, Lpeak, đồ thị 2 phút, tô màu vùng |
| Trọng số A/C/Z, F/S | Có, tính song song cả 3 × 3 |
| Phân vị Ln, liều tiếp xúc, TWA | LAF1-99, NIOSH + OSHA, TWA, SEL |
| Phân tích phổ FFT, phổ đồ, giữ đỉnh, con trỏ | Có; FFT tới 32768 điểm, 5 cửa sổ |
| Dải octave 1/1, 1/3 | Có, IEC 61260-1 |
| Máy dò tần số / bộ chỉnh âm | Cao độ McLeod, nốt, cent, A4 chỉnh được |
| Bộ phát tông/ồn | Sin, vuông, răng cưa, tam giác, ồn trắng/hồng, quét log |
| Hiệu chuẩn | 3 cách, hồ sơ đồng bộ |
| Lịch sử, xuất CSV, chia sẻ | Lịch sử phân trang, CSV/JSON, chia sẻ (di động) / lưu tệp (desktop) |
| Đồng bộ đám mây | Tài khoản TsuDEV, đa thiết bị + bảng điều khiển web |
| Đo trên web | Có (WebAssembly, cùng lõi) |

Khác biệt chủ ý: không quảng cáo, không ghi âm, không xin quyền vị trí, mã nguồn và bộ test độ chính xác công khai.
