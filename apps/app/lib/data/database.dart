import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/vi_text.dart';
import 'models.dart';

/// Bộ lọc Lịch sử (SEARCH_AND_FILTER.md mục 4, 6): từ khoá không dấu + khoảng `[from, to)` theo mốc bắt đầu.
/// Từ khoá chuẩn hoá ngắn hơn [minQueryLength] ⇒ không lọc theo chữ (mục 2.1).
class SessionQuery {
  const SessionQuery({this.text = '', this.from, this.to});

  static const minQueryLength = 2;
  static const none = SessionQuery();

  final String text;
  final DateTime? from;
  final DateTime? to;

  List<String> get terms {
    final n = viNormalizeText(text);
    return n.length < minQueryLength ? const [] : n.split(' ');
  }

  bool get isActive => terms.isNotEmpty || from != null || to != null;

  /// Mệnh đề WHERE + tham số. Từ khoá đã bỏ mọi dấu câu (gồm `%`, `_`) nên không cần ESCAPE cho LIKE.
  (String, List<Object?>) where() {
    final w = ['deleted = 0'];
    final args = <Object?>[];
    for (final t in terms) {
      w.add('search_norm LIKE ?');
      args.add('%$t%');
    }
    if (from != null) {
      w.add('started_at >= ?');
      args.add(from!.millisecondsSinceEpoch);
    }
    if (to != null) {
      w.add('started_at < ?');
      args.add(to!.millisecondsSinceEpoch);
    }
    return (w.join(' AND '), args);
  }
}

/// Kho cục bộ (SQLite). Hai bảng bản ghi đồng bộ được (`sessions`,
/// `calibrations`) cùng khuôn: id, data JSON, updated_at (ms UTC), deleted, dirty.
class LocalStore {
  LocalStore._(this._db);

  final Database _db;

  static Future<LocalStore> open() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    return openAt(p.join(dir.path, 'sound_db.sqlite'));
  }

  /// Mở tại đường dẫn cho trước (test dùng `inMemoryDatabasePath`).
  static Future<LocalStore> openAt(String path) async {
    final db = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        for (final table in const ['sessions', 'calibrations']) {
          await db.execute('''
            CREATE TABLE $table (
              id TEXT PRIMARY KEY,
              data TEXT NOT NULL,
              updated_at INTEGER NOT NULL,
              deleted INTEGER NOT NULL DEFAULT 0,
              dirty INTEGER NOT NULL DEFAULT 1
            )''');
          await db.execute('CREATE INDEX ${table}_dirty ON $table(dirty)');
        }
        await _addStartedAt(db);
        await _addSearch(db);
        await db.execute('CREATE TABLE kv (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
      },
      onUpgrade: (db, from, to) async {
        if (from < 2) await _addStartedAt(db, backfill: true);
        if (from < 3) await _addSearch(db, backfill: true);
      },
    );
    return LocalStore._(db);
  }

  /// v2 (QA-01): cột `started_at` (ms UTC) để xếp Lịch sử. KHÔNG dùng `json_extract`: SQLite hệ thống của một số máy
  /// Android (Samsung Android 13) không có JSON1. Điền lại bằng Dart từ `data`.
  static Future<void> _addStartedAt(DatabaseExecutor db, {bool backfill = false}) async {
    await db.execute('ALTER TABLE sessions ADD COLUMN started_at INTEGER NOT NULL DEFAULT 0');
    await db.execute('CREATE INDEX sessions_started ON sessions(deleted, started_at)');
    if (!backfill) return;
    final rows = await db.query('sessions', columns: ['id', 'data']);
    for (final r in rows) {
      Map<String, Object?> data;
      try {
        data = jsonDecode(r['data'] as String) as Map<String, Object?>;
      } on FormatException {
        continue;
      }
      await db.update('sessions', {'started_at': startedAtMs(data)}, where: 'id = ?', whereArgs: [r['id']]);
    }
  }

  /// v3: cột `search_norm` = nhãn + ghi chú + thiết bị đã chuẩn hoá, tính lúc GHI (SEARCH_AND_FILTER.md mục 4).
  static Future<void> _addSearch(DatabaseExecutor db, {bool backfill = false}) async {
    await db.execute("ALTER TABLE sessions ADD COLUMN search_norm TEXT NOT NULL DEFAULT ''");
    if (!backfill) return;
    final rows = await db.query('sessions', columns: ['id', 'data']);
    for (final r in rows) {
      Map<String, Object?> data;
      try {
        data = jsonDecode(r['data'] as String) as Map<String, Object?>;
      } on FormatException {
        continue;
      }
      await db.update('sessions', {'search_norm': searchNorm(data)}, where: 'id = ?', whereArgs: [r['id']]);
    }
  }

  static String searchNorm(Map<String, Object?> data) =>
      viNormalizeText([data['label'], data['note'], data['device_model']].whereType<String>().join(' '));

  /// Mốc bắt đầu (ms UTC) từ dữ liệu phiên; thiếu/hỏng ⇒ 0 (xếp cuối).
  static int startedAtMs(Map<String, Object?> data) =>
      DateTime.tryParse(data['started_at'] as String? ?? '')?.millisecondsSinceEpoch ?? 0;

  // ---- khóa-giá trị (cài đặt, con trỏ đồng bộ) ----
  Future<String?> getValue(String key) async {
    final rows = await _db.query('kv', where: 'key = ?', whereArgs: [key], limit: 1);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> setValue(String key, String value) =>
      _db.insert('kv', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> removeValue(String key) => _db.delete('kv', where: 'key = ?', whereArgs: [key]);

  // ---- phiên đo ----
  Future<void> saveSession(MeasurementSession s) =>
      _upsert('sessions', s.id, s.toData(), s.updatedAt, s.deleted, s.dirty);

  Future<int> countSessions({SessionQuery query = SessionQuery.none}) async {
    final (w, args) = query.where();
    return Sqflite.firstIntValue(await _db.rawQuery('SELECT COUNT(*) FROM sessions WHERE $w', args)) ?? 0;
  }

  Future<List<MeasurementSession>> listSessions({
    required int limit,
    required int offset,
    SessionQuery query = SessionQuery.none,
  }) async {
    final (w, args) = query.where();
    final rows = await _db.query(
      'sessions',
      where: w,
      whereArgs: args,
      orderBy: 'started_at DESC, id DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(_session).toList();
  }

  Future<MeasurementSession?> getSession(String id) async {
    final rows = await _db.query('sessions', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : _session(rows.first);
  }

  MeasurementSession _session(Map<String, Object?> r) => MeasurementSession.fromData(
    r['id'] as String,
    jsonDecode(r['data'] as String) as Map<String, Object?>,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(r['updated_at'] as int, isUtc: true),
    deleted: r['deleted'] == 1,
    dirty: r['dirty'] == 1,
  );

  // ---- hiệu chuẩn ----
  Future<void> saveCalibration(CalibrationProfile c) =>
      _upsert('calibrations', c.id, c.toData(), c.updatedAt, c.deleted, c.dirty);

  Future<List<CalibrationProfile>> listCalibrations() async {
    final rows = await _db.query('calibrations', where: 'deleted = 0', orderBy: 'updated_at DESC');
    return [
      for (final r in rows)
        CalibrationProfile.fromData(
          r['id'] as String,
          jsonDecode(r['data'] as String) as Map<String, Object?>,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(r['updated_at'] as int, isUtc: true),
          dirty: r['dirty'] == 1,
        ),
    ];
  }

  // ---- đồng bộ ----
  Future<void> _upsert(
    String table,
    String id,
    Map<String, Object?> data,
    DateTime updatedAt,
    bool deleted,
    bool dirty,
  ) => _db.insert(table, {
    'id': id,
    'data': jsonEncode(data),
    'updated_at': updatedAt.toUtc().millisecondsSinceEpoch,
    'deleted': deleted ? 1 : 0,
    'dirty': dirty ? 1 : 0,
    if (table == 'sessions') 'started_at': startedAtMs(data),
    if (table == 'sessions') 'search_norm': searchNorm(data),
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  static String tableOf(String kind) => switch (kind) {
    'session' => 'sessions',
    'calibration' => 'calibrations',
    _ => throw ArgumentError('loại bản ghi lạ: $kind'),
  };

  /// Bản ghi chưa đẩy lên máy chủ.
  Future<List<SyncRecord>> dirtyRecords({int limit = 200}) async {
    final out = <SyncRecord>[];
    for (final kind in const ['session', 'calibration']) {
      final rows = await _db.query(tableOf(kind), where: 'dirty = 1', limit: limit);
      out.addAll(
        rows.map(
          (r) => SyncRecord(
            kind: kind,
            id: r['id'] as String,
            updatedAt: r['updated_at'] as int,
            deleted: r['deleted'] == 1,
            data: jsonDecode(r['data'] as String) as Map<String, Object?>,
          ),
        ),
      );
    }
    return out;
  }

  Future<void> markClean(String kind, String id, int updatedAt) =>
      _db.update(tableOf(kind), {'dirty': 0}, where: 'id = ? AND updated_at = ?', whereArgs: [id, updatedAt]);

  /// Áp bản ghi từ máy chủ theo "ghi sau thắng": bỏ qua nếu bản cục bộ chưa
  /// đẩy và mới hơn (lượt đẩy kế sẽ thắng ở máy chủ).
  Future<bool> applyRemote(SyncRecord remote) async {
    final table = tableOf(remote.kind);
    final rows = await _db.query(table, where: 'id = ?', whereArgs: [remote.id], limit: 1);
    if (rows.isNotEmpty) {
      final local = rows.first;
      if (local['dirty'] == 1 && (local['updated_at'] as int) > remote.updatedAt) return false;
    }
    await _upsert(
      table,
      remote.id,
      remote.data,
      DateTime.fromMillisecondsSinceEpoch(remote.updatedAt, isUtc: true),
      remote.deleted,
      false,
    );
    return true;
  }

  /// "Đăng xuất và xóa dữ liệu cục bộ" (AUTH_AND_ACCOUNT.md mục 14.2).
  Future<void> wipe() async {
    await _db.delete('sessions');
    await _db.delete('calibrations');
    await _db.delete('kv');
  }
}

class SyncRecord {
  const SyncRecord({
    required this.kind,
    required this.id,
    required this.updatedAt,
    required this.deleted,
    required this.data,
  });

  final String kind;
  final String id;
  final int updatedAt;
  final bool deleted;
  final Map<String, Object?> data;

  Map<String, Object?> toJson() => {'kind': kind, 'id': id, 'updated_at': updatedAt, 'deleted': deleted, 'data': data};

  static SyncRecord fromJson(Map<String, Object?> j) => SyncRecord(
    kind: j['kind'] as String,
    id: j['id'] as String,
    updatedAt: (j['updated_at'] as num).toInt(),
    deleted: j['deleted'] == true,
    data: (j['data'] as Map<String, Object?>?) ?? const {},
  );
}
