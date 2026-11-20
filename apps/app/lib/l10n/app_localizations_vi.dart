// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get navMeter => 'Đo mức';

  @override
  String get navAnalysis => 'Phân tích';

  @override
  String get navTools => 'Công cụ';

  @override
  String get navHistory => 'Lịch sử';

  @override
  String get navSettings => 'Cài đặt';

  @override
  String get meterTitle => 'Đo mức âm';

  @override
  String get meterReferenceTooltip => 'Mức tham chiếu thường gặp';

  @override
  String get meterNotCalibrated =>
      'Chưa hiệu chuẩn: số đo là ước lượng theo micro điển hình (sai số có thể vài dB). Vào Cài đặt > Hiệu chuẩn để đo chính xác.';

  @override
  String meterLevelSemantics(String name, String value) {
    return 'Mức âm $name $value đề-xi-ben';
  }

  @override
  String get timeFast => 'Nhanh';

  @override
  String get timeSlow => 'Chậm';

  @override
  String get timeImpulse => 'Xung';

  @override
  String get meterLast2Min => '2 phút gần nhất';

  @override
  String get meterLeqHint => 'Mức tương đương liên tục của cả phiên';

  @override
  String get meterPeakHint => 'Đỉnh tức thời';

  @override
  String get meterL10Hint => 'Mức bị vượt 10% thời gian';

  @override
  String get meterL90Hint => 'Ồn nền';

  @override
  String get duration => 'Thời lượng';

  @override
  String get resetSession => 'Đặt lại phiên';

  @override
  String get saveSession => 'Lưu phiên đo';

  @override
  String get doseTitle => 'Liều tiếp xúc tiếng ồn';

  @override
  String get doseNioshRule => '85 dBA / 8 giờ, hệ số trao đổi 3 dB';

  @override
  String get doseOshaRule => '90 dBA / 8 giờ, hệ số trao đổi 5 dB';

  @override
  String get doseNote =>
      'Tính trên LAS từ khi bắt đầu phiên. 100% là giới hạn tiếp xúc cho một ngày làm việc.';

  @override
  String get refTitle => 'Mức âm tham chiếu (dBA)';

  @override
  String get ref0 => 'Ngưỡng nghe';

  @override
  String get ref20 => 'Thì thầm, phòng ngủ yên tĩnh';

  @override
  String get ref40 => 'Thư viện, văn phòng yên tĩnh';

  @override
  String get ref60 => 'Trò chuyện bình thường';

  @override
  String get ref70 => 'Máy hút bụi, đường phố đông';

  @override
  String get ref85 => 'Giao thông dày đặc - ngưỡng tiếp xúc 8 giờ (NIOSH)';

  @override
  String get ref95 => 'Xe máy tăng ga, máy khoan';

  @override
  String get ref110 => 'Hòa nhạc, vũ trường';

  @override
  String get ref120 => 'Còi xe cứu thương sát tai - ngưỡng đau';

  @override
  String defaultSessionLabel(String time) {
    return 'Phiên đo $time';
  }

  @override
  String get sessionFallback => 'Phiên đo';

  @override
  String get sessionName => 'Tên phiên';

  @override
  String get cancel => 'Hủy';

  @override
  String get save => 'Lưu';

  @override
  String get sessionTooShort => 'Phiên quá ngắn để lưu (cần ít nhất 1 giây).';

  @override
  String savedLabel(String label) {
    return 'Đã lưu \"$label\".';
  }

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get sectionAccount => 'Tài khoản và đồng bộ';

  @override
  String get sectionCalibration => 'Hiệu chuẩn';

  @override
  String get micCalibration => 'Hiệu chuẩn micro';

  @override
  String calibratedOffset(String offset) {
    return 'Đã hiệu chuẩn · offset $offset';
  }

  @override
  String notCalibratedOffset(String offset) {
    return 'Chưa hiệu chuẩn · dùng offset ước lượng $offset';
  }

  @override
  String get sectionTheme => 'Giao diện';

  @override
  String get themeLight => 'Sáng';

  @override
  String get themeDark => 'Tối';

  @override
  String get themeSystem => 'Hệ thống';

  @override
  String get sectionLanguage => 'Ngôn ngữ';

  @override
  String get languageSystem => 'Theo hệ thống';

  @override
  String get sectionMeasurement => 'Đo lường';

  @override
  String get keepScreenOn => 'Giữ màn hình sáng khi đang đo';

  @override
  String get a4Reference => 'Tần số chuẩn A4';

  @override
  String get sectionPrivacy => 'Quyền riêng tư';

  @override
  String get offlineMode => 'Chế độ ngoại tuyến hoàn toàn';

  @override
  String get offlineModeHint =>
      'Chặn mọi kết nối ra ngoài, kể cả đăng nhập và đồng bộ. Đo lường vẫn chạy đủ.';

  @override
  String get audioNeverLeaves => 'Âm thanh không bao giờ rời thiết bị';

  @override
  String get audioNeverLeavesHint =>
      'Sound Db chỉ xử lý âm thanh trong bộ nhớ, không ghi âm. Bản miễn phí không gửi dữ liệu đo lên internet; khi đồng bộ (TsuDEV Pro), chỉ các con số đo được gửi đi.';

  @override
  String get sectionAbout => 'Giới thiệu';

  @override
  String get logoSemantics => 'Logo Sound Db';

  @override
  String versionLine(String version) {
    return 'Phiên bản $version · Một sản phẩm của TsuDEV';
  }

  @override
  String proUntil(String date) {
    return 'TsuDEV Pro tới $date';
  }

  @override
  String get freePlan => 'Bản miễn phí';

  @override
  String get proTileOn => 'Đồng bộ và sao lưu đám mây đang bật.';

  @override
  String get proTileOff =>
      'Dữ liệu chỉ lưu trên thiết bị. Xem gói TsuDEV Pro để đồng bộ giữa các thiết bị, hoặc ủng hộ TsuDEV.';

  @override
  String get guestMode =>
      'Bạn đang dùng ở chế độ khách - mọi chức năng đo đều mở.';

  @override
  String signInFailed(String error) {
    return 'Đăng nhập thất bại: $error';
  }

  @override
  String get signInButton => 'Đăng nhập tài khoản TsuDEV';

  @override
  String get signInHint =>
      'Mở trình duyệt hệ thống tới tsudev.com (Google, GitHub hoặc tài khoản TsuDEV). Đăng nhập để dùng gói TsuDEV Pro (đồng bộ và sao lưu đám mây) và huy hiệu; bản miễn phí không cần đăng nhập.';

  @override
  String get syncNow => 'Đồng bộ ngay';

  @override
  String get autoSync => 'Tự đồng bộ khi mở app và sau khi lưu';

  @override
  String get manageOnWeb => 'Quản lý thiết bị và dữ liệu trên web';

  @override
  String get signOut => 'Đăng xuất';

  @override
  String get signOutWipe => 'Đăng xuất và xóa dữ liệu cục bộ';

  @override
  String get signOutWipeHint =>
      'Xóa lịch sử, hiệu chuẩn và cài đặt trên máy này. Bản sao đã đồng bộ (nếu có) vẫn còn trên tài khoản.';

  @override
  String get wipeConfirmTitle => 'Xóa dữ liệu trên máy này?';

  @override
  String get wipeConfirmBody => 'Bản ghi chưa đồng bộ sẽ mất vĩnh viễn.';

  @override
  String get delete => 'Xóa';

  @override
  String get calMethod94 => 'Máy hiệu chuẩn 94 dB @ 1 kHz';

  @override
  String get calMethod114 => 'Máy hiệu chuẩn 114 dB @ 1 kHz';

  @override
  String get calMethodReference => 'So với máy đo chuẩn (nhập số đọc)';

  @override
  String get micOpenFailed => 'Không mở được micro.';

  @override
  String offsetApplied(String offset) {
    return 'Đã áp dụng offset $offset.';
  }

  @override
  String currentOffset(String offset) {
    return 'Offset hiện tại: $offset';
  }

  @override
  String currentOffsetDefault(String offset) {
    return 'Offset hiện tại: $offset (mặc định, chưa hiệu chuẩn)';
  }

  @override
  String get calReferenceHowTo =>
      'Đặt điện thoại sát máy đo chuẩn, cùng hướng về nguồn ồn ổn định (quạt, ồn hồng). Đo 10 giây rồi nhập LAeq mà máy chuẩn hiển thị trong cùng khoảng thời gian.';

  @override
  String get calCalibratorHowTo =>
      'Lắp đầu micro vào khớp nối của máy hiệu chuẩn (hoặc áp sát nếu không vừa), bật máy hiệu chuẩn, giữ yên rồi bấm Đo. Kết quả dùng LZeq 10 giây.';

  @override
  String get referenceLaeq => 'LAeq của máy đo chuẩn (dB)';

  @override
  String measuringRemaining(String seconds) {
    return 'Đang đo... còn $seconds giây';
  }

  @override
  String measureSeconds(String seconds) {
    return 'Đo $seconds giây';
  }

  @override
  String measuredWithOld(String level) {
    return 'Đo được: $level (với offset cũ)';
  }

  @override
  String newOffset(String offset) {
    return 'Offset mới: $offset';
  }

  @override
  String get apply => 'Áp dụng';

  @override
  String get manualOffset => 'Nhập offset thủ công';

  @override
  String get offsetRange => 'Offset phải là số trong 0-200 dB.';

  @override
  String get restoreDefault => 'Khôi phục mặc định (bỏ hiệu chuẩn)';

  @override
  String get analysisTitle => 'Phân tích tần số';

  @override
  String get spectrumSettings => 'Thiết lập phổ';

  @override
  String get tabFft => 'Phổ FFT';

  @override
  String get tabSpectrogram => 'Phổ đồ';

  @override
  String get tabOctave => 'Dải octave';

  @override
  String get dominantFrequency => 'Tần số trội';

  @override
  String get peakLevel => 'Mức đỉnh';

  @override
  String get cursor => 'Con trỏ';

  @override
  String get tapChart => 'Chạm biểu đồ';

  @override
  String get peakHold => 'Giữ đỉnh';

  @override
  String get clearPeak => 'Xóa đỉnh';

  @override
  String fftInfo(String size, String window, String binHz, String weighting) {
    return 'FFT $size · $window · $binHz Hz/bin · trọng số $weighting';
  }

  @override
  String spectrogramNote(String nyquist) {
    return 'Mỗi hàng là một khung phổ (mới nhất ở trên), trục ngang là tần số log 20 Hz - $nyquist.';
  }

  @override
  String lowBandWarning(String bins) {
    return 'Dải thấp nhất chỉ phủ $bins bin FFT - tăng kích thước FFT (Thiết lập phổ) để dải tần thấp chính xác hơn.';
  }

  @override
  String bandNote(String weighting) {
    return 'Mức dải (IEC 61260-1, hệ cơ số 10) trọng số $weighting, từ phổ trung bình.';
  }

  @override
  String get fftSize => 'Kích thước FFT';

  @override
  String fftSamples(String n) {
    return '$n mẫu';
  }

  @override
  String get window => 'Cửa sổ';

  @override
  String get windowRectangular => 'Chữ nhật';

  @override
  String displayRange(String min, String max) {
    return 'Thang hiển thị: $min - $max dB';
  }

  @override
  String savedFile(String name) {
    return 'Đã lưu $name';
  }

  @override
  String get deleteSessionTitle => 'Xóa phiên đo?';

  @override
  String get deleteSessionBody =>
      'Phiên sẽ bị xóa trên máy này và trên mọi thiết bị đã đồng bộ.';

  @override
  String get actions => 'Thao tác';

  @override
  String get exportCsv => 'Xuất CSV';

  @override
  String get exportJson => 'Xuất JSON';

  @override
  String get deleteSession => 'Xóa phiên';

  @override
  String get doseNiosh => 'Liều NIOSH';

  @override
  String get doseOsha => 'Liều OSHA';

  @override
  String get laeqOverTime => 'LAeq theo thời gian';

  @override
  String get thirdOctaveAvg => 'Phổ 1/3 octave trung bình (LZeq)';

  @override
  String calOffsetAtMeasure(String offset) {
    return 'Offset hiệu chuẩn khi đo: $offset';
  }

  @override
  String get historyTitle => 'Lịch sử đo';

  @override
  String get reload => 'Tải lại';

  @override
  String get historyEmpty =>
      'Chưa có phiên đo nào. Bấm \"Lưu phiên đo\" ở màn hình Đo mức để lưu lại kết quả.';

  @override
  String get notSynced => ' · chưa đồng bộ';

  @override
  String get toolsTitle => 'Công cụ';

  @override
  String get tabPitch => 'Tần số & cao độ';

  @override
  String get tabGenerator => 'Phát tín hiệu';

  @override
  String get pitchNotDetected => 'Chưa nhận ra cao độ';

  @override
  String noteSemantics(String note, String cents) {
    return 'Nốt $note, lệch $cents cent';
  }

  @override
  String get noPitchedSound => 'Chưa nhận ra âm có cao độ';

  @override
  String get deviation => 'Lệch';

  @override
  String get clarity => 'Độ rõ';

  @override
  String get dominantFft => 'Tần số trội (FFT)';

  @override
  String get dominantLevel => 'Mức trội';

  @override
  String get a4Standard => 'A4 chuẩn';

  @override
  String get pitchNote =>
      'Cao độ dùng thuật toán McLeod (NSDF) trên khung 4096 mẫu, sai số < 1 cent với âm có họa âm. Tần số trội lấy trọng tâm công suất quanh đỉnh FFT - đúng cho cả tông thuần không có họa âm.';

  @override
  String playFailed(String error) {
    return 'Không phát được âm thanh: $error';
  }

  @override
  String get generatorWarning =>
      'Bắt đầu ở âm lượng nhỏ. Tần số rất cao hoặc âm lượng lớn qua tai nghe có thể gây hại cho thính giác và loa.';

  @override
  String frequencyValue(String hz) {
    return 'Tần số: $hz';
  }

  @override
  String sweepNote(String seconds) {
    return 'Quét log 20 Hz - 20 kHz trong $seconds giây, lặp lại.';
  }

  @override
  String signalVolume(String db) {
    return 'Âm lượng tín hiệu: $db dBFS';
  }

  @override
  String get stopPlaying => 'Dừng phát';

  @override
  String get play => 'Phát';

  @override
  String get waveSine => 'Sin';

  @override
  String get waveSquare => 'Vuông';

  @override
  String get waveSawtooth => 'Răng cưa';

  @override
  String get waveTriangle => 'Tam giác';

  @override
  String get waveWhite => 'Ồn trắng';

  @override
  String get wavePink => 'Ồn hồng';

  @override
  String get waveSweep => 'Quét tần số';

  @override
  String get pause => 'Tạm dừng';

  @override
  String get resume => 'Tiếp tục';

  @override
  String get startMeasuring => 'Bắt đầu đo';

  @override
  String get error => 'Lỗi';

  @override
  String get notice => 'Lưu ý';

  @override
  String get perPage => '/ trang';

  @override
  String get previousPage => 'Trang trước';

  @override
  String get nextPage => 'Trang sau';

  @override
  String get errOfflineMode =>
      'Đang bật Chế độ ngoại tuyến hoàn toàn - tắt nó trong Cài đặt để đăng nhập.';

  @override
  String get errBrowser => 'Không mở được trình duyệt hệ thống.';

  @override
  String get errLoginCancelled => 'Đăng nhập bị hủy hoặc bị từ chối.';

  @override
  String get errStateMismatch =>
      'Phản hồi đăng nhập không khớp phiên - đã chặn để an toàn.';

  @override
  String get errNoCode => 'Máy chủ không trả mã đăng nhập.';

  @override
  String get errLoginTimeout => 'Hết 5 phút chờ đăng nhập - hãy thử lại.';

  @override
  String get loopbackDone =>
      'Đã nhận phản hồi đăng nhập. Bạn có thể đóng thẻ này và quay lại Sound Db.';

  @override
  String get errLoginFailed => 'Đăng nhập thất bại.';

  @override
  String errBadResponse(String status) {
    return 'Máy chủ trả dữ liệu không hợp lệ (HTTP $status).';
  }

  @override
  String get errSignedOut => 'Chưa đăng nhập.';

  @override
  String get syncRunning => 'Đang đồng bộ...';

  @override
  String get syncFreePlan =>
      'Bản miễn phí: dữ liệu chỉ lưu trên thiết bị này. Đồng bộ lên đám mây cần TsuDEV Pro.';

  @override
  String syncError(String error) {
    return 'Lỗi đồng bộ: $error';
  }

  @override
  String get syncNever => 'Chưa đồng bộ lần nào';

  @override
  String syncLast(String time) {
    return 'Đồng bộ lúc $time';
  }

  @override
  String syncRejected(String count) {
    return 'máy chủ từ chối $count bản ghi';
  }

  @override
  String get errMicPermission =>
      'Sound Db cần quyền dùng micro để đo. Hãy cấp quyền trong cài đặt hệ thống.';

  @override
  String get errPcm16 => 'Thiết bị không hỗ trợ thu PCM 16-bit.';

  @override
  String errMicOpen(String error) {
    return 'Không mở được micro: $error';
  }

  @override
  String get windowFlatTop => 'Đỉnh phẳng';

  @override
  String get proStatus => 'Trạng thái';

  @override
  String proActiveLine(String date) {
    return 'TsuDEV Pro tới $date: đồng bộ và sao lưu đám mây đang bật.';
  }

  @override
  String proExpiredLine(String date, String deleteDate) {
    return 'TsuDEV Pro đã hết hạn ngày $date. Bản sao trên đám mây còn tải về được tới ngày $deleteDate.';
  }

  @override
  String get proFreeLine =>
      'Bản miễn phí: mọi chức năng đo đều mở; dữ liệu chỉ lưu trên thiết bị này, không gửi lên internet.';

  @override
  String get proFeaturesTitle => 'Pro có gì';

  @override
  String get proFeatures =>
      '• Đồng bộ lịch sử đo và hồ sơ hiệu chuẩn giữa các thiết bị cùng tài khoản.\n• Sao lưu lên đám mây, xem và tải về trên web (sounddb.tsudev.com).\n• Huy hiệu Pro cạnh tên tài khoản. Một gói dùng chung cho mọi sản phẩm TsuDEV.';

  @override
  String get proPlaySoon =>
      'Mua TsuDEV Pro trong Google Play sẽ có ở bản cập nhật tới.';

  @override
  String get proRenewWeb => 'Gia hạn trên tsudev.com';

  @override
  String get proBuyWeb => 'Mua TsuDEV Pro trên tsudev.com';

  @override
  String get supportTsudev => 'Ủng hộ TsuDEV';

  @override
  String get proPayNote =>
      'Thanh toán trên tsudev.com bằng VietQR. Mua xong, mở lại app hoặc bấm Kiểm tra lại.';

  @override
  String get proCheckAgain => 'Kiểm tra lại gói Pro';
}
