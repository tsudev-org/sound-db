import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:record/record.dart';
import '../l10n/l10n.dart';

class AudioInputException implements Exception {
  AudioInputException(this.message, {this.code});

  /// Quyền micro bị từ chối - giao diện đưa người dùng tới trang quyền của app (QA-10).
  static const permissionDenied = 'mic_permission';

  final String message;
  final String? code;
  @override
  String toString() => message;
}

/// Thu âm micro thành luồng mẫu Float32 [-1, 1].
///
/// Tắt mọi xử lý của hệ điều hành (AGC, khử vọng, khử ồn) và trên Android chọn
/// nguồn `unprocessed`: các bộ xử lý đó đổi mức âm theo thời gian, làm máy đo
/// sai một cách không đoán trước được.
class AudioInput {
  AudioInput({this.sampleRate = 48000});

  final int sampleRate;
  static const _sessionChannel = MethodChannel('com.tsudev.sounddb/audio_session');
  // Tạo lười: chỉ gọi plugin thu âm khi người dùng thật sự bắt đầu đo.
  late final AudioRecorder _recorder = AudioRecorder();
  bool _recorderCreated = false;
  StreamSubscription<Uint8List>? _subscription;
  final StreamController<Float32List> _controller = StreamController<Float32List>.broadcast();
  int _carry = -1;

  Stream<Float32List> get samples => _controller.stream;

  Future<List<InputDevice>> devices() {
    _recorderCreated = true;
    return _recorder.listInputDevices();
  }

  Future<void> start({InputDevice? device}) async {
    _recorderCreated = true;
    if (!await _recorder.hasPermission()) {
      throw AudioInputException(l10nNow.errMicPermission, code: AudioInputException.permissionDenied);
    }
    final config = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: sampleRate,
      numChannels: 1,
      autoGain: false,
      echoCancel: false,
      noiseSuppress: false,
      device: device,
      androidConfig: const AndroidRecordConfig(audioSource: AndroidAudioSource.unprocessed),
      iosConfig: const IosRecordConfig(categoryOptions: [IosAudioCategoryOption.allowBluetooth]),
    );
    if (!await _recorder.isEncoderSupported(AudioEncoder.pcm16bits)) {
      throw AudioInputException(l10nNow.errPcm16);
    }
    if (Platform.isIOS) {
      // iOS: tự đặt AVAudioSession mode .measurement (ios/Runner/AppDelegate.swift) thay vì để plugin đặt mode mặc
      // định có xử lý giọng nói. Lỗi kênh không chặn đo, chỉ mất chế độ đo lường.
      await _recorder.ios?.manageAudioSession(false);
      try {
        await _sessionChannel.invokeMethod<double>('configureMeasurement');
      } on PlatformException catch (_) {
        await _recorder.ios?.manageAudioSession(true);
      }
    }
    final stream = await _recorder.startStream(config);
    _carry = -1;
    _subscription = stream.listen(_onBytes, onError: (Object e) => _controller.addError(AudioInputException('$e')));
  }

  /// PCM16 little-endian. Gói byte có thể bị cắt lẻ giữa một mẫu: giữ byte thừa
  /// để ghép với gói sau thay vì làm lệch pha toàn bộ phần còn lại.
  void _onBytes(Uint8List bytes) {
    var offset = 0;
    final total = bytes.length + (_carry >= 0 ? 1 : 0);
    final out = Float32List(total ~/ 2);
    var index = 0;
    if (_carry >= 0 && bytes.isNotEmpty) {
      out[index++] = _toSample(_carry, bytes[0]);
      offset = 1;
      _carry = -1;
    }
    for (; offset + 1 < bytes.length; offset += 2) {
      out[index++] = _toSample(bytes[offset], bytes[offset + 1]);
    }
    if (offset < bytes.length) _carry = bytes[offset];
    if (index > 0) _controller.add(index == out.length ? out : Float32List.sublistView(out, 0, index));
  }

  static double _toSample(int lo, int hi) {
    var v = lo | (hi << 8);
    if (v >= 0x8000) v -= 0x10000;
    return v / 32768.0;
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    if (_recorderCreated && await _recorder.isRecording()) await _recorder.stop();
  }

  Future<void> dispose() async {
    await stop();
    if (_recorderCreated) await _recorder.dispose();
    await _controller.close();
  }

  static String get platformName => Platform.operatingSystem;
}
