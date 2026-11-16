import 'package:flutter/material.dart';

import 'tokens.g.dart';

/// Lựa chọn giao diện theo ECOSYSTEM_IDENTITY.md mục 4.1: chỉ Sáng/Tối/Hệ thống,
/// mặc định Tối; giá trị cũ `warm` đọc thành `light`.
enum ThemeChoice {
  light('Sáng'),
  dark('Tối'),
  system('Hệ thống');

  const ThemeChoice(this.label);
  final String label;

  static ThemeChoice parse(String? raw) => switch (raw) {
        'light' || 'warm' => ThemeChoice.light,
        'system' => ThemeChoice.system,
        _ => ThemeChoice.dark,
      };

  ThemeMode get mode => switch (this) {
        ThemeChoice.light => ThemeMode.light,
        ThemeChoice.dark => ThemeMode.dark,
        ThemeChoice.system => ThemeMode.system,
      };
}

class SdbTheme extends ThemeExtension<SdbTheme> {
  const SdbTheme(this.palette);
  final SdbPalette palette;

  @override
  SdbTheme copyWith({SdbPalette? palette}) => SdbTheme(palette ?? this.palette);

  @override
  SdbTheme lerp(SdbTheme? other, double t) => t < 0.5 ? this : (other ?? this);
}

extension SdbThemeContext on BuildContext {
  SdbPalette get palette => Theme.of(this).extension<SdbTheme>()!.palette;
}

ThemeData buildTheme(Brightness brightness) {
  final p = brightness == Brightness.dark ? SdbPalette.dark : SdbPalette.light;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: p.primary,
    onPrimary: p.onPrimary,
    secondary: p.textLink,
    onSecondary: p.onPrimary,
    error: p.danger,
    onError: p.onStatus,
    surface: p.bgSurface,
    onSurface: p.textPrimary,
    onSurfaceVariant: p.textSecondary,
    outline: p.borderControl,
    outlineVariant: p.border,
    surfaceContainerLowest: p.bgBase,
    surfaceContainerLow: p.bgSurface,
    surfaceContainer: p.bgSubtle,
    surfaceContainerHigh: p.bgHover,
    surfaceContainerHighest: p.bgHover,
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(SdbRadius.md),
    borderSide: BorderSide(color: p.borderControl),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bgBase,
    canvasColor: p.bgBase,
    dividerColor: p.border,
    extensions: [SdbTheme(p)],
    appBarTheme: AppBarTheme(
      backgroundColor: p.bgBase,
      foregroundColor: p.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: p.bgSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SdbRadius.lg),
        side: BorderSide(color: p.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: BorderSide(color: p.focusRing, width: 2)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SdbRadius.md)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.textPrimary,
        side: BorderSide(color: p.borderControl),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SdbRadius.md)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.bgSurface,
      indicatorColor: p.bgHover,
      surfaceTintColor: Colors.transparent,
    ),
    navigationRailTheme: NavigationRailThemeData(backgroundColor: p.bgSurface, indicatorColor: p.bgHover),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: p.primary,
        selectedForegroundColor: p.onPrimary,
        side: BorderSide(color: p.borderControl),
      ),
    ),
    fontFamilyFallback: const ['Inter', 'SF Pro Text', 'Segoe UI', 'Roboto'],
  );
}
