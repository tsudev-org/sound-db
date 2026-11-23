// QA-03 (máy thật 23/11/2026): bấm "Tiếp tục" sau "Tạm dừng" xoá sạch phiên đang đo (LAeq, Max/Min, đồ thị 2 phút,
// mốc bắt đầu) - start() gán state = starting TRƯỚC khi kiểm "có đang tạm dừng không".
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart' show InputDevice;
import 'package:sound_db/data/database.dart';
import 'package:sound_db/services/audio_input.dart';
import 'package:sound_db/services/measurement.dart';
import 'package:sound_db/services/settings.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeInput extends AudioInput {
  _FakeInput() : super(sampleRate: 48000);
  final _c = StreamController<Float32List>.broadcast();
  @override
  Stream<Float32List> get samples => _c.stream;
  @override
  Future<void> start({InputDevice? device}) async {}
  @override
  Future<void> stop() async {}
  void push(Float32List b) => _c.add(b);
}

Float32List _tone(int n) =>
    Float32List.fromList([for (var i = 0; i < n; i++) 0.1 * math.sin(2 * math.pi * 1000 * i / 48000)]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MeasurementController m;
  late _FakeInput input;

  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final store = await LocalStore.openAt('${Directory.systemTemp.createTempSync('sounddb-resume').path}/db.sqlite');
    final settings = Settings(store);
    await settings.load();
    input = _FakeInput();
    m = MeasurementController(settings, input: input);
  });

  Future<void> feed(int seconds) async {
    for (var i = 0; i < seconds * 10; i++) {
      input.push(_tone(4800));
    }
    await Future<void>.delayed(Duration.zero);
  }

  test('Tiếp tục sau Tạm dừng giữ nguyên phiên đang đo', () async {
    await m.start();
    expect(m.state, MeterState.running);
    await feed(3);
    final started = m.startedAt;
    final history = m.levelHistory.length;
    expect(history, greaterThan(20));
    final samples = m.engine.meter.snapshot().elapsedSeconds;

    await m.pause();
    expect(m.state, MeterState.paused);
    await m.start();
    expect(m.state, MeterState.running);

    expect(m.startedAt, started, reason: 'mốc bắt đầu phiên không được đặt lại');
    expect(m.levelHistory.length, history, reason: 'đồ thị 2 phút không được xoá');
    expect(m.engine.meter.snapshot().elapsedSeconds, samples, reason: 'Leq/Max/Min tích luỹ không được xoá');

    await feed(1);
    expect(m.levelHistory.length, greaterThan(history));
    await m.pause();
  });

  // QA-04 (máy thật 23/11/2026): Ticker xin khung ở MỌI vsync (90 Hz) dù dữ liệu chỉ đổi mỗi 50 ms ⇒ ~46 khung/giây,
  // mỗi khung raster lại toàn màn (~10 ms GPU trên Mali-G52) và DSP nặng chạy TRONG khung (build p90 25 ms) ⇒ giật
  // 27-56%. Nhịp hiển thị phải là bộ hẹn giờ, chỉ vẽ khi có dữ liệu mới.
  test('Đang đo không giữ callback theo từng khung hình', () async {
    final before = SchedulerBinding.instance.transientCallbackCount;
    await m.start();
    expect(SchedulerBinding.instance.transientCallbackCount, before);
    await m.pause();
  });

  test('Nhịp hiển thị vẫn cập nhật ảnh chụp mức khi đang đo', () async {
    await m.start();
    await feed(1);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(m.snapshot, isNotNull);
    await m.pause();
  });

  test('Bắt đầu mới (không phải tiếp tục) vẫn mở phiên mới', () async {
    await m.start();
    await feed(2);
    expect(m.levelHistory, isNotEmpty);
    m.resetSession();
    expect(m.levelHistory, isEmpty);
    await m.pause();
  });
}
