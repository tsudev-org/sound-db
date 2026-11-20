import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:tsudev_ui/tsudev_ui.dart';

import '../data/database.dart';
import '../services/settings.dart';
import '../sync/auth_service.dart';

/// client_id OIDC của Sound Db - `aud` của JWS quyền lợi, `?app=` của trang Pro/Ủng hộ.
const sounddbClientId = 'sounddb';

/// Bản phát hành qua Google Play (`--dart-define=SOUNDDB_STORE=play`): `MUST NOT` dẫn ra thanh toán web
/// (PRODUCT_POLICY 4.3, 7.3). Play Billing chưa nối (chờ B2 của tsudev) ⇒ bản Play chỉ hiện trạng thái Pro.
const storeChannel = String.fromEnvironment('SOUNDDB_STORE', defaultValue: 'direct');
bool get isPlayBuild => storeChannel == 'play';

Uri get proBuyUrl => proWebUrl(sounddbClientId);
Uri get donateUrl => Uri.https('tsudev.com', '/ung-ho', {'app': sounddbClientId});

/// Nối kho `kv` của SQLite cục bộ vào giao diện lưu trữ của `tsudev_ui`.
class LocalKeyValueStore implements TsuKeyValueStore {
  LocalKeyValueStore(this._store);
  final LocalStore _store;

  @override
  Future<String?> read(String key) => _store.getValue(key);
  @override
  Future<void> write(String key, String value) => _store.setValue(key, value);
  @override
  Future<void> delete(String key) => _store.removeValue(key);
}

String _platform() {
  if (kIsWeb) return 'web';
  if (Platform.isAndroid) return 'android';
  if (Platform.isIOS) return 'ios';
  if (Platform.isMacOS) return 'macos';
  if (Platform.isWindows) return 'windows';
  return 'linux';
}

/// Quyền lợi TsuDEV Pro của app (PRODUCT_POLICY 7, ADR-0005).
///
/// JWS do tsudev.com ký, đi qua máy chủ Sound Db (`GET /api/v1/me/entitlements` - máy chủ là RP); app TỰ kiểm chữ ký
/// bằng JWKS của tsudev.com (`EntitlementVerifier`), đệm ≤ 7 ngày, hết hạn ⇒ miễn phí. Chỉ để ẩn/hiện ở app:
/// máy chủ tự kiểm Pro trước mỗi lượt đẩy (N4). Không đăng nhập / ngoại tuyến hoàn toàn ⇒ không gọi mạng.
class ProService extends ChangeNotifier {
  ProService(LocalStore store, this._auth, this._settings, {EntitlementsRepository? repository, http.Client? client})
      : kv = LocalKeyValueStore(store) {
    final c = client ?? http.Client();
    repo = repository ??
        EntitlementsRepository(
          verifier: EntitlementVerifier(clientId: sounddbClientId, jwks: DiscoveryJwks(client: c, store: kv)),
          store: kv,
          fetchJws: _fetchJws,
        );
  }

  final TsuKeyValueStore kv;
  final AuthService _auth;
  final Settings _settings;
  late final EntitlementsRepository repo;

  EntitlementState state = const EntitlementState.free();

  /// Nhắc gia hạn 7 ngày cuối / báo hết kỳ (7.6) - MỘT controller cho cả tiến trình (nối vòng đời app).
  late final ProRenewalController renewal = ProRenewalController(store: kv);

  /// Thông báo "nhiều thiết bị chưa có Pro" (7.3), chu kỳ 30 ngày.
  late final ProNoticeController notice = ProNoticeController(store: kv);

  Future<EntitlementState>? _refreshing;

  /// Lượt làm mới đang chạy (hoặc trạng thái hiện tại) - để màn chính chờ trước khi quyết định nhắc.
  Future<EntitlementState> get settled => _refreshing ?? Future.value(state);

  /// Máy chủ vừa trả `402 pro_required` (đồng bộ dừng, không thử lại cho tới khi quyền lợi đổi).
  bool serverSaysProRequired = false;

  bool get isPro => state.isPro(DateTime.now());
  DateTime? get proUntil => state.entitlement?.proUntil;

  Future<String> _fetchJws() async {
    final installation = await InstallationId.getOrCreate(kv);
    final r = await _auth.authorized('GET', '/api/v1/me/entitlements', headers: {
      InstallationId.headerName: installation,
      'X-Tsu-Platform': _platform(),
    });
    if (r.statusCode != 200) throw EntitlementsHttpException(r.statusCode, null);
    final body = jsonDecode(utf8.decode(r.bodyBytes));
    final jws = body is Map ? body['jws'] : null;
    // Không có JWS (chưa cấu hình kênh RP / grant đã hết) ⇒ coi như không lấy được: rơi về đệm còn hạn hoặc miễn phí.
    if (jws is! String) throw const EntitlementsHttpException(404, 'no_jws');
    return jws;
  }

  /// Đọc đệm lúc mở app (không gọi mạng).
  Future<void> load() async {
    state = await repo.current();
    notifyListeners();
  }

  /// Làm mới khi mở app / đăng nhập / quay lại app. Không bao giờ ném lỗi.
  Future<EntitlementState> refresh() => _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<EntitlementState> _refresh() async {
    if (!_auth.signedIn || _settings.offlineMode) {
      state = _auth.signedIn ? await repo.current() : const EntitlementState.free();
    } else {
      state = await repo.refresh();
      if (isPro) serverSaysProRequired = false;
    }
    notifyListeners();
    return state;
  }

  void markProRequired() {
    serverSaysProRequired = true;
    notifyListeners();
  }

  /// Đăng xuất: bỏ JWS đệm của tài khoản cũ (mã cài đặt GIỮ NGUYÊN - nó thuộc bản cài, không thuộc tài khoản).
  Future<void> clear() async {
    await repo.clear();
    state = const EntitlementState.free();
    serverSaysProRequired = false;
    notifyListeners();
  }
}
