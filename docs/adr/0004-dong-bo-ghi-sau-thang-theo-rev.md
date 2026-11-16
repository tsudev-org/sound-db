# ADR-0004: Đồng bộ "ghi sau thắng" theo updated_at, con trỏ kéo là `rev` của máy chủ

- **Trạng thái**: ĐÃ CHẤP NHẬN
- **Ngày**: 17/11/2026
- **Người quyết định**: agent-sound

## 1. Bối cảnh

Dữ liệu đồng bộ là phiên đo (gần như bất biến sau khi lưu - chỉ đổi tên/ghi chú/xóa) và hồ sơ hiệu chuẩn. Xung
đột thật rất hiếm; không cần CRDT. Không được hỏi định kỳ (FREE_TIER_STACK.md mục 3).

## 2. Quyết định

- Mỗi bản ghi: `id` UUIDv7 do máy khách sinh, `updated_at` (ms), `deleted`, `data` (lược đồ có phiên bản `v`).
- Đẩy: máy chủ nhận nếu `updated_at` mới hơn bản đang có, gán `rev = users.rev + 1`; không thì trả `stale` kèm bản
  máy chủ để máy khách áp lại.
- Kéo: `rev > con trỏ`, theo trang; con trỏ đơn điệu nên không sót dù đồng hồ máy khách lệch.
- Xóa = bia mộ không nội dung; bia mộ quá 180 ngày bị dọn (thiết bị không đồng bộ suốt 180 ngày có thể giữ bản đã
  xóa - chấp nhận).
- Chặn `updated_at` vượt hiện tại quá 1 ngày (đồng hồ hỏng sẽ "thắng" mãi mãi).

## 3. Đường lùi

Cần hợp nhất trường-theo-trường: thêm `field_updated_at` vào `data` (tăng `v`), máy chủ giữ nguyên giao thức.
