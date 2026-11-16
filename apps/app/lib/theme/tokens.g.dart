// TỆP SINH TỰ ĐỘNG bởi scripts/build-tokens.mjs - KHÔNG SỬA TAY.
// Nguồn: .standards/tokens/design-tokens.json + tokens/extensions.sound-db.json
// ignore_for_file: public_member_api_docs

import 'dart:ui' show Color;

class SdbPalette {
  const SdbPalette({
    required this.bgBase,
    required this.bgSurface,
    required this.bgSubtle,
    required this.bgHover,
    required this.border,
    required this.borderStrong,
    required this.borderControl,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textLink,
    required this.primary,
    required this.primaryHover,
    required this.primaryActive,
    required this.onPrimary,
    required this.focusRing,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.onStatus,
    required this.overlay,
    required this.chartLine,
    required this.chartFill,
    required this.chartPeak,
    required this.chartGrid,
    required this.chartAxis,
    required this.chartLevelSafe,
    required this.chartLevelCaution,
    required this.chartLevelDanger,
  });

  final Color bgBase;
  final Color bgSurface;
  final Color bgSubtle;
  final Color bgHover;
  final Color border;
  final Color borderStrong;
  final Color borderControl;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textLink;
  final Color primary;
  final Color primaryHover;
  final Color primaryActive;
  final Color onPrimary;
  final Color focusRing;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color onStatus;
  final Color overlay;
  final Color chartLine;
  final Color chartFill;
  final Color chartPeak;
  final Color chartGrid;
  final Color chartAxis;
  final Color chartLevelSafe;
  final Color chartLevelCaution;
  final Color chartLevelDanger;

  static const light = SdbPalette(
    bgBase: Color(0xFFFAFAFA),
    bgSurface: Color(0xFFFFFFFF),
    bgSubtle: Color(0xFFF4F4F5),
    bgHover: Color(0xFFEBEBED),
    border: Color(0xFFE4E4E7),
    borderStrong: Color(0xFFD4D4D8),
    borderControl: Color(0xFF71717A),
    textPrimary: Color(0xFF0A0A0A),
    textSecondary: Color(0xFF3F3F46),
    textMuted: Color(0xFF52525B),
    textLink: Color(0xFF0757A3),
    primary: Color(0xFF0868C4),
    primaryHover: Color(0xFF0757A3),
    primaryActive: Color(0xFF064785),
    onPrimary: Color(0xFFFFFFFF),
    focusRing: Color(0xFF0868C4),
    success: Color(0xFF15803D),
    warning: Color(0xFFB45309),
    danger: Color(0xFFDC2626),
    info: Color(0xFF0369A1),
    onStatus: Color(0xFFFFFFFF),
    overlay: Color(0x730A0A0A),
    chartLine: Color(0xFF0868C4),
    chartFill: Color(0x240868C4),
    chartPeak: Color(0xFFB45309),
    chartGrid: Color(0xFFD4D4D8),
    chartAxis: Color(0xFF52525B),
    chartLevelSafe: Color(0xFF15803D),
    chartLevelCaution: Color(0xFFB45309),
    chartLevelDanger: Color(0xFFDC2626),
  );

  static const dark = SdbPalette(
    bgBase: Color(0xFF0A0A0A),
    bgSurface: Color(0xFF0F1114),
    bgSubtle: Color(0xFF15181D),
    bgHover: Color(0xFF1C2027),
    border: Color(0xFF22272F),
    borderStrong: Color(0xFF2C323C),
    borderControl: Color(0xFF6E6E6E),
    textPrimary: Color(0xFFEDEDED),
    textSecondary: Color(0xFFB4B4B4),
    textMuted: Color(0xFF8F8F8F),
    textLink: Color(0xFF7DD3FC),
    primary: Color(0xFF38BDF8),
    primaryHover: Color(0xFF7DD3FC),
    primaryActive: Color(0xFF0EA5E9),
    onPrimary: Color(0xFF0A0A0A),
    focusRing: Color(0xFF38BDF8),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    info: Color(0xFF38BDF8),
    onStatus: Color(0xFF0A0A0A),
    overlay: Color(0x99000000),
    chartLine: Color(0xFF38BDF8),
    chartFill: Color(0x2E38BDF8),
    chartPeak: Color(0xFFFBBF24),
    chartGrid: Color(0xFF2C323C),
    chartAxis: Color(0xFF8F8F8F),
    chartLevelSafe: Color(0xFF4ADE80),
    chartLevelCaution: Color(0xFFFBBF24),
    chartLevelDanger: Color(0xFFF87171),
  );
}

const List<Color> spectrogramStops = [
  Color(0xFF000004),
  Color(0xFF320A5E),
  Color(0xFF781B6C),
  Color(0xFFBB3654),
  Color(0xFFEC6824),
  Color(0xFFFBB41A),
  Color(0xFFFCFFA4),
];

class SdbRadius {
  static const double none = 0;
  static const double sm = 4;
  static const double md = 6;
  static const double lg = 8;
}

class SdbSpacing {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;
}

class SdbMeterZones {
  static const double caution = 70;
  static const double danger = 85;
}
