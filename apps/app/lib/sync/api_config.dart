/// Địa chỉ máy chủ Sound Db. Bản dựng dev đặt
/// `--dart-define=SOUNDDB_API=http://127.0.0.1:8787` để chạy với `wrangler dev`.
const String apiBase = String.fromEnvironment('SOUNDDB_API', defaultValue: 'https://sounddb.tsudev.com');

/// Scheme quay về cho app di động/macOS. Phải khớp danh sách cho phép ở
/// `services/sync-api/src/auth/redirects.ts` và cấu hình nền tảng
/// (AndroidManifest, Info.plist).
const String appCallbackScheme = 'com.tsudev.sounddb';
const String appRedirectUri = '$appCallbackScheme:/auth/callback';
