import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app_links/app_links.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../services/settings.dart';
import 'api_config.dart';

class AuthException implements Exception {
  AuthException(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => message;
}

class AccountUser {
  const AccountUser({required this.id, required this.name, required this.email, this.picture, required this.verified});
  final String id;
  final String name;
  final String email;
  final String? picture;
  final bool verified;

  static AccountUser fromJson(Map<String, Object?> j) => AccountUser(
        id: j['id'] as String,
        name: (j['display_name'] as String?) ?? (j['email'] as String? ?? ''),
        email: (j['email'] as String?) ?? '',
        picture: j['avatar_url'] as String?,
        verified: j['email_verified'] == true,
      );

  Map<String, Object?> toJson() =>
      {'id': id, 'display_name': name, 'email': email, 'avatar_url': picture, 'email_verified': verified};
}

/// Đăng nhập tài khoản TsuDEV cho app.
///
/// Luồng (docs/adr/0003-dang-nhap-qua-may-chu-sound-db.md): app mở TRÌNH DUYỆT
/// HỆ THỐNG tới máy chủ Sound Db, máy chủ đăng nhập với tsudev.com (OIDC + PKCE)
/// rồi trả một mã dùng một lần về app; app đổi mã bằng `code_verifier` của
/// chính nó. Không WebView, không hứng mật khẩu.
/// - Android/iOS: trình duyệt hệ thống (Custom Tabs/Safari), quay về bằng scheme
///   `com.tsudev.sounddb:/auth/callback` nhận qua `app_links`.
/// - Windows/macOS/Linux: vòng lặp `http://127.0.0.1:<cổng ngẫu nhiên>/callback` (RFC 8252).
/// KHÔNG dùng WebView nhúng ở bất kỳ nền tảng nào (AUTH_AND_ACCOUNT.md mục 4).
///
/// Refresh token nằm trong kho bí mật của hệ điều hành (Keychain, Keystore,
/// Credential Manager, Secret Service), access token chỉ ở bộ nhớ.
class AuthService extends ChangeNotifier {
  AuthService(this._settings, {http.Client? client, FlutterSecureStorage? storage})
      : _http = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  final Settings _settings;
  final http.Client _http;
  final FlutterSecureStorage _storage;

  static const _kRefresh = 'sounddb.refresh_token';
  static const _kUser = 'sounddb.user';
  static const _kDevice = 'sounddb.device_id';
  static const _kLastOnline = 'sounddb.last_online_ms';

  /// Ngoại tuyến quá 7 ngày kể từ lần xác thực trực tuyến gần nhất ⇒ về chế độ khách.
  static const offlineGrace = Duration(days: 7);

  AccountUser? user;
  String? deviceId;
  String? _accessToken;
  DateTime? _accessExpiry;
  bool busy = false;

  bool get signedIn => user != null;

  Future<void> load() async {
    try {
      final raw = await _storage.read(key: _kUser);
      final last = int.tryParse(await _storage.read(key: _kLastOnline) ?? '');
      if (raw != null && last != null) {
        final age = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(last));
        if (age <= offlineGrace) {
          user = AccountUser.fromJson(jsonDecode(raw) as Map<String, Object?>);
          deviceId = await _storage.read(key: _kDevice);
        }
      }
    } catch (_) {
      // Kho bí mật không mở được (ví dụ Linux không có Secret Service): chạy ở chế độ khách.
      user = null;
    }
    notifyListeners();
  }

  void _ensureOnline() {
    if (_settings.offlineMode) {
      throw AuthException('offline_mode', 'Đang bật Chế độ ngoại tuyến hoàn toàn - tắt nó trong Cài đặt để đăng nhập.');
    }
  }

  static String _randomUrlSafe(int bytes) {
    final rnd = Random.secure();
    return base64UrlEncode(List<int>.generate(bytes, (_) => rnd.nextInt(256))).replaceAll('=', '');
  }

  static String _challenge(String verifier) =>
      base64UrlEncode(sha256.convert(ascii.encode(verifier)).bytes).replaceAll('=', '');

  Future<void> signIn({required String deviceName}) async {
    _ensureOnline();
    busy = true;
    notifyListeners();
    HttpServer? loopback;
    try {
      final verifier = _randomUrlSafe(48);
      final state = _randomUrlSafe(24);
      final useLoopback = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
      String redirectUri;
      if (useLoopback) {
        loopback = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        redirectUri = 'http://127.0.0.1:${loopback.port}/callback';
      } else {
        redirectUri = appRedirectUri;
      }
      final startUrl = Uri.parse('$apiBase/auth/app/start').replace(queryParameters: {
        'redirect_uri': redirectUri,
        'state': state,
        'code_challenge': _challenge(verifier),
        'code_challenge_method': 'S256',
      });
      Uri callback;
      if (useLoopback) {
        if (!await launchUrl(startUrl, mode: LaunchMode.externalApplication)) {
          throw AuthException('browser', 'Không mở được trình duyệt hệ thống.');
        }
        callback = await _awaitLoopback(loopback!);
      } else {
        callback = await _awaitSchemeCallback(startUrl);
      }
      final params = callback.queryParameters;
      if (params['error'] != null) {
        throw AuthException(params['error']!, params['error_description'] ?? 'Đăng nhập bị hủy hoặc bị từ chối.');
      }
      if (params['state'] != state) {
        throw AuthException('state_mismatch', 'Phản hồi đăng nhập không khớp phiên - đã chặn để an toàn.');
      }
      final code = params['code'];
      if (code == null || code.isEmpty) throw AuthException('no_code', 'Máy chủ không trả mã đăng nhập.');
      await _tokenRequest({
        'grant_type': 'authorization_code',
        'code': code,
        'code_verifier': verifier,
        'redirect_uri': redirectUri,
        'device_name': deviceName,
        'platform': Platform.operatingSystem,
      });
    } finally {
      await loopback?.close(force: true);
      busy = false;
      notifyListeners();
    }
  }

  /// Mở trình duyệt hệ thống, chờ hệ điều hành chuyển `com.tsudev.sounddb:/auth/callback` về app.
  Future<Uri> _awaitSchemeCallback(Uri startUrl) async {
    final completer = Completer<Uri>();
    final sub = AppLinks().uriLinkStream.listen((uri) {
      if (uri.scheme == appCallbackScheme && uri.path == '/auth/callback' && !completer.isCompleted) {
        completer.complete(uri);
      }
    });
    try {
      if (!await launchUrl(startUrl, mode: LaunchMode.externalApplication)) {
        throw AuthException('browser', 'Không mở được trình duyệt hệ thống.');
      }
      return await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => throw AuthException('timeout', 'Hết 5 phút chờ đăng nhập - hãy thử lại.'),
      );
    } finally {
      await sub.cancel();
    }
  }

  Future<Uri> _awaitLoopback(HttpServer server) async {
    final completer = Completer<Uri>();
    late StreamSubscription<HttpRequest> sub;
    sub = server.listen((request) async {
      if (request.uri.path != '/callback') {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..headers.set('Cache-Control', 'no-store')
        ..headers.set('Content-Security-Policy', "default-src 'none'; style-src 'unsafe-inline'")
        ..write('<!doctype html><meta charset="utf-8"><title>Sound Db</title>'
            '<body style="font-family:system-ui;background:#0A0A0A;color:#EDEDED;display:grid;place-items:center;height:100vh">'
            '<p>Đã nhận phản hồi đăng nhập. Bạn có thể đóng thẻ này và quay lại Sound Db.</p>');
      await request.response.close();
      if (!completer.isCompleted) completer.complete(request.uri);
      await sub.cancel();
    });
    return completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () => throw AuthException('timeout', 'Hết 5 phút chờ đăng nhập - hãy thử lại.'),
    );
  }

  Future<void> _tokenRequest(Map<String, String> body) async {
    final response = await _http
        .post(Uri.parse('$apiBase/api/v1/auth/token'),
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'}, body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    final json = _decode(response);
    if (response.statusCode != 200) {
      if (response.statusCode == 400 || response.statusCode == 401) await _clearLocalTokens();
      throw AuthException(json['code'] as String? ?? 'token_error', json['message'] as String? ?? 'Đăng nhập thất bại.');
    }
    _accessToken = json['access_token'] as String;
    _accessExpiry = DateTime.now().add(Duration(seconds: (json['expires_in'] as num).toInt() - 30));
    user = AccountUser.fromJson(json['user'] as Map<String, Object?>);
    deviceId = json['device_id'] as String?;
    await _storage.write(key: _kRefresh, value: json['refresh_token'] as String);
    await _storage.write(key: _kUser, value: jsonEncode(user!.toJson()));
    if (deviceId != null) await _storage.write(key: _kDevice, value: deviceId);
    await _storage.write(key: _kLastOnline, value: '${DateTime.now().millisecondsSinceEpoch}');
    notifyListeners();
  }

  static Map<String, Object?> _decode(http.Response r) {
    try {
      return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, Object?>;
    } catch (_) {
      return {'code': 'bad_response', 'message': 'Máy chủ trả dữ liệu không hợp lệ (HTTP ${r.statusCode}).'};
    }
  }

  /// Access token còn hạn, tự xoay vòng bằng refresh token khi cần.
  Future<String> accessToken() async {
    _ensureOnline();
    if (_accessToken != null && _accessExpiry != null && DateTime.now().isBefore(_accessExpiry!)) return _accessToken!;
    final refresh = await _storage.read(key: _kRefresh);
    if (refresh == null) throw AuthException('signed_out', 'Chưa đăng nhập.');
    await _tokenRequest({'grant_type': 'refresh_token', 'refresh_token': refresh});
    return _accessToken!;
  }

  /// Gọi API kèm Bearer; 401 thì xoay token một lần rồi thử lại.
  Future<http.Response> authorized(String method, String path, {Object? body, Map<String, String>? headers}) async {
    Future<http.Response> send(String token) {
      final request = http.Request(method, Uri.parse('$apiBase$path'))
        ..headers.addAll(headers ?? const {})
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json';
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      return _http.send(request).then(http.Response.fromStream).timeout(const Duration(seconds: 30));
    }

    var response = await send(await accessToken());
    if (response.statusCode == 401) {
      _accessToken = null;
      response = await send(await accessToken());
    }
    return response;
  }

  Future<void> signOut() async {
    try {
      final refresh = await _storage.read(key: _kRefresh);
      if (refresh != null && !_settings.offlineMode) {
        await _http
            .post(Uri.parse('$apiBase/api/v1/auth/logout'),
                headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh_token': refresh}))
            .timeout(const Duration(seconds: 10));
      }
    } catch (_) {
      // Mất mạng vẫn đăng xuất cục bộ; refresh token phía máy chủ tự hết hạn.
    }
    await _clearLocalTokens();
  }

  Future<void> _clearLocalTokens() async {
    _accessToken = null;
    _accessExpiry = null;
    user = null;
    deviceId = null;
    for (final key in const [_kRefresh, _kUser, _kDevice, _kLastOnline]) {
      try {
        await _storage.delete(key: key);
      } catch (_) {}
    }
    notifyListeners();
  }
}
