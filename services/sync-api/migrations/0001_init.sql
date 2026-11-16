-- Sound Db - lược đồ khởi tạo (D1/SQLite). Migration đã áp dụng là BẤT BIẾN:
-- muốn đổi thì tạo tệp mới.

-- Người dùng = danh tính tsudev (sub của OIDC). Không lưu mật khẩu, không lưu
-- token của tsudev.com.
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  oidc_sub TEXT NOT NULL UNIQUE,
  email TEXT,
  email_verified INTEGER NOT NULL DEFAULT 0,
  display_name TEXT,
  avatar_url TEXT,
  rev INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  last_login_at INTEGER NOT NULL
);

-- Yêu cầu đăng nhập đang chờ tsudev.com trả về (một lần, sống 10 phút).
CREATE TABLE login_requests (
  state_hash TEXT PRIMARY KEY,
  binder_hash TEXT NOT NULL,
  nonce TEXT NOT NULL,
  code_verifier TEXT NOT NULL,
  client_kind TEXT NOT NULL CHECK (client_kind IN ('web', 'app')),
  app_redirect_uri TEXT,
  app_state TEXT,
  app_code_challenge TEXT,
  return_to TEXT,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL
);

-- Mã một lần trả về app, đổi lấy token kèm code_verifier (sống 60 giây).
CREATE TABLE app_codes (
  code_hash TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  redirect_uri TEXT NOT NULL,
  code_challenge TEXT NOT NULL,
  used_at INTEGER,
  expires_at INTEGER NOT NULL
);

-- Thiết bị đã đăng nhập (mỗi lần đăng nhập app = một thiết bị = một họ refresh token).
CREATE TABLE devices (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  platform TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  last_seen_at INTEGER NOT NULL,
  revoked_at INTEGER
);
CREATE INDEX devices_user ON devices(user_id);

-- Refresh token xoay vòng; chỉ lưu SHA-256. used_at khác NULL = đã xoay; dùng lại
-- một token đã xoay ⇒ thu hồi cả thiết bị (phát hiện token bị đánh cắp).
CREATE TABLE refresh_tokens (
  token_hash TEXT PRIMARY KEY,
  device_id TEXT NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  used_at INTEGER
);
CREATE INDEX refresh_tokens_device ON refresh_tokens(device_id);

-- Phiên trình duyệt của bảng điều khiển web.
CREATE TABLE web_sessions (
  token_hash TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  user_agent TEXT
);
CREATE INDEX web_sessions_user ON web_sessions(user_id);

-- Bản ghi đồng bộ (phiên đo, hồ sơ hiệu chuẩn). rev tăng đơn điệu theo người dùng.
CREATE TABLE records (
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  kind TEXT NOT NULL CHECK (kind IN ('session', 'calibration')),
  id TEXT NOT NULL,
  rev INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted INTEGER NOT NULL DEFAULT 0,
  data TEXT NOT NULL,
  device_id TEXT,
  PRIMARY KEY (user_id, kind, id)
);
CREATE INDEX records_user_rev ON records(user_id, rev);
CREATE INDEX records_user_kind_started ON records(user_id, kind, deleted, json_extract(data, '$.started_at'));

-- Giới hạn tần suất cửa sổ cố định.
CREATE TABLE rate_limits (
  key TEXT PRIMARY KEY,
  window_start INTEGER NOT NULL,
  count INTEGER NOT NULL
);

-- Nhật ký sự kiện bảo mật (đăng nhập, thu hồi, phát hiện token dùng lại). IP chỉ lưu dạng băm.
CREATE TABLE audit_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT,
  event TEXT NOT NULL,
  detail TEXT,
  ip_hash TEXT,
  at INTEGER NOT NULL
);
CREATE INDEX audit_log_user ON audit_log(user_id, at);
