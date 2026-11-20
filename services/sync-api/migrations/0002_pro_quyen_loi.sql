-- PRO1/PRO2 (PRODUCT_POLICY 7): quyền lợi TsuDEV Pro đệm theo tài khoản. Nguồn sự thật là tsudev.com:
-- JWS quyền lợi qua kênh RP (`GET /api/rp/entitlements/{sub}`) hoặc `pro_until` qua kênh trạng thái.
-- Đệm tối đa 24 giờ (7.4); xoá dữ liệu đám mây chỉ sau khi kênh trạng thái xác nhận (xoá có xác minh).
CREATE TABLE entitlements (
  user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  pro_until INTEGER NOT NULL DEFAULT 0,      -- mili giây Unix; 0 = chưa từng có Pro
  badge TEXT NOT NULL DEFAULT 'none',
  devices_30d INTEGER NOT NULL DEFAULT 0,
  jws TEXT,                                  -- JWS gần nhất (trả lại cho app; app tự kiểm chữ ký)
  jws_exp INTEGER NOT NULL DEFAULT 0,        -- mili giây
  fetched_at INTEGER NOT NULL DEFAULT 0,     -- lần làm mới gần nhất (mili giây)
  purge_checked_at INTEGER NOT NULL DEFAULT 0 -- lần hỏi kênh trạng thái gần nhất trước khi xoá (mili giây)
);
