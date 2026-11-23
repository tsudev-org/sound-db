import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sound_db/core/vi_text.dart';
import 'package:sound_db/data/database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Tìm/lọc Lịch sử (SEARCH_AND_FILTER.md mục 3-4, 6; chủ dự án chốt phạm vi tối thiểu 24/11/2026):
/// tìm nhãn/ghi chú/thiết bị không dấu, lọc khoảng ngày, cùng một truy vấn với đếm + phân trang.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  String tmp() => '${Directory.systemTemp.createTempSync('sounddb-search').path}/db.sqlite';

  Map<String, Object?> data(String label, String at, {String note = '', String device = 'SM-M325FV'}) => {
    'v': 1,
    'started_at': at,
    'duration_s': 30,
    'label': label,
    'note': note,
    'device_model': device,
    'summary': {'laeq': 50.0},
    'series': {
      'interval_s': 1,
      'laeq': [50.0],
    },
  };

  group('viNormalizeText', () {
    test('bỏ dấu, đ/Đ, chữ thường, gộp khoảng trắng, NFC/NFD như nhau', () {
      expect(viNormalizeText('  Đường   Giải  Phóng '), 'duong giai phong');
      expect(viNormalizeText('Thư viện'), 'thu vien');
      // "ế" tổ hợp (e + U+0302 + U+0301) phải khớp bản dựng sẵn.
      expect(viNormalizeText('Bếp'), viNormalizeText('Bếp'));
    });
    test('bỏ dấu câu không cần cho so khớp', () {
      expect(viNormalizeText('Phòng ngủ, tầng 2!'), 'phong ngu tang 2');
    });
  });

  test('tìm không dấu ra có dấu, theo nhãn/ghi chú/thiết bị; AND giữa các từ', () async {
    final s = await LocalStore.openAt(tmp());
    await s.applyRemote(
      SyncRecord(
        kind: 'session',
        id: 'a',
        updatedAt: 1,
        deleted: false,
        data: data('Phòng ngủ', '2026-11-01T08:00:00Z'),
      ),
    );
    await s.applyRemote(
      SyncRecord(
        kind: 'session',
        id: 'b',
        updatedAt: 1,
        deleted: false,
        data: data('Đường Giải Phóng', '2026-11-10T08:00:00Z', note: 'giờ cao điểm'),
      ),
    );
    await s.applyRemote(
      SyncRecord(
        kind: 'session',
        id: 'c',
        updatedAt: 1,
        deleted: false,
        data: data('Văn phòng', '2026-11-20T08:00:00Z', device: 'Pixel 8'),
      ),
    );

    Future<List<String>> find(String q) async =>
        (await s.listSessions(limit: 10, offset: 0, query: SessionQuery(text: q))).map((e) => e.label).toList();

    expect(await find('phong'), ['Văn phòng', 'Đường Giải Phóng', 'Phòng ngủ']);
    expect(await find('duong giai'), ['Đường Giải Phóng']);
    expect(await find('cao diem'), ['Đường Giải Phóng']);
    expect(await find('pixel'), ['Văn phòng']);
    expect(await find('phong pixel'), ['Văn phòng']);
    expect(await find('khong co'), isEmpty);
    expect(await s.countSessions(query: const SessionQuery(text: 'phong ngu')), 1);
    // Dưới 2 ký tự (sau chuẩn hoá) ⇒ không lọc (mục 2.1). Ký tự đại diện LIKE bị bỏ như dấu câu ⇒ không lọt vào SQL.
    expect(await find('p'), hasLength(3));
    expect(await find('%_%'), hasLength(3));
    expect(viNormalizeText('a%b_c'), 'a b c');
  });

  test('lọc khoảng ngày [from, to) kết hợp với từ khoá', () async {
    final s = await LocalStore.openAt(tmp());
    for (final (id, label, at) in [
      ('a', 'Phòng A', '2026-11-01T08:00:00Z'),
      ('b', 'Phòng B', '2026-11-10T08:00:00Z'),
      ('c', 'Bếp', '2026-11-10T09:00:00Z'),
      ('d', 'Phòng D', '2026-11-20T08:00:00Z'),
    ]) {
      await s.applyRemote(SyncRecord(kind: 'session', id: id, updatedAt: 1, deleted: false, data: data(label, at)));
    }
    final q = SessionQuery(from: DateTime.utc(2026, 11, 5), to: DateTime.utc(2026, 11, 20, 8));
    expect((await s.listSessions(limit: 10, offset: 0, query: q)).map((e) => e.label), ['Bếp', 'Phòng B']);
    expect(await s.countSessions(query: q), 2);
    final q2 = SessionQuery(text: 'phong', from: DateTime.utc(2026, 11, 5));
    expect((await s.listSessions(limit: 10, offset: 0, query: q2)).map((e) => e.label), ['Phòng D', 'Phòng B']);
  });

  test('nâng cấp DB v2 ⇒ điền cột tìm kiếm cho bản ghi cũ', () async {
    final path = tmp();
    final v2 = await openDatabase(
      path,
      version: 2,
      onCreate: (db, _) async {
        for (final t in ['sessions', 'calibrations']) {
          await db.execute(
            'CREATE TABLE $t (id TEXT PRIMARY KEY, data TEXT NOT NULL, updated_at INTEGER NOT NULL, '
            'deleted INTEGER NOT NULL DEFAULT 0, dirty INTEGER NOT NULL DEFAULT 1)',
          );
        }
        await db.execute('ALTER TABLE sessions ADD COLUMN started_at INTEGER NOT NULL DEFAULT 0');
        await db.execute('CREATE TABLE kv (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
      },
    );
    await v2.insert('sessions', {
      'id': 'old',
      'data': jsonEncode(data('Phòng khách', '2026-11-01T08:00:00Z')),
      'updated_at': 1,
      'dirty': 0,
      'started_at': DateTime.utc(2026, 11).millisecondsSinceEpoch,
    });
    await v2.insert('sessions', {'id': 'bad', 'data': '{hỏng', 'updated_at': 1, 'dirty': 0, 'started_at': 0});
    await v2.close();

    final s = await LocalStore.openAt(path);
    expect(
      (await s.listSessions(limit: 10, offset: 0, query: const SessionQuery(text: 'phong khach'))).single.id,
      'old',
    );
    expect(await s.countSessions(), 2);
  });
}
