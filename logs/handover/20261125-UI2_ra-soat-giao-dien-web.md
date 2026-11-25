# PHIẾU - UI2: rà quét sâu giao diện web + hiện đại hoá (sound-db)

- **Mã phiếu**: 20261125-UI2 (phiếu con của `~/projects/logs/handover/20261125-UI2_ra-soat-giao-dien-web-toan-he.md`)
- **Từ**: chủ dự án (25/11/2026), phát bởi phiên `tsudev-3e` - **Đến**: agent của repo `sound-db`
- **Trạng thái**: MỞ
- **Phạm vi**: A + B (thuộc hệ sinh thái TsuDEV)
- **Ủy quyền**: chủ dự án cho agent TỰ MỞ TRÌNH DUYỆT (Playwright/Chromium headless) để rà website của repo này.

## Việc cần làm

1. Đọc phiếu toàn hệ (đường dẫn ở trên) - mục 0 là ba nguyên nhân "trang nhúng khi Ctrl+F5" đã gặp ở tsudev.com; kiểm
   cả ba ở repo này TRƯỚC (fade-in ở màn đầu, font không preload/dự phòng lệch số đo, scroll-reveal ẩn trước khi đo).
2. Làm phần A (rà quét sâu bằng trình duyệt: quay khung hình tải lạnh, ảnh 3 khổ × Sáng/Tối, console/mạng, tiếng
   Việt, bàn phím, LCP/CLS/INP).
3. Làm phần B (hiện đại hoá) - thay đổi bảng màu/font CHUNG chờ bản phát hành tsudev-standards, không tự đổi hex.
4. Ghi từng lỗi + cách sửa vào mục Kết quả; sửa theo PR nhỏ; `akb new issue` cho lỗi tốn > 10 phút.

## Kết quả xử lý

- 25/11/2026 - tsudev-3e: mở phiếu.
- 25/11/2026 - sound-db-ff (agent-sound), PR `chore/standards-v6.0.0`:
  - **Mục 0 (ba nguyên nhân "nhúng")**: (1) fade-in màn đầu - KHÔNG có; (3) scroll-reveal - KHÔNG có; (2) font - CÓ: quay
    khung hình tải lạnh production (Chromium headless, CDP 150 ms / 4 Mbps, không cache) ở 1366 px: tiêu đề h1 hai dòng
    (144 px) bằng font hệ thống rồi nhảy về một dòng (72 px) lúc 1,8 s, CLS 0,049. Sửa: preload 4 tệp woff2 màn đầu
    (Space Grotesk 700 + Be Vietnam Pro 400, latin + vietnamese, `crossorigin`); `@font-face` dự phòng `Space Grotesk
    Fallback` + `Be Vietnam Pro Fallback` với `size-adjust`/`ascent-override`/`descent-override` ĐO bằng canvas trên câu
    tiếng Việt so với Arimo (≡ Arial): SG 500 107,0/91,6/27,1 %, SG 700 100,8/97,2/28,8 %, BVP 400 108,1/92,5/25,0 %,
    BVP 700 105,7/94,6/25,6 % (chuẩn ghi BVP 105,4/102,4 - lệch ~2,7 %, có thể do chuỗi đo; đã dùng số đo của trang).
    Sau (bản dựng local, cùng điều kiện mạng): h1 một dòng ngay khung đầu, CLS 0,0001 (1366) / 0 (360), LCP 976 / 760 ms.
  - **Phần A**: quét 16 trang (vi + en) × 360/768/1366 × Sáng/Tối = 96 lượt (tràn ngang, ảnh hỏng, lỗi console/mạng,
    12 lần Tab phải có vòng focus, gạch dài em/en-dash): 1 lỗi - `/en/tai-ve/` ở 360 px bảng tràn 6 px (từ tiếng Anh dài +
    đệm 0,75rem) ⇒ màn ≤ 420 px bớt đệm + `overflow-wrap: anywhere`; quét lại 30/30 đạt. Ảnh trang chủ 1366 Sáng/Tối:
    9 thẻ tính năng xếp 4 cột, thẻ thứ 9 lẻ một hàng ⇒ lưới `minmax(18rem)` = 3 × 3.
  - **Phần B**: sync tsudev-standards **v6.0.0** (nền Sáng "giấy" `#EEF1F5`, thẻ `#F8FAFC`), sinh lại token web + app
    (`npm run tokens`), `theme.js` nền chống nháy Sáng `#eef1f5`, màu biểu đồ Sáng grid `#C3CBD6` / trục `#475569` theo bảng
    mới; thẻ có hoạ tiết "giấy kẻ ô" tĩnh (≤ 10 % sắc sản phẩm, mờ dần về phía chữ), chân trang lưới chấm tĩnh (≤ 14 %),
    không dải màu đầu thẻ, không chuyển động. App Flutter đọc token lúc dựng ⇒ bản phát hành kế tiếp có nền Sáng mới.
  - CÒN: Lighthouse/INP trên production sau deploy (đo lại bằng `film`); ảnh cửa hàng chế độ Sáng chụp lại khi nộp.
  - **Production sau deploy** (run 45551877260, PR #70): HTML có 4 `rel="preload"` font, `theme.js` nền Sáng `#eef1f5`;
    quay khung hình production: 1366 px h1 một dòng ngay khung đầu, CLS 0,049 ⇒ 0,0001, LCP 1876 ⇒ 1108 ms; 360 px CLS 0,
    LCP 1040 ms; quét `scripts/web/ui2-sweep.cjs` production 16 trang × 3 khổ × Sáng/Tối = **96/96 đạt**. Phiếu con này
    coi như XONG phần A + B; còn Lighthouse INP (không đo được ở headless) và ảnh cửa hàng chế độ Sáng khi nộp.
