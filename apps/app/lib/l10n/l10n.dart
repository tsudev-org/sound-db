import 'package:flutter/widgets.dart';
import 'package:sounddb_dsp/sounddb_dsp.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// Ngôn ngữ app (PRODUCT_POLICY mục 1.1): ngôn ngữ hệ thống nếu đã hỗ trợ, không thì tiếng Anh.
Locale resolveAppLocale(Locale? device) {
  final code = device?.languageCode;
  return AppLocalizations.supportedLocales.firstWhere((l) => l.languageCode == code, orElse: () => const Locale('en'));
}

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

AppLocalizations _active = lookupAppLocalizations(const Locale('vi'));

/// Chuỗi cho mã chạy ngoài cây widget (dịch vụ, thông báo lỗi). Đặt bởi `MaterialApp.builder` theo ngôn ngữ đang hiển thị.
AppLocalizations get l10nNow => _active;

/// Mã ngôn ngữ đang hiển thị (`vi`/`en`) - cho `core/format.dart`.
String get activeLanguage => _active.localeName;

void setActiveLocale(Locale locale) {
  if (_active.localeName != locale.languageCode) _active = lookupAppLocalizations(resolveAppLocale(locale));
}

/// Tên dạng sóng / cửa sổ: nhãn trong `sounddb_dsp` là tiếng Việt (gói thuật toán, không phụ thuộc giao diện).
String waveformLabel(AppLocalizations l, Waveform w) => switch (w) {
      Waveform.sine => l.waveSine,
      Waveform.square => l.waveSquare,
      Waveform.sawtooth => l.waveSawtooth,
      Waveform.triangle => l.waveTriangle,
      Waveform.whiteNoise => l.waveWhite,
      Waveform.pinkNoise => l.wavePink,
      Waveform.logSweep => l.waveSweep,
    };

String windowLabel(AppLocalizations l, WindowKind w) => switch (w) {
      WindowKind.rectangular => l.windowRectangular,
      WindowKind.flatTop => l.windowFlatTop,
      _ => w.label,
    };
