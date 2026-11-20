import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/database.dart';
import '../services/settings.dart';
import '../core/format.dart';
import '../pro/pro_service.dart';
import 'auth_service.dart';

/// Đồng bộ hai chiều theo con trỏ phiên bản máy chủ (`rev`).
///
/// - Đẩy: mọi bản ghi `dirty` lên `/api/v1/sync/push`; máy chủ áp "ghi sau
///   thắng" theo `updated_at` và trả `rev` mới.
/// - Kéo: `/api/v1/sync/pull?since=<rev>` theo trang, áp vào kho cục bộ.
/// Không hỏi định kỳ (FREE_TIER_STACK.md mục 3): chạy khi mở app, sau khi lưu
/// phiên đo, và khi người dùng bấm "Đồng bộ ngay".
///
/// Đẩy lên đám mây là TsuDEV Pro (PRODUCT_POLICY 7.1 N2/N3): không có Pro còn hạn
/// thì KHÔNG gửi một byte dữ liệu đo nào (kể cả khi máy chủ sẽ từ chối). Kéo vẫn
/// chạy: hết Pro vẫn tải được bản sao đám mây trong 90 ngày (7.2).
class SyncService extends ChangeNotifier {
  SyncService(this._store, this._auth, this._settings, this._pro);

  final LocalStore _store;
  final AuthService _auth;
  final Settings _settings;
  final ProService _pro;

  bool running = false;
  String? lastError;
  DateTime? lastSyncAt;
  int lastPushed = 0;
  int lastPulled = 0;

  static const _kCursor = 'sync.cursor';
  static const _kLastSync = 'sync.last_at';

  Future<void> load() async {
    final raw = await _store.getValue(_kLastSync);
    lastSyncAt = raw == null ? null : DateTime.tryParse(raw);
    notifyListeners();
  }

  String get statusText {
    if (running) return 'Đang đồng bộ...';
    if (!_pro.isPro || _pro.serverSaysProRequired) {
      return 'Bản miễn phí: dữ liệu chỉ lưu trên thiết bị này. Đồng bộ lên đám mây cần TsuDEV Pro.';
    }
    if (lastError != null) return 'Lỗi đồng bộ: $lastError';
    if (lastSyncAt == null) return 'Chưa đồng bộ lần nào';
    return 'Đồng bộ lúc ${formatDateTime(lastSyncAt!)}';
  }

  /// Trả về `true` nếu chạy xong không lỗi.
  Future<bool> syncNow({bool onlyIfAuto = false}) async {
    if (running || !_auth.signedIn || _settings.offlineMode) return false;
    if (onlyIfAuto && !_settings.autoSync) return false;
    running = true;
    lastError = null;
    notifyListeners();
    try {
      lastPushed = _pro.isPro && !_pro.serverSaysProRequired ? await _push() : 0;
      lastPulled = await _pull();
      lastSyncAt = DateTime.now();
      await _store.setValue(_kLastSync, lastSyncAt!.toIso8601String());
      return true;
    } catch (e) {
      lastError = '$e';
      return false;
    } finally {
      running = false;
      notifyListeners();
    }
  }

  Future<int> _push() async {
    var pushed = 0;
    while (true) {
      final dirty = await _store.dirtyRecords(limit: 50);
      if (dirty.isEmpty) return pushed;
      final response = await _auth.authorized('POST', '/api/v1/sync/push', body: {
        'changes': [for (final r in dirty) r.toJson()],
      });
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, Object?>;
      if (response.statusCode == 402) {
        // Máy chủ là nơi quyết (N4): hết Pro ⇒ dừng đẩy, không thử lại.
        _pro.markProRequired();
        return pushed;
      }
      if (response.statusCode != 200) throw Exception(json['message'] ?? 'HTTP ${response.statusCode}');
      final results = (json['results'] as List<Object?>).cast<Map<String, Object?>>();
      var progressed = 0;
      for (final r in results) {
        final kind = r['kind'] as String, id = r['id'] as String;
        final original = dirty.firstWhere((d) => d.kind == kind && d.id == id);
        if (r['status'] == 'applied' || r['status'] == 'stale') {
          await _store.markClean(kind, id, original.updatedAt);
          progressed++;
        }
        if (r['status'] == 'stale' && r['record'] != null) {
          await _store.applyRemote(SyncRecord.fromJson(r['record'] as Map<String, Object?>));
        }
      }
      pushed += progressed;
      if (progressed == 0) throw Exception('máy chủ từ chối ${dirty.length} bản ghi');
    }
  }

  Future<int> _pull() async {
    var cursor = int.tryParse(await _store.getValue(_kCursor) ?? '') ?? 0;
    var pulled = 0;
    while (true) {
      final response = await _auth.authorized('GET', '/api/v1/sync/pull?since=$cursor&limit=200');
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, Object?>;
      if (response.statusCode != 200) throw Exception(json['message'] ?? 'HTTP ${response.statusCode}');
      for (final raw in (json['changes'] as List<Object?>).cast<Map<String, Object?>>()) {
        if (await _store.applyRemote(SyncRecord.fromJson(raw))) pulled++;
      }
      cursor = (json['cursor'] as num).toInt();
      await _store.setValue(_kCursor, '$cursor');
      if (json['has_more'] != true) return pulled;
    }
  }

  /// Gọi khi đăng xuất để lần đăng nhập sau kéo lại từ đầu.
  Future<void> resetCursor() => _store.removeValue(_kCursor);
}
