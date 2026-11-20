import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @navMeter.
  ///
  /// In vi, this message translates to:
  /// **'Đo mức'**
  String get navMeter;

  /// No description provided for @navAnalysis.
  ///
  /// In vi, this message translates to:
  /// **'Phân tích'**
  String get navAnalysis;

  /// No description provided for @navTools.
  ///
  /// In vi, this message translates to:
  /// **'Công cụ'**
  String get navTools;

  /// No description provided for @navHistory.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get navSettings;

  /// No description provided for @meterTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đo mức âm'**
  String get meterTitle;

  /// No description provided for @meterReferenceTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Mức tham chiếu thường gặp'**
  String get meterReferenceTooltip;

  /// No description provided for @meterNotCalibrated.
  ///
  /// In vi, this message translates to:
  /// **'Chưa hiệu chuẩn: số đo là ước lượng theo micro điển hình (sai số có thể vài dB). Vào Cài đặt > Hiệu chuẩn để đo chính xác.'**
  String get meterNotCalibrated;

  /// No description provided for @meterLevelSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Mức âm {name} {value} đề-xi-ben'**
  String meterLevelSemantics(String name, String value);

  /// No description provided for @timeFast.
  ///
  /// In vi, this message translates to:
  /// **'Nhanh'**
  String get timeFast;

  /// No description provided for @timeSlow.
  ///
  /// In vi, this message translates to:
  /// **'Chậm'**
  String get timeSlow;

  /// No description provided for @timeImpulse.
  ///
  /// In vi, this message translates to:
  /// **'Xung'**
  String get timeImpulse;

  /// No description provided for @meterLast2Min.
  ///
  /// In vi, this message translates to:
  /// **'2 phút gần nhất'**
  String get meterLast2Min;

  /// No description provided for @meterLeqHint.
  ///
  /// In vi, this message translates to:
  /// **'Mức tương đương liên tục của cả phiên'**
  String get meterLeqHint;

  /// No description provided for @meterPeakHint.
  ///
  /// In vi, this message translates to:
  /// **'Đỉnh tức thời'**
  String get meterPeakHint;

  /// No description provided for @meterL10Hint.
  ///
  /// In vi, this message translates to:
  /// **'Mức bị vượt 10% thời gian'**
  String get meterL10Hint;

  /// No description provided for @meterL90Hint.
  ///
  /// In vi, this message translates to:
  /// **'Ồn nền'**
  String get meterL90Hint;

  /// No description provided for @duration.
  ///
  /// In vi, this message translates to:
  /// **'Thời lượng'**
  String get duration;

  /// No description provided for @resetSession.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại phiên'**
  String get resetSession;

  /// No description provided for @saveSession.
  ///
  /// In vi, this message translates to:
  /// **'Lưu phiên đo'**
  String get saveSession;

  /// No description provided for @doseTitle.
  ///
  /// In vi, this message translates to:
  /// **'Liều tiếp xúc tiếng ồn'**
  String get doseTitle;

  /// No description provided for @doseNioshRule.
  ///
  /// In vi, this message translates to:
  /// **'85 dBA / 8 giờ, hệ số trao đổi 3 dB'**
  String get doseNioshRule;

  /// No description provided for @doseOshaRule.
  ///
  /// In vi, this message translates to:
  /// **'90 dBA / 8 giờ, hệ số trao đổi 5 dB'**
  String get doseOshaRule;

  /// No description provided for @doseNote.
  ///
  /// In vi, this message translates to:
  /// **'Tính trên LAS từ khi bắt đầu phiên. 100% là giới hạn tiếp xúc cho một ngày làm việc.'**
  String get doseNote;

  /// No description provided for @refTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mức âm tham chiếu (dBA)'**
  String get refTitle;

  /// No description provided for @ref0.
  ///
  /// In vi, this message translates to:
  /// **'Ngưỡng nghe'**
  String get ref0;

  /// No description provided for @ref20.
  ///
  /// In vi, this message translates to:
  /// **'Thì thầm, phòng ngủ yên tĩnh'**
  String get ref20;

  /// No description provided for @ref40.
  ///
  /// In vi, this message translates to:
  /// **'Thư viện, văn phòng yên tĩnh'**
  String get ref40;

  /// No description provided for @ref60.
  ///
  /// In vi, this message translates to:
  /// **'Trò chuyện bình thường'**
  String get ref60;

  /// No description provided for @ref70.
  ///
  /// In vi, this message translates to:
  /// **'Máy hút bụi, đường phố đông'**
  String get ref70;

  /// No description provided for @ref85.
  ///
  /// In vi, this message translates to:
  /// **'Giao thông dày đặc - ngưỡng tiếp xúc 8 giờ (NIOSH)'**
  String get ref85;

  /// No description provided for @ref95.
  ///
  /// In vi, this message translates to:
  /// **'Xe máy tăng ga, máy khoan'**
  String get ref95;

  /// No description provided for @ref110.
  ///
  /// In vi, this message translates to:
  /// **'Hòa nhạc, vũ trường'**
  String get ref110;

  /// No description provided for @ref120.
  ///
  /// In vi, this message translates to:
  /// **'Còi xe cứu thương sát tai - ngưỡng đau'**
  String get ref120;

  /// No description provided for @defaultSessionLabel.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đo {time}'**
  String defaultSessionLabel(String time);

  /// No description provided for @sessionFallback.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đo'**
  String get sessionFallback;

  /// No description provided for @sessionName.
  ///
  /// In vi, this message translates to:
  /// **'Tên phiên'**
  String get sessionName;

  /// No description provided for @cancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get save;

  /// No description provided for @sessionTooShort.
  ///
  /// In vi, this message translates to:
  /// **'Phiên quá ngắn để lưu (cần ít nhất 1 giây).'**
  String get sessionTooShort;

  /// No description provided for @savedLabel.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu \"{label}\".'**
  String savedLabel(String label);

  /// No description provided for @settingsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settingsTitle;

  /// No description provided for @sectionAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản và đồng bộ'**
  String get sectionAccount;

  /// No description provided for @sectionCalibration.
  ///
  /// In vi, this message translates to:
  /// **'Hiệu chuẩn'**
  String get sectionCalibration;

  /// No description provided for @micCalibration.
  ///
  /// In vi, this message translates to:
  /// **'Hiệu chuẩn micro'**
  String get micCalibration;

  /// No description provided for @calibratedOffset.
  ///
  /// In vi, this message translates to:
  /// **'Đã hiệu chuẩn · offset {offset}'**
  String calibratedOffset(String offset);

  /// No description provided for @notCalibratedOffset.
  ///
  /// In vi, this message translates to:
  /// **'Chưa hiệu chuẩn · dùng offset ước lượng {offset}'**
  String notCalibratedOffset(String offset);

  /// No description provided for @sectionTheme.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện'**
  String get sectionTheme;

  /// No description provided for @themeLight.
  ///
  /// In vi, this message translates to:
  /// **'Sáng'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In vi, this message translates to:
  /// **'Tối'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống'**
  String get themeSystem;

  /// No description provided for @sectionLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get sectionLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In vi, this message translates to:
  /// **'Theo hệ thống'**
  String get languageSystem;

  /// No description provided for @sectionMeasurement.
  ///
  /// In vi, this message translates to:
  /// **'Đo lường'**
  String get sectionMeasurement;

  /// No description provided for @keepScreenOn.
  ///
  /// In vi, this message translates to:
  /// **'Giữ màn hình sáng khi đang đo'**
  String get keepScreenOn;

  /// No description provided for @a4Reference.
  ///
  /// In vi, this message translates to:
  /// **'Tần số chuẩn A4'**
  String get a4Reference;

  /// No description provided for @sectionPrivacy.
  ///
  /// In vi, this message translates to:
  /// **'Quyền riêng tư'**
  String get sectionPrivacy;

  /// No description provided for @offlineMode.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ ngoại tuyến hoàn toàn'**
  String get offlineMode;

  /// No description provided for @offlineModeHint.
  ///
  /// In vi, this message translates to:
  /// **'Chặn mọi kết nối ra ngoài, kể cả đăng nhập và đồng bộ. Đo lường vẫn chạy đủ.'**
  String get offlineModeHint;

  /// No description provided for @audioNeverLeaves.
  ///
  /// In vi, this message translates to:
  /// **'Âm thanh không bao giờ rời thiết bị'**
  String get audioNeverLeaves;

  /// No description provided for @audioNeverLeavesHint.
  ///
  /// In vi, this message translates to:
  /// **'Sound Db chỉ xử lý âm thanh trong bộ nhớ, không ghi âm. Bản miễn phí không gửi dữ liệu đo lên internet; khi đồng bộ (TsuDEV Pro), chỉ các con số đo được gửi đi.'**
  String get audioNeverLeavesHint;

  /// No description provided for @sectionAbout.
  ///
  /// In vi, this message translates to:
  /// **'Giới thiệu'**
  String get sectionAbout;

  /// No description provided for @logoSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Logo Sound Db'**
  String get logoSemantics;

  /// No description provided for @versionLine.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản {version} · Một sản phẩm của TsuDEV'**
  String versionLine(String version);

  /// No description provided for @proUntil.
  ///
  /// In vi, this message translates to:
  /// **'TsuDEV Pro tới {date}'**
  String proUntil(String date);

  /// No description provided for @freePlan.
  ///
  /// In vi, this message translates to:
  /// **'Bản miễn phí'**
  String get freePlan;

  /// No description provided for @proTileOn.
  ///
  /// In vi, this message translates to:
  /// **'Đồng bộ và sao lưu đám mây đang bật.'**
  String get proTileOn;

  /// No description provided for @proTileOff.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu chỉ lưu trên thiết bị. Xem gói TsuDEV Pro để đồng bộ giữa các thiết bị, hoặc ủng hộ TsuDEV.'**
  String get proTileOff;

  /// No description provided for @guestMode.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang dùng ở chế độ khách - mọi chức năng đo đều mở.'**
  String get guestMode;

  /// No description provided for @signInFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập thất bại: {error}'**
  String signInFailed(String error);

  /// No description provided for @signInButton.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập tài khoản TsuDEV'**
  String get signInButton;

  /// No description provided for @signInHint.
  ///
  /// In vi, this message translates to:
  /// **'Mở trình duyệt hệ thống tới tsudev.com (Google, GitHub hoặc tài khoản TsuDEV). Đăng nhập để dùng gói TsuDEV Pro (đồng bộ và sao lưu đám mây) và huy hiệu; bản miễn phí không cần đăng nhập.'**
  String get signInHint;

  /// No description provided for @syncNow.
  ///
  /// In vi, this message translates to:
  /// **'Đồng bộ ngay'**
  String get syncNow;

  /// No description provided for @autoSync.
  ///
  /// In vi, this message translates to:
  /// **'Tự đồng bộ khi mở app và sau khi lưu'**
  String get autoSync;

  /// No description provided for @manageOnWeb.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý thiết bị và dữ liệu trên web'**
  String get manageOnWeb;

  /// No description provided for @signOut.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get signOut;

  /// No description provided for @signOutWipe.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất và xóa dữ liệu cục bộ'**
  String get signOutWipe;

  /// No description provided for @signOutWipeHint.
  ///
  /// In vi, this message translates to:
  /// **'Xóa lịch sử, hiệu chuẩn và cài đặt trên máy này. Bản sao đã đồng bộ (nếu có) vẫn còn trên tài khoản.'**
  String get signOutWipeHint;

  /// No description provided for @wipeConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa dữ liệu trên máy này?'**
  String get wipeConfirmTitle;

  /// No description provided for @wipeConfirmBody.
  ///
  /// In vi, this message translates to:
  /// **'Bản ghi chưa đồng bộ sẽ mất vĩnh viễn.'**
  String get wipeConfirmBody;

  /// No description provided for @delete.
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get delete;

  /// No description provided for @calMethod94.
  ///
  /// In vi, this message translates to:
  /// **'Máy hiệu chuẩn 94 dB @ 1 kHz'**
  String get calMethod94;

  /// No description provided for @calMethod114.
  ///
  /// In vi, this message translates to:
  /// **'Máy hiệu chuẩn 114 dB @ 1 kHz'**
  String get calMethod114;

  /// No description provided for @calMethodReference.
  ///
  /// In vi, this message translates to:
  /// **'So với máy đo chuẩn (nhập số đọc)'**
  String get calMethodReference;

  /// No description provided for @micOpenFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được micro.'**
  String get micOpenFailed;

  /// No description provided for @offsetApplied.
  ///
  /// In vi, this message translates to:
  /// **'Đã áp dụng offset {offset}.'**
  String offsetApplied(String offset);

  /// No description provided for @currentOffset.
  ///
  /// In vi, this message translates to:
  /// **'Offset hiện tại: {offset}'**
  String currentOffset(String offset);

  /// No description provided for @currentOffsetDefault.
  ///
  /// In vi, this message translates to:
  /// **'Offset hiện tại: {offset} (mặc định, chưa hiệu chuẩn)'**
  String currentOffsetDefault(String offset);

  /// No description provided for @calReferenceHowTo.
  ///
  /// In vi, this message translates to:
  /// **'Đặt điện thoại sát máy đo chuẩn, cùng hướng về nguồn ồn ổn định (quạt, ồn hồng). Đo 10 giây rồi nhập LAeq mà máy chuẩn hiển thị trong cùng khoảng thời gian.'**
  String get calReferenceHowTo;

  /// No description provided for @calCalibratorHowTo.
  ///
  /// In vi, this message translates to:
  /// **'Lắp đầu micro vào khớp nối của máy hiệu chuẩn (hoặc áp sát nếu không vừa), bật máy hiệu chuẩn, giữ yên rồi bấm Đo. Kết quả dùng LZeq 10 giây.'**
  String get calCalibratorHowTo;

  /// No description provided for @referenceLaeq.
  ///
  /// In vi, this message translates to:
  /// **'LAeq của máy đo chuẩn (dB)'**
  String get referenceLaeq;

  /// No description provided for @measuringRemaining.
  ///
  /// In vi, this message translates to:
  /// **'Đang đo... còn {seconds} giây'**
  String measuringRemaining(String seconds);

  /// No description provided for @measureSeconds.
  ///
  /// In vi, this message translates to:
  /// **'Đo {seconds} giây'**
  String measureSeconds(String seconds);

  /// No description provided for @measuredWithOld.
  ///
  /// In vi, this message translates to:
  /// **'Đo được: {level} (với offset cũ)'**
  String measuredWithOld(String level);

  /// No description provided for @newOffset.
  ///
  /// In vi, this message translates to:
  /// **'Offset mới: {offset}'**
  String newOffset(String offset);

  /// No description provided for @apply.
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng'**
  String get apply;

  /// No description provided for @manualOffset.
  ///
  /// In vi, this message translates to:
  /// **'Nhập offset thủ công'**
  String get manualOffset;

  /// No description provided for @offsetRange.
  ///
  /// In vi, this message translates to:
  /// **'Offset phải là số trong 0-200 dB.'**
  String get offsetRange;

  /// No description provided for @restoreDefault.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục mặc định (bỏ hiệu chuẩn)'**
  String get restoreDefault;

  /// No description provided for @analysisTitle.
  ///
  /// In vi, this message translates to:
  /// **'Phân tích tần số'**
  String get analysisTitle;

  /// No description provided for @spectrumSettings.
  ///
  /// In vi, this message translates to:
  /// **'Thiết lập phổ'**
  String get spectrumSettings;

  /// No description provided for @tabFft.
  ///
  /// In vi, this message translates to:
  /// **'Phổ FFT'**
  String get tabFft;

  /// No description provided for @tabSpectrogram.
  ///
  /// In vi, this message translates to:
  /// **'Phổ đồ'**
  String get tabSpectrogram;

  /// No description provided for @tabOctave.
  ///
  /// In vi, this message translates to:
  /// **'Dải octave'**
  String get tabOctave;

  /// No description provided for @dominantFrequency.
  ///
  /// In vi, this message translates to:
  /// **'Tần số trội'**
  String get dominantFrequency;

  /// No description provided for @peakLevel.
  ///
  /// In vi, this message translates to:
  /// **'Mức đỉnh'**
  String get peakLevel;

  /// No description provided for @cursor.
  ///
  /// In vi, this message translates to:
  /// **'Con trỏ'**
  String get cursor;

  /// No description provided for @tapChart.
  ///
  /// In vi, this message translates to:
  /// **'Chạm biểu đồ'**
  String get tapChart;

  /// No description provided for @peakHold.
  ///
  /// In vi, this message translates to:
  /// **'Giữ đỉnh'**
  String get peakHold;

  /// No description provided for @clearPeak.
  ///
  /// In vi, this message translates to:
  /// **'Xóa đỉnh'**
  String get clearPeak;

  /// No description provided for @fftInfo.
  ///
  /// In vi, this message translates to:
  /// **'FFT {size} · {window} · {binHz} Hz/bin · trọng số {weighting}'**
  String fftInfo(String size, String window, String binHz, String weighting);

  /// No description provided for @spectrogramNote.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi hàng là một khung phổ (mới nhất ở trên), trục ngang là tần số log 20 Hz - {nyquist}.'**
  String spectrogramNote(String nyquist);

  /// No description provided for @lowBandWarning.
  ///
  /// In vi, this message translates to:
  /// **'Dải thấp nhất chỉ phủ {bins} bin FFT - tăng kích thước FFT (Thiết lập phổ) để dải tần thấp chính xác hơn.'**
  String lowBandWarning(String bins);

  /// No description provided for @bandNote.
  ///
  /// In vi, this message translates to:
  /// **'Mức dải (IEC 61260-1, hệ cơ số 10) trọng số {weighting}, từ phổ trung bình.'**
  String bandNote(String weighting);

  /// No description provided for @fftSize.
  ///
  /// In vi, this message translates to:
  /// **'Kích thước FFT'**
  String get fftSize;

  /// No description provided for @fftSamples.
  ///
  /// In vi, this message translates to:
  /// **'{n} mẫu'**
  String fftSamples(String n);

  /// No description provided for @window.
  ///
  /// In vi, this message translates to:
  /// **'Cửa sổ'**
  String get window;

  /// No description provided for @windowRectangular.
  ///
  /// In vi, this message translates to:
  /// **'Chữ nhật'**
  String get windowRectangular;

  /// No description provided for @displayRange.
  ///
  /// In vi, this message translates to:
  /// **'Thang hiển thị: {min} - {max} dB'**
  String displayRange(String min, String max);

  /// No description provided for @savedFile.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu {name}'**
  String savedFile(String name);

  /// No description provided for @deleteSessionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa phiên đo?'**
  String get deleteSessionTitle;

  /// No description provided for @deleteSessionBody.
  ///
  /// In vi, this message translates to:
  /// **'Phiên sẽ bị xóa trên máy này và trên mọi thiết bị đã đồng bộ.'**
  String get deleteSessionBody;

  /// No description provided for @actions.
  ///
  /// In vi, this message translates to:
  /// **'Thao tác'**
  String get actions;

  /// No description provided for @exportCsv.
  ///
  /// In vi, this message translates to:
  /// **'Xuất CSV'**
  String get exportCsv;

  /// No description provided for @exportJson.
  ///
  /// In vi, this message translates to:
  /// **'Xuất JSON'**
  String get exportJson;

  /// No description provided for @deleteSession.
  ///
  /// In vi, this message translates to:
  /// **'Xóa phiên'**
  String get deleteSession;

  /// No description provided for @doseNiosh.
  ///
  /// In vi, this message translates to:
  /// **'Liều NIOSH'**
  String get doseNiosh;

  /// No description provided for @doseOsha.
  ///
  /// In vi, this message translates to:
  /// **'Liều OSHA'**
  String get doseOsha;

  /// No description provided for @laeqOverTime.
  ///
  /// In vi, this message translates to:
  /// **'LAeq theo thời gian'**
  String get laeqOverTime;

  /// No description provided for @thirdOctaveAvg.
  ///
  /// In vi, this message translates to:
  /// **'Phổ 1/3 octave trung bình (LZeq)'**
  String get thirdOctaveAvg;

  /// No description provided for @calOffsetAtMeasure.
  ///
  /// In vi, this message translates to:
  /// **'Offset hiệu chuẩn khi đo: {offset}'**
  String calOffsetAtMeasure(String offset);

  /// No description provided for @historyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử đo'**
  String get historyTitle;

  /// No description provided for @reload.
  ///
  /// In vi, this message translates to:
  /// **'Tải lại'**
  String get reload;

  /// No description provided for @historyEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có phiên đo nào. Bấm \"Lưu phiên đo\" ở màn hình Đo mức để lưu lại kết quả.'**
  String get historyEmpty;

  /// No description provided for @historyLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không đọc được lịch sử đo trên thiết bị này. Dữ liệu vẫn còn; bấm Tải lại hoặc cập nhật ứng dụng.'**
  String get historyLoadFailed;

  /// No description provided for @notSynced.
  ///
  /// In vi, this message translates to:
  /// **' · chưa đồng bộ'**
  String get notSynced;

  /// No description provided for @toolsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Công cụ'**
  String get toolsTitle;

  /// No description provided for @tabPitch.
  ///
  /// In vi, this message translates to:
  /// **'Tần số & cao độ'**
  String get tabPitch;

  /// No description provided for @tabGenerator.
  ///
  /// In vi, this message translates to:
  /// **'Phát tín hiệu'**
  String get tabGenerator;

  /// No description provided for @pitchNotDetected.
  ///
  /// In vi, this message translates to:
  /// **'Chưa nhận ra cao độ'**
  String get pitchNotDetected;

  /// No description provided for @noteSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Nốt {note}, lệch {cents} cent'**
  String noteSemantics(String note, String cents);

  /// No description provided for @noPitchedSound.
  ///
  /// In vi, this message translates to:
  /// **'Chưa nhận ra âm có cao độ'**
  String get noPitchedSound;

  /// No description provided for @deviation.
  ///
  /// In vi, this message translates to:
  /// **'Lệch'**
  String get deviation;

  /// No description provided for @clarity.
  ///
  /// In vi, this message translates to:
  /// **'Độ rõ'**
  String get clarity;

  /// No description provided for @dominantFft.
  ///
  /// In vi, this message translates to:
  /// **'Tần số trội (FFT)'**
  String get dominantFft;

  /// No description provided for @dominantLevel.
  ///
  /// In vi, this message translates to:
  /// **'Mức trội'**
  String get dominantLevel;

  /// No description provided for @a4Standard.
  ///
  /// In vi, this message translates to:
  /// **'A4 chuẩn'**
  String get a4Standard;

  /// No description provided for @pitchNote.
  ///
  /// In vi, this message translates to:
  /// **'Cao độ dùng thuật toán McLeod (NSDF) trên khung 4096 mẫu, sai số < 1 cent với âm có họa âm. Tần số trội lấy trọng tâm công suất quanh đỉnh FFT - đúng cho cả tông thuần không có họa âm.'**
  String get pitchNote;

  /// No description provided for @playFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không phát được âm thanh: {error}'**
  String playFailed(String error);

  /// No description provided for @generatorWarning.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu ở âm lượng nhỏ. Tần số rất cao hoặc âm lượng lớn qua tai nghe có thể gây hại cho thính giác và loa.'**
  String get generatorWarning;

  /// No description provided for @frequencyValue.
  ///
  /// In vi, this message translates to:
  /// **'Tần số: {hz}'**
  String frequencyValue(String hz);

  /// No description provided for @sweepNote.
  ///
  /// In vi, this message translates to:
  /// **'Quét log 20 Hz - 20 kHz trong {seconds} giây, lặp lại.'**
  String sweepNote(String seconds);

  /// No description provided for @signalVolume.
  ///
  /// In vi, this message translates to:
  /// **'Âm lượng tín hiệu: {db} dBFS'**
  String signalVolume(String db);

  /// No description provided for @stopPlaying.
  ///
  /// In vi, this message translates to:
  /// **'Dừng phát'**
  String get stopPlaying;

  /// No description provided for @play.
  ///
  /// In vi, this message translates to:
  /// **'Phát'**
  String get play;

  /// No description provided for @waveSine.
  ///
  /// In vi, this message translates to:
  /// **'Sin'**
  String get waveSine;

  /// No description provided for @waveSquare.
  ///
  /// In vi, this message translates to:
  /// **'Vuông'**
  String get waveSquare;

  /// No description provided for @waveSawtooth.
  ///
  /// In vi, this message translates to:
  /// **'Răng cưa'**
  String get waveSawtooth;

  /// No description provided for @waveTriangle.
  ///
  /// In vi, this message translates to:
  /// **'Tam giác'**
  String get waveTriangle;

  /// No description provided for @waveWhite.
  ///
  /// In vi, this message translates to:
  /// **'Ồn trắng'**
  String get waveWhite;

  /// No description provided for @wavePink.
  ///
  /// In vi, this message translates to:
  /// **'Ồn hồng'**
  String get wavePink;

  /// No description provided for @waveSweep.
  ///
  /// In vi, this message translates to:
  /// **'Quét tần số'**
  String get waveSweep;

  /// No description provided for @pause.
  ///
  /// In vi, this message translates to:
  /// **'Tạm dừng'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get resume;

  /// No description provided for @startMeasuring.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu đo'**
  String get startMeasuring;

  /// No description provided for @error.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi'**
  String get error;

  /// No description provided for @notice.
  ///
  /// In vi, this message translates to:
  /// **'Lưu ý'**
  String get notice;

  /// No description provided for @perPage.
  ///
  /// In vi, this message translates to:
  /// **'/ trang'**
  String get perPage;

  /// No description provided for @previousPage.
  ///
  /// In vi, this message translates to:
  /// **'Trang trước'**
  String get previousPage;

  /// No description provided for @nextPage.
  ///
  /// In vi, this message translates to:
  /// **'Trang sau'**
  String get nextPage;

  /// No description provided for @errOfflineMode.
  ///
  /// In vi, this message translates to:
  /// **'Đang bật Chế độ ngoại tuyến hoàn toàn - tắt nó trong Cài đặt để đăng nhập.'**
  String get errOfflineMode;

  /// No description provided for @errBrowser.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được trình duyệt hệ thống.'**
  String get errBrowser;

  /// No description provided for @errLoginCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập bị hủy hoặc bị từ chối.'**
  String get errLoginCancelled;

  /// No description provided for @errStateMismatch.
  ///
  /// In vi, this message translates to:
  /// **'Phản hồi đăng nhập không khớp phiên - đã chặn để an toàn.'**
  String get errStateMismatch;

  /// No description provided for @errNoCode.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ không trả mã đăng nhập.'**
  String get errNoCode;

  /// No description provided for @errLoginTimeout.
  ///
  /// In vi, this message translates to:
  /// **'Hết 5 phút chờ đăng nhập - hãy thử lại.'**
  String get errLoginTimeout;

  /// No description provided for @loopbackDone.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận phản hồi đăng nhập. Bạn có thể đóng thẻ này và quay lại Sound Db.'**
  String get loopbackDone;

  /// No description provided for @errLoginFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập thất bại.'**
  String get errLoginFailed;

  /// No description provided for @errBadResponse.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ trả dữ liệu không hợp lệ (HTTP {status}).'**
  String errBadResponse(String status);

  /// No description provided for @errSignedOut.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đăng nhập.'**
  String get errSignedOut;

  /// No description provided for @syncRunning.
  ///
  /// In vi, this message translates to:
  /// **'Đang đồng bộ...'**
  String get syncRunning;

  /// No description provided for @syncFreePlan.
  ///
  /// In vi, this message translates to:
  /// **'Bản miễn phí: dữ liệu chỉ lưu trên thiết bị này. Đồng bộ lên đám mây cần TsuDEV Pro.'**
  String get syncFreePlan;

  /// No description provided for @syncError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi đồng bộ: {error}'**
  String syncError(String error);

  /// No description provided for @syncNever.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đồng bộ lần nào'**
  String get syncNever;

  /// No description provided for @syncLast.
  ///
  /// In vi, this message translates to:
  /// **'Đồng bộ lúc {time}'**
  String syncLast(String time);

  /// No description provided for @syncRejected.
  ///
  /// In vi, this message translates to:
  /// **'máy chủ từ chối {count} bản ghi'**
  String syncRejected(String count);

  /// No description provided for @errMicPermission.
  ///
  /// In vi, this message translates to:
  /// **'Sound Db cần quyền dùng micro để đo. Hãy cấp quyền trong cài đặt hệ thống.'**
  String get errMicPermission;

  /// No description provided for @errPcm16.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị không hỗ trợ thu PCM 16-bit.'**
  String get errPcm16;

  /// No description provided for @errMicOpen.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được micro: {error}'**
  String errMicOpen(String error);

  /// No description provided for @windowFlatTop.
  ///
  /// In vi, this message translates to:
  /// **'Đỉnh phẳng'**
  String get windowFlatTop;

  /// No description provided for @proStatus.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái'**
  String get proStatus;

  /// No description provided for @proActiveLine.
  ///
  /// In vi, this message translates to:
  /// **'TsuDEV Pro tới {date}: đồng bộ và sao lưu đám mây đang bật.'**
  String proActiveLine(String date);

  /// No description provided for @proExpiredLine.
  ///
  /// In vi, this message translates to:
  /// **'TsuDEV Pro đã hết hạn ngày {date}. Bản sao trên đám mây còn tải về được tới ngày {deleteDate}.'**
  String proExpiredLine(String date, String deleteDate);

  /// No description provided for @proFreeLine.
  ///
  /// In vi, this message translates to:
  /// **'Bản miễn phí: mọi chức năng đo đều mở; dữ liệu chỉ lưu trên thiết bị này, không gửi lên internet.'**
  String get proFreeLine;

  /// No description provided for @proFeaturesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Pro có gì'**
  String get proFeaturesTitle;

  /// No description provided for @proFeatures.
  ///
  /// In vi, this message translates to:
  /// **'• Đồng bộ lịch sử đo và hồ sơ hiệu chuẩn giữa các thiết bị cùng tài khoản.\n• Sao lưu lên đám mây, xem và tải về trên web (sound.tsudev.com).\n• Huy hiệu Pro cạnh tên tài khoản. Một gói dùng chung cho mọi sản phẩm TsuDEV.'**
  String get proFeatures;

  /// No description provided for @proPlaySoon.
  ///
  /// In vi, this message translates to:
  /// **'Mua TsuDEV Pro trong Google Play sẽ có ở bản cập nhật tới.'**
  String get proPlaySoon;

  /// No description provided for @proRenewWeb.
  ///
  /// In vi, this message translates to:
  /// **'Gia hạn trên tsudev.com'**
  String get proRenewWeb;

  /// No description provided for @proBuyWeb.
  ///
  /// In vi, this message translates to:
  /// **'Mua TsuDEV Pro trên tsudev.com'**
  String get proBuyWeb;

  /// No description provided for @supportTsudev.
  ///
  /// In vi, this message translates to:
  /// **'Ủng hộ TsuDEV'**
  String get supportTsudev;

  /// No description provided for @proPayNote.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán trên tsudev.com bằng VietQR. Mua xong, mở lại app hoặc bấm Kiểm tra lại.'**
  String get proPayNote;

  /// No description provided for @proCheckAgain.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra lại gói Pro'**
  String get proCheckAgain;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
