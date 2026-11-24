import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../theme/tokens.g.dart';

/// Trục tần số logarit dùng chung cho phổ và phổ đồ.
class LogAxis {
  const LogAxis(this.minHz, this.maxHz);
  final double minHz;
  final double maxHz;

  double toX(double hz, double width) =>
      width * (math.log(hz.clamp(minHz, maxHz)) - math.log(minHz)) / (math.log(maxHz) - math.log(minHz));

  double toHz(double x, double width) =>
      math.exp(math.log(minHz) + (x / width).clamp(0.0, 1.0) * (math.log(maxHz) - math.log(minHz)));

  static const ticks = [20.0, 50.0, 100.0, 200.0, 500.0, 1000.0, 2000.0, 5000.0, 10000.0, 20000.0];
}

TextPainter _label(String text, Color color, double size) =>
    TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: size)), textDirection: TextDirection.ltr)
      ..layout();

void _gridDb(Canvas canvas, Size size, double minDb, double maxDb, SdbPalette p, double left) {
  final grid = Paint()
    ..color = p.chartGrid
    ..strokeWidth = 1;
  final span = maxDb - minDb;
  final step = span > 80 ? 20.0 : 10.0;
  for (var db = (minDb / step).ceil() * step; db <= maxDb; db += step) {
    final y = size.height * (1 - (db - minDb) / span);
    canvas.drawLine(Offset(left, y), Offset(size.width, y), grid);
    _label(db.toStringAsFixed(0), p.chartAxis, 10).paint(canvas, Offset(2, y - 6));
  }
}

/// Lưới + nhãn dB của đồ thị mức (lớp tĩnh dưới [LevelHistoryPainter] - nhãn chữ tốn layout, không vẽ lại theo nhịp).
class DbGridPainter extends CustomPainter {
  const DbGridPainter({required this.palette, this.minDb = 20, this.maxDb = 120});

  final SdbPalette palette;
  final double minDb, maxDb;

  @override
  void paint(Canvas canvas, Size size) => _gridDb(canvas, size, minDb, maxDb, palette, LevelHistoryPainter.left);

  @override
  bool shouldRepaint(DbGridPainter old) => old.palette != palette || old.minDb != minDb || old.maxDb != maxDb;
}

/// Đồ thị mức theo thời gian, tô màu theo vùng an toàn/lưu ý/nguy hại. Lưới ở [DbGridPainter].
/// [values] bị sửa tại chỗ ⇒ [version] (tăng mỗi lần đổi) quyết định có vẽ lại không.
class LevelHistoryPainter extends CustomPainter {
  LevelHistoryPainter(this.values, this.palette,
      {this.minDb = 20, this.maxDb = 120, this.capacity = 1200, required this.version});

  static const double left = 26.0;
  final List<double> values;
  final SdbPalette palette;
  final double minDb, maxDb;
  final int capacity;
  final int version;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final width = size.width - left;
    double y(double db) => size.height * (1 - ((db.isFinite ? db : minDb) - minDb).clamp(0, maxDb - minDb) / (maxDb - minDb));
    final path = Path();
    final start = capacity - values.length;
    for (var i = 0; i < values.length; i++) {
      final x = left + width * (start + i) / (capacity - 1);
      i == 0 ? path.moveTo(x, y(values[i])) : path.lineTo(x, y(values[i]));
    }
    final last = values.last;
    final color = last >= SdbMeterZones.danger
        ? palette.chartLevelDanger
        : last >= SdbMeterZones.caution
            ? palette.chartLevelCaution
            : palette.chartLevelSafe;
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(LevelHistoryPainter old) =>
      old.version != version || old.palette != palette || old.minDb != minDb || old.maxDb != maxDb;
}

/// Phổ FFT trên trục tần số log, kèm đường giữ đỉnh và đánh dấu đỉnh mạnh nhất.
class SpectrumPainter extends CustomPainter {
  SpectrumPainter({
    required this.spectrum,
    required this.peakHold,
    required this.binHz,
    required this.axis,
    required this.minDb,
    required this.maxDb,
    required this.palette,
    this.peakHz,
    this.cursorHz,
  });

  final Float64List spectrum;
  final Float64List peakHold;
  final double binHz;
  final LogAxis axis;
  final double minDb, maxDb;
  final SdbPalette palette;
  final double? peakHz;
  final double? cursorHz;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 26.0, bottom = 16.0;
    final plot = Size(size.width - left, size.height - bottom);
    canvas.save();
    _gridDb(canvas, plot, minDb, maxDb, palette, left);
    final grid = Paint()..color = palette.chartGrid;
    for (final hz in LogAxis.ticks) {
      if (hz < axis.minHz || hz > axis.maxHz) continue;
      final x = left + axis.toX(hz, plot.width);
      canvas.drawLine(Offset(x, 0), Offset(x, plot.height), grid);
      _label(hz >= 1000 ? '${(hz / 1000).toStringAsFixed(0)}k' : hz.toStringAsFixed(0), palette.chartAxis, 10)
          .paint(canvas, Offset(x - 8, plot.height + 2));
    }
    double y(double db) => plot.height * (1 - ((db.isFinite ? db : minDb) - minDb).clamp(0, maxDb - minDb) / (maxDb - minDb));

    Path build(Float64List data) {
      final path = Path();
      var started = false;
      // Gộp các bin rơi vào cùng một cột điểm ảnh (lấy cực đại) để vẽ nhanh và không mất đỉnh.
      var lastX = -1.0, colMax = double.negativeInfinity;
      for (var k = 1; k < data.length; k++) {
        final hz = k * binHz;
        if (hz < axis.minHz) continue;
        if (hz > axis.maxHz) break;
        final x = left + axis.toX(hz, plot.width);
        colMax = math.max(colMax, data[k]);
        if (x - lastX >= 1) {
          started ? path.lineTo(x, y(colMax)) : path.moveTo(x, y(colMax));
          started = true;
          lastX = x;
          colMax = double.negativeInfinity;
        }
      }
      return path;
    }

    if (spectrum.isNotEmpty) {
      final line = build(spectrum);
      final fill = Path.from(line)
        ..lineTo(size.width, plot.height)
        ..lineTo(left, plot.height)
        ..close();
      canvas.drawPath(fill, Paint()..color = palette.chartFill);
      canvas.drawPath(
          line,
          Paint()
            ..color = palette.chartLine
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }
    if (peakHold.isNotEmpty) {
      canvas.drawPath(
          build(peakHold),
          Paint()
            ..color = palette.chartPeak
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
    }
    for (final (hz, color) in [(peakHz, palette.chartPeak), (cursorHz, palette.textPrimary)]) {
      if (hz == null || hz < axis.minHz || hz > axis.maxHz) continue;
      final x = left + axis.toX(hz, plot.width);
      canvas.drawLine(Offset(x, 0), Offset(x, plot.height), Paint()..color = color.withValues(alpha: 0.7));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(SpectrumPainter old) => true;
}

/// Biểu đồ cột dải octave.
class BandsPainter extends CustomPainter {
  BandsPainter({required this.levels, required this.labels, required this.minDb, required this.maxDb, required this.palette});

  final List<double> levels;
  final List<String> labels;
  final double minDb, maxDb;
  final SdbPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 26.0, bottom = 18.0;
    final plot = Size(size.width - left, size.height - bottom);
    _gridDb(canvas, plot, minDb, maxDb, palette, left);
    if (levels.isEmpty) return;
    final slot = plot.width / levels.length;
    final labelEvery = slot < 22 ? 3 : 1;
    for (var i = 0; i < levels.length; i++) {
      final v = levels[i].isFinite ? levels[i] : minDb;
      final h = plot.height * ((v - minDb).clamp(0, maxDb - minDb) / (maxDb - minDb));
      final rect = Rect.fromLTWH(left + i * slot + slot * 0.12, plot.height - h, slot * 0.76, h);
      canvas.drawRRect(RRect.fromRectAndCorners(rect, topLeft: const Radius.circular(2), topRight: const Radius.circular(2)),
          Paint()..color = palette.chartLine);
      if (i % labelEvery == 0) {
        final tp = _label(labels[i], palette.chartAxis, 9);
        tp.paint(canvas, Offset(left + i * slot + slot / 2 - tp.width / 2, plot.height + 3));
      }
    }
  }

  @override
  bool shouldRepaint(BandsPainter old) => true;
}

/// Phổ đồ (thác nước): dựng ảnh RGBA từ các hàng phổ rồi vẽ một lần.
class SpectrogramView extends StatefulWidget {
  const SpectrogramView({super.key, required this.rows, required this.minDb, required this.maxDb, required this.version});

  final List<Float32List> rows;
  final double minDb, maxDb;
  final int version;

  @override
  State<SpectrogramView> createState() => _SpectrogramViewState();
}

class _SpectrogramViewState extends State<SpectrogramView> {
  ui.Image? _image;
  int _built = -1;
  bool _building = false;

  static Color _colorAt(double t) {
    final stops = spectrogramStops;
    final scaled = t.clamp(0.0, 1.0) * (stops.length - 1);
    final i = scaled.floor().clamp(0, stops.length - 2);
    return Color.lerp(stops[i], stops[i + 1], scaled - i)!;
  }

  static final List<Color> _lut = List.generate(256, (i) => _colorAt(i / 255));

  void _rebuild() {
    if (_building || widget.rows.isEmpty || _built == widget.version) return;
    _building = true;
    final rows = widget.rows;
    final width = rows.first.length, height = rows.length;
    final pixels = Uint8List(width * height * 4);
    final span = widget.maxDb - widget.minDb;
    for (var r = 0; r < height; r++) {
      final row = rows[height - 1 - r];
      for (var c = 0; c < width; c++) {
        final t = ((row[c] - widget.minDb) / span).clamp(0.0, 1.0);
        final color = _lut[(t * 255).round()];
        final o = (r * width + c) * 4;
        pixels[o] = (color.r * 255).round();
        pixels[o + 1] = (color.g * 255).round();
        pixels[o + 2] = (color.b * 255).round();
        pixels[o + 3] = 255;
      }
    }
    final version = widget.version;
    ui.decodeImageFromPixels(pixels, width, height, ui.PixelFormat.rgba8888, (image) {
      _building = false;
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() {
        _image?.dispose();
        _image = image;
        _built = version;
      });
    });
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _rebuild();
    final image = _image;
    if (image == null) return const SizedBox.expand();
    return RawImage(image: image, fit: BoxFit.fill, filterQuality: FilterQuality.low);
  }
}

String axisHzLabel(double hz) => formatHz(hz);
