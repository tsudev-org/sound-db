import 'package:flutter/widgets.dart';
import 'package:sounddb_dsp/sounddb_dsp.dart';

import '../data/database.dart';
import '../theme/app_theme.dart';

/// Cài đặt người dùng, lưu ở bảng `kv` của kho cục bộ.
class Settings extends ChangeNotifier {
  Settings(this._store);

  final LocalStore _store;

  ThemeChoice theme = ThemeChoice.system;

  /// Ngôn ngữ đã chọn (`vi`/`en`); null = theo hệ thống (PRODUCT_POLICY mục 1.1).
  String? localeCode;
  Locale? get locale => localeCode == null ? null : Locale(localeCode!);
  Weighting weighting = Weighting.a;
  TimeWeighting timeWeighting = TimeWeighting.fast;

  /// Offset hiệu chuẩn (dB): mức = 10 log10(ms) + offset. Chưa hiệu chuẩn thì
  /// dùng giá trị ước lượng điển hình của micro điện thoại và cảnh báo rõ.
  double calibrationOffsetDb = defaultOffsetDb;
  bool calibrated = false;
  int fftSize = 8192;
  WindowKind window = WindowKind.hann;
  double spectrumMinDb = 0;
  double spectrumMaxDb = 120;
  double a4Hz = 440;
  bool keepScreenOn = true;

  /// AUTH_AND_ACCOUNT.md mục 14.1: chặn MỌI kết nối ra, kể cả đồng bộ.
  bool offlineMode = false;
  bool autoSync = true;

  static const double defaultOffsetDb = 120;
  static const supportedLocaleCodes = ['vi', 'en'];
  static const fftSizes = [1024, 2048, 4096, 8192, 16384, 32768];

  Future<void> load() async {
    final values = <String, String?>{};
    for (final key in const [
      'theme', 'locale', 'weighting', 'time_weighting', 'calibration_offset_db', 'calibrated', 'fft_size', 'window', //
      'spectrum_min_db', 'spectrum_max_db', 'a4_hz', 'keep_screen_on', 'offline_mode', 'auto_sync',
    ]) {
      values[key] = await _store.getValue('setting.$key');
    }
    await _migrateLocale(values);
    await _migrateDefaults(values);
    theme = ThemeChoice.parse(values['theme']);
    localeCode = supportedLocaleCodes.contains(values['locale']) ? values['locale'] : null;
    weighting = Weighting.values.asNameMap()[values['weighting']] ?? Weighting.a;
    timeWeighting = TimeWeighting.values.asNameMap()[values['time_weighting']] ?? TimeWeighting.fast;
    calibrationOffsetDb = double.tryParse(values['calibration_offset_db'] ?? '') ?? defaultOffsetDb;
    calibrated = values['calibrated'] == 'true';
    final fft = int.tryParse(values['fft_size'] ?? '');
    fftSize = fftSizes.contains(fft) ? fft! : 8192;
    window = WindowKind.values.asNameMap()[values['window']] ?? WindowKind.hann;
    spectrumMinDb = double.tryParse(values['spectrum_min_db'] ?? '') ?? 0;
    spectrumMaxDb = double.tryParse(values['spectrum_max_db'] ?? '') ?? 120;
    a4Hz = double.tryParse(values['a4_hz'] ?? '') ?? 440;
    keepScreenOn = values['keep_screen_on'] != 'false';
    offlineMode = values['offline_mode'] == 'true';
    autoSync = values['auto_sync'] != 'false';
    notifyListeners();
  }

  /// Di trú một lần (PRODUCT_POLICY mục 1.2): máy đã cài bản mặc định Tối mà chưa từng chọn giao diện
  /// ⇒ ghi lại Tối để không đổi đột ngột. Máy mới (chưa có cài đặt/phiên đo nào) dùng mặc định Hệ thống.
  Future<void> _migrateDefaults(Map<String, String?> values) async {
    if (await _store.getValue('setting.defaults_v2') == 'true') return;
    final installedBefore = values.values.any((v) => v != null) || await _store.countSessions() > 0;
    if (installedBefore && values['theme'] == null) {
      values['theme'] = ThemeChoice.dark.name;
      await _store.setValue('setting.theme', ThemeChoice.dark.name);
    }
    await _store.setValue('setting.defaults_v2', 'true');
  }

  /// Di trú một lần khi thêm tiếng Anh: máy đã cài bản chỉ tiếng Việt mà chưa từng chọn ngôn ngữ ⇒ ghi lại `vi`
  /// để giao diện không đổi đột ngột sau cập nhật. Máy mới theo ngôn ngữ hệ thống.
  Future<void> _migrateLocale(Map<String, String?> values) async {
    if (await _store.getValue('setting.locale_v1') == 'true') return;
    final installedBefore = await _store.getValue('setting.defaults_v2') == 'true' ||
        values.values.any((v) => v != null) ||
        await _store.countSessions() > 0;
    if (installedBefore && values['locale'] == null) {
      values['locale'] = 'vi';
      await _store.setValue('setting.locale', 'vi');
    }
    await _store.setValue('setting.locale_v1', 'true');
  }

  Future<void> _save(String key, Object value) async {
    await _store.setValue('setting.$key', value is Enum ? value.name : '$value');
    notifyListeners();
  }

  Future<void> setTheme(ThemeChoice v) {
    theme = v;
    return _save('theme', v);
  }

  /// null = theo hệ thống.
  Future<void> setLocaleCode(String? code) async {
    localeCode = supportedLocaleCodes.contains(code) ? code : null;
    if (localeCode == null) {
      await _store.removeValue('setting.locale');
      notifyListeners();
      return;
    }
    return _save('locale', localeCode!);
  }

  Future<void> setWeighting(Weighting v) {
    weighting = v;
    return _save('weighting', v);
  }

  Future<void> setTimeWeighting(TimeWeighting v) {
    timeWeighting = v;
    return _save('time_weighting', v);
  }

  Future<void> setCalibration(double offsetDb, {required bool calibrated}) async {
    calibrationOffsetDb = offsetDb;
    this.calibrated = calibrated;
    await _store.setValue('setting.calibrated', '$calibrated');
    return _save('calibration_offset_db', offsetDb);
  }

  Future<void> setFft(int size, WindowKind w) async {
    fftSize = size;
    window = w;
    await _store.setValue('setting.window', w.name);
    return _save('fft_size', size);
  }

  Future<void> setSpectrumRange(double min, double max) async {
    spectrumMinDb = min;
    spectrumMaxDb = max;
    await _store.setValue('setting.spectrum_min_db', '$min');
    return _save('spectrum_max_db', max);
  }

  Future<void> setA4(double hz) {
    a4Hz = hz;
    return _save('a4_hz', hz);
  }

  Future<void> setKeepScreenOn(bool v) {
    keepScreenOn = v;
    return _save('keep_screen_on', v);
  }

  Future<void> setOfflineMode(bool v) {
    offlineMode = v;
    return _save('offline_mode', v);
  }

  Future<void> setAutoSync(bool v) {
    autoSync = v;
    return _save('auto_sync', v);
  }
}
