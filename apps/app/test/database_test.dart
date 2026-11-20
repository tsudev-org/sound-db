import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sound_db/data/database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// QA-01 (21/11/2026, Samsung SM-M325FV Android 13): SQLite hệ thống của máy KHÔNG có JSON1 ⇒
/// `json_extract` ném "no such function", Lịch sử trống dù đã lưu. Bộ test chạy SQLite của ffi (có JSON1) nên phải
/// chặn bằng cách cấm hàm JSON trong mọi câu SQL của app, và kiểm thứ tự dựa trên cột thật.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  String tmp() => '${Directory.systemTemp.createTempSync('sounddb-db').path}/db.sqlite';

  Map<String, Object?> sessionData(String label, String startedAt) => {
        'v': 1,
        'started_at': startedAt,
        'duration_s': 30,
        'label': label,
        'note': '',
        'summary': {'laeq': 50.0},
        'series': {'interval_s': 1, 'laeq': [50.0]},
      };

  test('SQL của app không dùng hàm JSON1 (SQLite Android của một số hãng không có)', () {
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final src = f.readAsStringSync();
      if (RegExp(r'json_(extract|each|tree|object|array|type|valid)\s*\(|->>').hasMatch(src)) offenders.add(f.path);
    }
    expect(offenders, isEmpty);
  });

  test('nâng cấp DB v1 ⇒ điền started_at, Lịch sử xếp mới nhất trước', () async {
    final path = tmp();
    final v1 = await openDatabase(path, version: 1, onCreate: (db, _) async {
      await db.execute('CREATE TABLE sessions (id TEXT PRIMARY KEY, data TEXT NOT NULL, updated_at INTEGER NOT NULL, '
          'deleted INTEGER NOT NULL DEFAULT 0, dirty INTEGER NOT NULL DEFAULT 1)');
      await db.execute('CREATE TABLE calibrations (id TEXT PRIMARY KEY, data TEXT NOT NULL, updated_at INTEGER NOT NULL, '
          'deleted INTEGER NOT NULL DEFAULT 0, dirty INTEGER NOT NULL DEFAULT 1)');
      await db.execute('CREATE TABLE kv (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
    });
    for (final (id, label, at) in [
      ('a', 'Cũ', '2026-11-01T08:00:00.000Z'),
      ('b', 'Mới nhất', '2026-11-20T08:00:00.000Z'),
      ('c', 'Giữa', '2026-11-10T08:00:00.000Z'),
      ('d', 'Hỏng', 'không-phải-ngày'),
    ]) {
      await v1.insert('sessions', {'id': id, 'data': jsonEncode(sessionData(label, at)), 'updated_at': 1, 'dirty': 0});
    }
    await v1.close();

    final store = await LocalStore.openAt(path);
    final rows = await store.listSessions(limit: 10, offset: 0);
    expect(rows.map((s) => s.label), ['Mới nhất', 'Giữa', 'Cũ', 'Hỏng']);
    expect(await store.countSessions(), 4);
  });

  test('DB mới: lưu/đồng bộ về ghi started_at, phân trang theo thứ tự', () async {
    final store = await LocalStore.openAt(tmp());
    await store.applyRemote(SyncRecord(kind: 'session', id: 'x', updatedAt: 1, deleted: false, data: sessionData('X', '2026-11-05T00:00:00Z')));
    await store.applyRemote(SyncRecord(kind: 'session', id: 'y', updatedAt: 1, deleted: false, data: sessionData('Y', '2026-11-06T00:00:00Z')));
    expect((await store.listSessions(limit: 1, offset: 0)).single.label, 'Y');
    expect((await store.listSessions(limit: 1, offset: 1)).single.label, 'X');
  });
}
