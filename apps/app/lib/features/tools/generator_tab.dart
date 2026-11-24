import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:sounddb_dsp/sounddb_dsp.dart';

import '../../core/format.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../../widgets/common.dart';

/// Bộ phát tín hiệu thử: dựng tệp WAV trong bộ nhớ rồi phát lặp.
class GeneratorTab extends StatefulWidget {
  const GeneratorTab({super.key});

  @override
  State<GeneratorTab> createState() => _GeneratorTabState();
}

class _GeneratorTabState extends State<GeneratorTab> with WidgetsBindingObserver {
  // Tạo lười: chỉ khởi tạo bộ phát âm thanh khi người dùng bấm Phát.
  AudioPlayer? _playerInstance;
  AudioPlayer get _player => _playerInstance ??= _createPlayer();
  StreamSubscription<PlayerState>? _stateSub;
  final SignalGenerator _generator = SignalGenerator(48000);
  bool _playing = false;
  double _logFrequency = math.log(1000);
  double _volumeDb = -12;

  double get _frequency => math.exp(_logFrequency);

  AudioPlayer _createPlayer() {
    final player = AudioPlayer(playerId: 'sounddb-generator');
    // QA-09: hệ điều hành có thể tạm dừng/dừng trình phát (mất tiêu điểm âm thanh, cuộc gọi...) ⇒ nút theo trạng
    // thái THẬT của trình phát, không chỉ theo lần bấm.
    _stateSub = player.onPlayerStateChanged.listen((s) {
      final playing = s == PlayerState.playing;
      if (mounted && !playing && _playing) setState(() => _playing = false);
    }, onError: (_) {});
    return player;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /// QA-09: ra nền ⇒ dừng hẳn (an toàn thính giác - người dùng không còn thấy nút Dừng), nút về "Phát".
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_playing && (state == AppLifecycleState.paused || state == AppLifecycleState.hidden)) {
      _playerInstance?.stop();
      setState(() => _playing = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stateSub?.cancel();
    _playerInstance?.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    _generator
      ..frequencyHz = _frequency
      ..amplitude = math.pow(10, _volumeDb / 20).toDouble();
    if (!_playing) return;
    final seconds = _generator.waveform == Waveform.logSweep ? _generator.sweepSeconds : 2.0;
    final wav = _generator.renderWav(seconds);
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(BytesSource(wav, mimeType: 'audio/wav'));
    } catch (e) {
      if (!mounted) return;
      showMessage(context, context.l10n.playFailed('$e'));
      setState(() => _playing = false);
    }
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.stop();
      if (mounted) setState(() => _playing = false);
    } else {
      setState(() => _playing = true);
      await _apply();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tonal = _generator.waveform.index <= Waveform.triangle.index;
    return ListView(padding: const EdgeInsets.all(SdbSpacing.s4), children: [
      NoticeBanner(
        message: context.l10n.generatorWarning,
      ),
      const SizedBox(height: SdbSpacing.s4),
      Wrap(spacing: SdbSpacing.s2, runSpacing: SdbSpacing.s2, children: [
        for (final w in Waveform.values)
          ChoiceChip(
            label: Text(waveformLabel(context.l10n, w)),
            selected: _generator.waveform == w,
            onSelected: (_) {
              setState(() => _generator.waveform = w);
              _apply();
            },
          ),
      ]),
      const SizedBox(height: SdbSpacing.s4),
      if (tonal) ...[
        Text(context.l10n.frequencyValue(formatHz(_frequency)), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        Slider(
          min: math.log(20),
          max: math.log(20000),
          value: _logFrequency,
          label: formatHz(_frequency),
          onChanged: (v) => setState(() => _logFrequency = v),
          onChangeEnd: (_) => _apply(),
        ),
        Wrap(spacing: SdbSpacing.s2, children: [
          for (final hz in const [50.0, 100.0, 440.0, 1000.0, 4000.0, 10000.0])
            OutlinedButton(
              onPressed: () {
                setState(() => _logFrequency = math.log(hz));
                _apply();
              },
              child: Text(formatHz(hz)),
            ),
        ]),
      ],
      if (_generator.waveform == Waveform.logSweep)
        Text(context.l10n.sweepNote(formatNumber(_generator.sweepSeconds, digits: 0)),
            style: TextStyle(color: p.textSecondary)),
      const SizedBox(height: SdbSpacing.s4),
      Text(context.l10n.signalVolume(formatNumber(_volumeDb, digits: 0))),
      Slider(
        min: -60,
        max: 0,
        divisions: 60,
        value: _volumeDb,
        onChanged: (v) => setState(() => _volumeDb = v),
        onChangeEnd: (_) => _apply(),
      ),
      const SizedBox(height: SdbSpacing.s4),
      FilledButton.icon(
        onPressed: _toggle,
        icon: Icon(_playing ? Icons.stop : Icons.play_arrow),
        label: Text(_playing ? context.l10n.stopPlaying : context.l10n.play),
      ),
    ]);
  }
}
