// PRO1/PRO2 (PRODUCT_POLICY 7): điều khoản nguyên văn, bản miễn phí không gửi dữ liệu đo lên mạng, 402 dừng đẩy.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sound_db/data/database.dart';
import 'package:sound_db/data/models.dart';
import 'package:sound_db/pro/pro_page.dart';
import 'package:sound_db/pro/pro_service.dart';
import 'package:sound_db/services/settings.dart';
import 'package:sound_db/sync/auth_service.dart';
import 'package:sound_db/sync/sync_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Tài khoản giả đã đăng nhập: ghi lại mọi yêu cầu, trả phản hồi theo [reply].
class _FakeAuth extends AuthService {
  _FakeAuth(super.settings);
  final calls = <String>[];
  int pushStatus = 200;

  @override
  bool get signedIn => true;

  @override
  Future<http.Response> authorized(String method, String path, {Object? body, Map<String, String>? headers}) async {
    calls.add('$method ${path.split('?').first}');
    if (path.startsWith('/api/v1/sync/push')) {
      if (pushStatus != 200) return http.Response.bytes(utf8.encode(jsonEncode({'error': 'pro_required', 'message': 'Cần Pro'})), pushStatus);
      final changes = ((body as Map)['changes'] as List).cast<Map<String, Object?>>();
      return http.Response(
          jsonEncode({'results': [for (final c in changes) {'kind': c['kind'], 'id': c['id'], 'status': 'applied', 'rev': 1}]}), 200);
    }
    return http.Response(jsonEncode({'changes': [], 'cursor': 0, 'has_more': false}), 200);
  }
}

class _FakePro extends ProService {
  _FakePro(super.store, super.auth, super.settings, {required this.pro});
  bool pro;
  @override
  bool get isPro => pro;
}

Future<(LocalStore, Settings, _FakeAuth)> _setup() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final store = await LocalStore.openAt('${Directory.systemTemp.createTempSync('sounddb-pro').path}/db.sqlite');
  final settings = Settings(store);
  await settings.load();
  await store.saveCalibration(CalibrationProfile(id: 'c1', name: 'Máy hiệu chuẩn', offsetDb: 118.2, method: 'manual', updatedAt: DateTime.now()));
  return (store, settings, _FakeAuth(settings));
}

/// Lấy câu nguyên văn trong `.standards/docs/PRODUCT_POLICY.md` mục 7.5.
String _policyTerms(String lang) {
  final text = File('../../.standards/docs/PRODUCT_POLICY.md').readAsStringSync();
  final m = RegExp(lang == 'vi' ? r'nguyên văn \(vi\): "([^"]+)"' : r'- \(en\): "([^"]+)"').firstMatch(text)!;
  return m.group(1)!.replaceAll(RegExp(r'\s*\n\s*'), ' ');
}

void main() {
  test('điều khoản Pro đúng NGUYÊN VĂN PRODUCT_POLICY 7.5 (vi + en)', () {
    expect(proTerms('{giá}'), _policyTerms('vi'));
    expect(proTerms('{price}', english: true), _policyTerms('en'));
  });

  test('trang Pro/Ủng hộ ngoài cửa hàng dẫn đúng hợp đồng 7.4', () {
    expect(proBuyUrl.toString(), 'https://tsudev.com/pro?app=sounddb');
    expect(donateUrl.toString(), 'https://tsudev.com/ung-ho?app=sounddb');
    expect(isPlayBuild, isFalse);
  });

  test('bản miễn phí: KHÔNG đẩy dữ liệu đo lên máy chủ (N2), vẫn kéo được', () async {
    final (store, settings, auth) = await _setup();
    final pro = _FakePro(store, auth, settings, pro: false);
    final sync = SyncService(store, auth, settings, pro);
    expect(await sync.syncNow(), isTrue);
    expect(auth.calls, ['GET /api/v1/sync/pull']);
    expect(sync.statusText, contains('TsuDEV Pro'));
    expect(await store.dirtyRecords(limit: 10), hasLength(1));
  });

  test('có Pro: đẩy rồi kéo', () async {
    final (store, settings, auth) = await _setup();
    final sync = SyncService(store, auth, settings, _FakePro(store, auth, settings, pro: true));
    expect(await sync.syncNow(), isTrue);
    expect(auth.calls, ['POST /api/v1/sync/push', 'GET /api/v1/sync/pull']);
    expect(await store.dirtyRecords(limit: 10), isEmpty);
  });

  test('máy chủ trả 402 pro_required ⇒ dừng đẩy, không thử lại, dữ liệu giữ trên thiết bị', () async {
    final (store, settings, auth) = await _setup();
    auth.pushStatus = 402;
    final pro = _FakePro(store, auth, settings, pro: true);
    final sync = SyncService(store, auth, settings, pro);
    await sync.syncNow();
    expect(pro.serverSaysProRequired, isTrue);
    expect(await store.dirtyRecords(limit: 10), hasLength(1));
    auth.calls.clear();
    await sync.syncNow();
    expect(auth.calls, ['GET /api/v1/sync/pull']);
  });
}
