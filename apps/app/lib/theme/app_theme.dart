import 'package:flutter/material.dart';
import 'package:tsudev_ui/tsudev_ui.dart';

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
  // UI1: khai ĐỦ cặp *Container (thiếu ⇒ M3 vẽ icon/chip đã chọn bằng onSecondary trắng trên nền nhạt, 1,2:1).
  final scheme = tsuCompleteContainers(
    ColorScheme(
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
    ),
    accent: p.primary,
    surface: p.bgSurface,
    onSurface: p.textPrimary,
  );
  final nav = TsuNavColors(
    background: p.bgSurface,
    indicator: p.primary.withValues(alpha: 0.14),
    selected: p.primary,
    unselected: p.iconNav,
    selectedLabel: p.textPrimary,
    unselectedLabel: p.textSecondary,
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
    // UI1 + DESIGN_SYSTEM mục 1: theme dùng chung của tsudev_ui (TsuNavColors ném lỗi khi biểu tượng/nền < 3:1);
    // test/icon_contrast_test.dart đo lại tại IconTheme thật, Sáng/Tối.
    navigationBarTheme: tsuNavigationBarTheme(nav),
    navigationRailTheme: tsuNavigationRailTheme(nav),
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
