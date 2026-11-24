import 'package:flutter/material.dart';

import 'tokens.g.dart';

/// Lựa chọn giao diện theo ECOSYSTEM_IDENTITY.md mục 4.1: chỉ Sáng/Tối/Hệ thống,
/// chưa lưu lựa chọn ⇒ Hệ thống (PRODUCT_POLICY mục 1.2); giá trị cũ `warm` đọc thành `light`.
enum ThemeChoice {
  light,
  dark,
  system;

  static ThemeChoice parse(String? raw) => switch (raw) {
    'light' || 'warm' => ThemeChoice.light,
    'dark' => ThemeChoice.dark,
    _ => ThemeChoice.system,
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
    // UI1 (24/11/2026): khai ĐỦ cặp *Container. Thiếu thì M3 lấy secondary/onSecondary ⇒ icon đang chọn của thanh điều
    // hướng, Chip đã chọn... vẽ bằng onSecondary (trắng) trên nền nhạt - không thấy (1,2:1).
    primaryContainer: p.bgSubtle,
    onPrimaryContainer: p.textPrimary,
    secondaryContainer: p.bgHover,
    onSecondaryContainer: p.textPrimary,
    tertiaryContainer: p.bgSubtle,
    onTertiaryContainer: p.textPrimary,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SdbRadius.control)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.textPrimary,
        side: BorderSide(color: p.borderControl),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SdbRadius.control)),
      ),
    ),
    // UI1 + DESIGN_SYSTEM mục 1: biểu tượng trên nền THẬT >= 3:1 ở mọi trạng thái (test/icon_contrast_test.dart).
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.bgSurface,
      indicatorColor: p.primary.withValues(alpha: 0.14),
      surfaceTintColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? p.primary : p.iconNav),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          color: s.contains(WidgetState.selected) ? p.textPrimary : p.textSecondary,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: p.bgSurface,
      indicatorColor: p.primary.withValues(alpha: 0.14),
      selectedIconTheme: IconThemeData(color: p.primary),
      unselectedIconTheme: IconThemeData(color: p.iconNav),
      selectedLabelTextStyle: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600),
      unselectedLabelTextStyle: TextStyle(color: p.textSecondary, fontWeight: FontWeight.w500),
    ),
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
