import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';

/// Mặt đồng hồ mức âm - bố cục chữ ký `do-luong` của Sound Db (tsudev-standards v5.0.0, DESIGN_SYSTEM 1.2.2):
/// cung 0..130 dB quét 240°, vành ngoài tô vùng an toàn / lưu ý / nguy hại theo [SdbMeterZones], cung mức hiện tại
/// bằng màu nhấn của sản phẩm. [child] (số đo lớn) đặt ở tâm. Cùng hình học với mặt đồng hồ ở trang chủ website.
class LevelDial extends StatelessWidget {
  const LevelDial({super.key, required this.level, required this.child, this.size = 300});

  /// Mức dB hiện tại; NaN (chưa đo) ⇒ chỉ vẽ ray.
  final double level;
  final Widget child;
  final double size;

  static const double maxDb = 130;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: size,
      height: size * 196 / 240,
      child: CustomPaint(
        painter: _DialPainter(level: level, palette: p),
        child: Align(alignment: const Alignment(0, 0.22), child: child),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({required this.level, required this.palette});

  final double level;
  final SdbPalette palette;

  static const double _start = 150 * math.pi / 180;
  static const double _sweep = 240 * math.pi / 180;

  double _angle(double db) => _sweep * (db.clamp(0, LevelDial.maxDb) / LevelDial.maxDb);

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 240; // hệ toạ độ 240 x 196 như bản web
    final c = Offset(120 * k, 120 * k);
    Rect r(double radius) => Rect.fromCircle(center: c, radius: radius * k);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14 * k
      ..strokeCap = StrokeCap.round
      ..color = palette.borderStrong;
    canvas.drawArc(r(100), _start, _sweep, false, track);

    final zone = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * k;
    void band(double a, double b, Color color) =>
        canvas.drawArc(r(112), _start + _angle(a), _angle(b) - _angle(a), false, zone..color = color);
    band(0, SdbMeterZones.caution, palette.chartLevelSafe);
    band(SdbMeterZones.caution, SdbMeterZones.danger, palette.chartLevelCaution);
    band(SdbMeterZones.danger, LevelDial.maxDb, palette.chartLevelDanger);

    final tick = Paint()
      ..strokeWidth = 1.2 * k
      ..color = palette.textMuted;
    for (var db = 0.0; db <= LevelDial.maxDb; db += 10) {
      final a = _start + _angle(db);
      final inner = db % 30 == 0 ? 76.0 : 81.0;
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * 86 * k,
        c + Offset(math.cos(a), math.sin(a)) * inner * k,
        tick,
      );
    }

    if (!level.isNaN && level > 0) {
      final value = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14 * k
        ..strokeCap = StrokeCap.round
        ..color = palette.primary;
      canvas.drawArc(r(100), _start, _angle(level), false, value);
    }
  }

  @override
  bool shouldRepaint(_DialPainter old) => old.level != level || old.palette != palette;
}
