// Chuỗi giao diện tiếng Việt của sound.tsudev.com (PRODUCT_POLICY mục 1: không viết cứng trong mã).
// Bản gốc: mọi khoá phải có trong en.ts (kiểu `Dict` bắt buộc). Chuỗi có HTML chỉ là nội dung tĩnh của dự án,
// KHÔNG bao giờ chèn dữ liệu người dùng/máy chủ vào chúng.
import { REPO_URL } from '../lib/site';

export const vi = {
  meta: { ogLocale: 'vi_VN', ten: 'Tiếng Việt' },
  khung: {
    boQua: 'Bỏ qua tới nội dung',
    trangChu: 'Sound Db - Trang chủ',
    menuChinh: 'Chính',
    menu: { do: 'Đo trên web', huongDan: 'Hướng dẫn', baoMat: 'Bảo mật', taiKhoan: 'Tài khoản' },
    maNguon: 'Mã nguồn',
    taiVe: 'Tải về',
    gioiThieu: `Sound Db là máy đo âm thanh của hệ sinh thái TsuDEV, mã nguồn mở theo
      <a href="${REPO_URL}/blob/main/LICENSE" target="_blank" rel="noopener noreferrer">giấy phép Apache 2.0</a>.`,
    heSinhThai: 'Hệ sinh thái TsuDEV',
    dieuKhoan: 'Điều khoản sử dụng',
    riengTu: 'Chính sách riêng tư',
    sanPhamKhac: 'Sản phẩm khác',
    duAn: 'Dự án',
    baoMatRiengTu: 'Bảo mật và quyền riêng tư',
    baoLoi: 'Báo lỗi, góp ý',
    giaoDien: 'Giao diện',
    cheDo: { light: 'Sáng', dark: 'Tối', system: 'Hệ thống' },
    ngonNgu: 'Ngôn ngữ',
  },
  p404: {
    tieuDe: 'Không tìm thấy trang',
    moTa: 'Trang bạn tìm không tồn tại trên Sound Db. Quay về trang chủ hoặc mở máy đo âm thanh trên trình duyệt để bắt đầu đo ngay.',
    veTrangChu: 'Về trang chủ',
  },
  chu: {
    moTa: 'Sound Db: máy đo âm thanh chính xác cho Android, iOS, Windows, macOS, Linux và web. Đo dB, phổ tần số, octave, cao độ, liều tiếng ồn.',
    nhan: 'Một sản phẩm của TsuDEV',
    tieuDe: 'Đo âm thanh <span class="nhan-mau">chính xác</span>, trên mọi thiết bị',
    dan: `Sound Db đo mức âm, phổ tần số, dải octave và cao độ ngay trên thiết bị của bạn. Âm thanh không bao giờ rời
      máy; bản miễn phí giữ mọi dữ liệu trên máy, đồng bộ giữa các thiết bị là tính năng TsuDEV Pro.`,
    doNgay: 'Đo ngay trên trình duyệt',
    taiApp: 'Tải ứng dụng',
    tanSoTroi: 'Tần số trội',
    minhHoa: 'Minh hoạ mặt đồng hồ với số đo mẫu - bấm "Đo ngay trên trình duyệt" để đo thật bằng micro của bạn.',
    mau: { laf: 62.4, leq: 58.1, lmax: 71.3, lpeak: 84.0, tanSo: 1.0 },
    boCongCu: 'Bộ công cụ đo đầy đủ',
    boCongCuDan: `Một lõi xử lý tín hiệu viết bằng Rust, chạy giống hệt nhau trên web (WebAssembly) và được kiểm
        khớp từng con số với bản trong ứng dụng.`,
    tinhNang: [
      ['Máy đo mức âm', 'Trọng số A, C, Z và thời gian Nhanh/Chậm/Xung cùng lúc. Leq, Lmax, Lmin, Lpeak, LAF10/50/90, SEL.'],
      ['Phổ tần số FFT', 'FFT tới 32768 điểm trong ứng dụng (8192 trên web), 5 loại cửa sổ, giữ đỉnh, con trỏ đọc tần số. Tần số trội sai số dưới 1% bin.'],
      ['Phổ đồ', 'Thác nước theo thời gian trên trục tần số log, nhận ra tiếng vo ve, tiếng rít, tần số lạ.'],
      ['Dải octave 1/1 và 1/3', 'Dải cơ số 10 theo IEC 61260-1, tên dải danh định từ 16 Hz tới 20 kHz.'],
      ['Cao độ và nốt nhạc', 'Thuật toán McLeod: sai số dưới 1 cent, hiện nốt, lệch cent, chỉnh được A4.'],
      ['Liều tiếp xúc tiếng ồn', 'Tính theo NIOSH (85 dBA, 3 dB) và OSHA (90 dBA, 5 dB), kèm mức trung bình 8 giờ.'],
      ['Bộ phát tín hiệu', 'Sin, vuông, răng cưa, tam giác, ồn trắng, ồn hồng, quét tần số log 20 Hz - 20 kHz.'],
      ['Hiệu chuẩn', 'Theo máy hiệu chuẩn 94/114 dB, theo máy đo chuẩn, hoặc nhập offset; hồ sơ lưu trên thiết bị.'],
      ['Đồng bộ đa thiết bị', 'Có TsuDEV Pro: lịch sử đo trên điện thoại, máy tính và web cùng tài khoản. Không bắt buộc.'],
    ] as [string, string][],
    chinhXac: 'Độ chính xác có kiểm chứng',
    chinhXacDan: `Bộ lọc trọng số bám đường chuẩn IEC 61672-1 với sai lệch dưới 0,05 dB tới 12,5 kHz (dung sai
        cấp 1 của chuẩn là ±1 dB trở lên). Trọng số thời gian, phân vị và liều tiếp xúc có bộ test tự động riêng.
        Micro điện thoại không phải micro đo lường: hãy hiệu chuẩn để sai số tổng còn vài phần mười dB.`,
    diemManh: [
      ['Không xử lý ngầm', 'Tắt tự động tăng âm, khử vọng, khử ồn của hệ điều hành; Android dùng nguồn thu chưa xử lý.'],
      ['Mã nguồn mở', 'Ai cũng xem và chạy lại được bộ test độ chính xác. Giấy phép Apache 2.0.'],
      ['Bảo mật mặc định', 'Đăng nhập qua trình duyệt hệ thống với PKCE, token trong kho bí mật của hệ điều hành.'],
    ] as [string, string][],
  },
  do: {
    tieuDe: 'Đo trên trình duyệt',
    moTa: 'Máy đo âm thanh chạy ngay trong trình duyệt: mức dB trọng số A, C, Z, Leq, Lmax, phổ tần số và tần số trội. Âm thanh không rời máy.',
    h1: 'Máy đo âm thanh trên trình duyệt',
    canhBao: `Micro của máy tính và tai nghe khác nhau rất nhiều: kết quả chỉ chính xác sau khi
      <a href="/huong-dan/">hiệu chuẩn</a>. Âm thanh được xử lý ngay trên trình duyệt, không gửi đi đâu.`,
    batDau: 'Bắt đầu đo',
    dung: 'Dừng đo',
    datLai: 'Đặt lại phiên',
    trongSoTanSo: 'Trọng số tần số',
    trongSoThoiGian: 'Trọng số thời gian',
    thoiGian: ['Nhanh', 'Chậm', 'Xung'],
    tanSoTroi: 'Tần số trội',
    thoiLuong: 'Thời lượng',
    pho: 'Phổ tần số trên trục log từ 20 Hz',
    hieuChuan: 'Hiệu chuẩn cho trình duyệt này',
    offsetHien: 'Offset hiện tại: <strong id="offset-hien">-</strong> dB. Mức = 10·log10(trung bình bình phương) + offset.',
    offsetMoi: 'Offset mới (dB)',
    apDung: 'Áp dụng',
    loiQuyen: 'Trình duyệt chưa cho phép dùng micro. Hãy cấp quyền micro cho trang này rồi thử lại.',
    loiKhongMicro: 'Không tìm thấy micro nào.',
    loiKhoiDong: 'Không khởi động được máy đo trên trình duyệt này.',
    loiOffset: 'Offset phải là số trong khoảng 0-200 dB.',
    loiKhongHoTro: 'Trình duyệt này không hỗ trợ đo bằng micro (cần HTTPS và trình duyệt mới).',
  },
  huongDan: {
    tieuDe: 'Hướng dẫn đo',
    moTa: 'Hướng dẫn đo mức âm đúng cách với Sound Db: chọn trọng số A, C, Z, trọng số thời gian, hiệu chuẩn micro và đọc phổ tần số.',
    noiDung: `
    <h2>1. Chọn trọng số</h2>
    <ul>
      <li><strong>A</strong> (dBA): mô phỏng độ nhạy tai người, dùng cho tiếng ồn môi trường và nghề nghiệp.</li>
      <li><strong>C</strong> (dBC): giữ gần như nguyên tần số thấp, dùng cho âm nhạc, máy móc và đỉnh LCpeak.</li>
      <li><strong>Z</strong> (dBZ): không trọng số, để đo kỹ thuật và phân tích phổ.</li>
    </ul>
    <h2>2. Chọn trọng số thời gian</h2>
    <ul>
      <li><strong>Nhanh (F, 125 ms)</strong>: tiếng ồn thay đổi nhanh, mặc định cho phần lớn phép đo.</li>
      <li><strong>Chậm (S, 1 s)</strong>: tiếng ồn ổn định; liều tiếp xúc tính trên mức này.</li>
      <li><strong>Xung (I)</strong>: tiếng đập, tiếng nổ ngắn.</li>
    </ul>
    <h2>3. Hiệu chuẩn</h2>
    <p>Micro mỗi máy khác nhau tới 10 dB. Trước khi dùng số đo cho việc quan trọng:</p>
    <ol>
      <li>Có máy hiệu chuẩn âm (94 dB hoặc 114 dB tại 1 kHz): chọn cách tương ứng trong Cài đặt, đo 10 giây, áp dụng.</li>
      <li>Có máy đo âm chuẩn: đặt hai máy sát nhau trước một nguồn ồn ổn định, đo cùng lúc 10 giây, nhập LAeq của máy chuẩn.</li>
      <li>Biết sẵn offset của máy: nhập tay.</li>
    </ol>
    <p>Hồ sơ hiệu chuẩn lưu trên thiết bị (đồng bộ khi có TsuDEV Pro), nhưng chỉ đúng cho đúng thiết bị đó.</p>
    <h2>4. Đọc kết quả</h2>
    <ul>
      <li><strong>Leq</strong>: mức năng lượng trung bình của cả phiên, con số dùng để so với quy chuẩn.</li>
      <li><strong>LAF10 / LAF90</strong>: mức bị vượt 10% / 90% thời gian; LAF90 là ồn nền.</li>
      <li><strong>Liều</strong>: 100% là giới hạn tiếp xúc cho một ngày làm việc 8 giờ.</li>
    </ul>
    <h2>5. Giới hạn cần biết</h2>
    <p>Điện thoại không phải máy đo âm cấp 1/cấp 2 được kiểm định. Micro điện thoại thường bão hòa quanh 100-120 dB
      và kém nhạy dưới 50 Hz. Dùng Sound Db để khảo sát, theo dõi và so sánh; với phép đo có giá trị pháp lý, dùng
      thiết bị đã kiểm định.</p>`,
  },
  baoMat: {
    tieuDe: 'Bảo mật và quyền riêng tư',
    moTa: 'Cách Sound Db bảo vệ dữ liệu: âm thanh không rời thiết bị, đăng nhập TsuDEV bằng PKCE, token mã hóa, tự xóa dữ liệu và báo lỗ hổng.',
    noiDung: `
    <h2>Dữ liệu nào được thu</h2>
    <ul>
      <li><strong>Âm thanh: không.</strong> Âm thanh chỉ được xử lý trong bộ nhớ của thiết bị, không ghi, không gửi đi.</li>
      <li><strong>Khi chưa đăng nhập:</strong> ứng dụng không gửi bất kỳ yêu cầu mạng nào.</li>
      <li><strong>Đăng nhập ở bản miễn phí:</strong> chỉ để kiểm tra gói TsuDEV Pro và quản lý thiết bị; dữ liệu đo vẫn
        chỉ nằm trên thiết bị, không gửi lên internet.</li>
      <li><strong>Khi có TsuDEV Pro:</strong> chỉ đồng bộ các con số bạn chủ động lưu (tóm tắt phiên đo, chuỗi LAeq theo
        giây, phổ 1/3 octave, hồ sơ hiệu chuẩn), cùng tên thiết bị để bạn quản lý. Hết Pro: ngừng đồng bộ, bản sao trên
        đám mây còn tải về được 90 ngày rồi bị xoá; dữ liệu trên thiết bị giữ nguyên.</li>
      <li>Không theo dõi quảng cáo, không vị trí, không bán dữ liệu.</li>
    </ul>
    <h2>Đăng nhập</h2>
    <p>Sound Db không giữ mật khẩu. Đăng nhập qua tài khoản TsuDEV (Google, GitHub hoặc email) bằng OpenID Connect với
      PKCE trong trình duyệt hệ thống, không bao giờ qua khung nhúng. Token làm mới nằm trong kho bí mật của hệ điều
      hành, xoay vòng sau mỗi lần dùng; nếu một token đã dùng bị dùng lại, thiết bị đó bị đăng xuất ngay.</p>
    <h2>Quyền của bạn</h2>
    <ul>
      <li>Xem và thu hồi từng thiết bị, tải toàn bộ dữ liệu dạng JSON, xóa toàn bộ dữ liệu ở <a href="/bang-dieu-khien/">trang Tài khoản</a>.</li>
      <li>Bật <em>Chế độ ngoại tuyến hoàn toàn</em> trong ứng dụng để chặn mọi kết nối.</li>
      <li>Nút <em>Đăng xuất và xóa dữ liệu cục bộ</em> xóa sạch dữ liệu trên máy.</li>
    </ul>
    <h2>Báo lỗ hổng</h2>
    <p>Gửi báo cáo riêng tư qua <a href="${REPO_URL}/security/advisories/new" target="_blank" rel="noopener noreferrer">GitHub Security Advisories</a>.
      Xem thêm <a href="/.well-known/security.txt">security.txt</a>.</p>`,
  },
  dangNhap: {
    tieuDe: 'Đăng nhập',
    moTa: 'Đăng nhập Sound Db bằng tài khoản TsuDEV (Google, GitHub hoặc email) để xem lịch sử đo, quản lý thiết bị và dữ liệu đã đồng bộ.',
    loi: 'Đăng nhập không thành công hoặc đã bị hủy. Hãy thử lại.',
    dan: `Dùng tài khoản TsuDEV để xem lịch sử đo, quản lý thiết bị và dữ liệu đã đồng bộ. Trang đăng nhập của
      tsudev.com cho chọn <strong>Google</strong>, <strong>GitHub</strong> hoặc <strong>tài khoản TsuDEV</strong>.`,
    tiepTuc: 'Tiếp tục với tài khoản TsuDEV',
    chuaCo: 'Chưa có tài khoản? <a href="https://tsudev.com/register" target="_blank" rel="noopener noreferrer">Đăng ký tại tsudev.com</a>.',
  },
  taiVe: {
    tieuDe: 'Tải về',
    moTa: 'Tải Sound Db cho Android, iOS, Windows, macOS và Linux. Mỗi tệp cài đều công bố SHA-256 để bạn tự kiểm chứng trước khi cài đặt.',
    h1: 'Tải về Sound Db',
    banMoi: 'Bản mới nhất: <strong>{v}</strong>. Mọi bản được dựng tự động trên GitHub Actions từ mã nguồn công khai, kèm SHA-256 và chứng thực nguồn gốc. Không muốn cài đặt? <a href="/do/">Đo ngay trên trình duyệt</a>.',
    cot: ['Nền tảng', 'Yêu cầu', 'Kênh'],
    nenTang: [
      ['Windows', 'Windows 10/11 x64', 'Tệp .zip, giải nén rồi chạy sound_db.exe'],
      ['macOS', 'macOS 12 trở lên (Intel và Apple Silicon)', 'Tệp .zip chứa Sound Db.app (chưa ký Apple: chuột phải > Mở)'],
      ['Linux', 'x64 (Debian 12, Ubuntu 22.04, Fedora trở lên)', 'Gói APT/DNF (mục Cài bằng lệnh) hoặc tệp .tar.gz'],
      ['Android', 'Android 7.0 trở lên (arm64 và x86_64)', 'Tệp .apk ký số trên trang phát hành (cho phép cài từ nguồn ngoài)'],
      ['iOS và iPadOS', 'iOS 15 trở lên', 'App Store - đang chuẩn bị'],
    ] as [string, string, string][],
    moPhatHanh: 'Mở trang phát hành',
    caiBangLenh: 'Cài bằng lệnh',
    lenhCai: 'Lệnh cài',
    tuCapNhat: 'Gói tự cập nhật theo bản phát hành mới (mã băm SHA-256 lấy từ chính bản phát hành).',
    kiemChung: 'Kiểm chứng tệp tải về',
    kiemChungDan: 'Mỗi bản phát hành kèm tệp <code>SHA256SUMS</code>. So khớp trước khi cài:',
    lenhKiem: 'Lệnh kiểm chứng tệp tải về',
    powershell: 'Trên Windows PowerShell:',
    lenhKiemWin: 'Lệnh kiểm SHA-256 trên Windows',
  },
  bang: {
    tieuDe: 'Tài khoản',
    moTa: 'Bảng điều khiển Sound Db: xem lịch sử đo đã đồng bộ, quản lý và thu hồi thiết bị, tải về hoặc xóa toàn bộ dữ liệu của tài khoản TsuDEV.',
    h1: 'Tài khoản Sound Db',
    dangTai: 'Đang tải...',
    chuaDangNhap: 'Bạn chưa đăng nhập.',
    dangNhap: 'Đăng nhập',
    goi: 'Gói và đồng bộ đám mây',
    dangKiemPro: 'Đang kiểm tra gói TsuDEV Pro...',
    mienPhi: `Bản miễn phí dùng đủ mọi chức năng đo; dữ liệu chỉ lưu trên thiết bị, không gửi lên internet. Đồng bộ và
          sao lưu đám mây giữa các thiết bị là tính năng của TsuDEV Pro.`,
    // NGUYÊN VĂN PRODUCT_POLICY 7.5 (vi) - check-dist so với `.standards`.
    dieuKhoan: 'TsuDEV Pro 490.000 ₫ cho 1 năm, KHÔNG tự gia hạn. Gia hạn sớm được cộng thêm 1 năm vào thời hạn còn lại. Hết hạn mà chưa gia hạn, ứng dụng trở về bản miễn phí và ngừng đồng bộ lên đám mây; dữ liệu trên thiết bị vẫn giữ nguyên, bản sao trên đám mây còn tải về được 90 ngày rồi bị xoá.',
    xemPro: 'Xem gói Pro',
    ungHo: 'Ủng hộ TsuDEV',
    taiJson: 'Tải toàn bộ dữ liệu (JSON)',
    dangXuat: 'Đăng xuất',
    phienDo: 'Phiên đo',
    timTheoTen: 'Tìm theo nhãn, ghi chú, thiết bị',
    khoangThoiGian: 'Khoảng thời gian',
    khoang: ['Mọi lúc', '7 ngày qua', '1 tháng qua', '1 năm qua', 'Tuỳ chọn'],
    tuNgay: 'Từ ngày',
    denNgay: 'Đến ngày',
    bangPhien: 'Bảng phiên đo',
    cotPhien: ['Tên', 'Bắt đầu', 'Thời lượng'],
    thaoTac: 'Thao tác',
    soDong: 'Số bản ghi mỗi trang',
    moiTrang: '/ trang',
    truoc: 'Trang trước',
    sau: 'Trang sau',
    thietBi: 'Thiết bị đã đăng nhập',
    bangThietBi: 'Bảng thiết bị',
    cotThietBi: ['Thiết bị', 'Nền tảng', 'Lần cuối'],
    hoatDong: 'Hoạt động bảo mật gần đây',
    bangHoatDong: 'Bảng hoạt động bảo mật',
    cotHoatDong: ['Sự kiện', 'Lúc'],
    xoaDuLieu: 'Xóa dữ liệu',
    xoaDan: 'Xóa vĩnh viễn mọi phiên đo, hồ sơ hiệu chuẩn và thiết bị của bạn trên máy chủ Sound Db. Tài khoản TsuDEV không bị ảnh hưởng.',
    nutXoa: 'Xóa toàn bộ dữ liệu Sound Db',
  },
  // Chuỗi dùng trong script phía trình duyệt (src/scripts/*). {x} = chỗ điền.
  js: {
    loiHttp: 'Lỗi HTTP {x}',
    loi: 'Lỗi',
    thatBai: 'Thao tác thất bại. Hãy thử lại.',
    phienDo: 'Phiên đo',
    xoa: 'Xóa',
    xacNhanXoaPhien: 'Xóa phiên "{x}" trên mọi thiết bị?',
    khongKhop: 'Không có phiên đo nào trong khoảng thời gian này. Thử nới khoảng thời gian.',
    khongKhopTu: 'Không tìm thấy phiên đo phù hợp với "{x}". Thử kiểm tra chính tả, từ khoá khác hoặc nới khoảng thời gian.',
    chuaCoPhien: 'Chưa có phiên đo nào được đồng bộ.',
    dangXuatThietBi: 'Đăng xuất thiết bị',
    xacNhanDangXuat: 'Đăng xuất "{x}" khỏi tài khoản?',
    suKien: {
      login: 'Đăng nhập',
      device_added: 'Thêm thiết bị',
      device_revoked: 'Thu hồi thiết bị',
      logout: 'Đăng xuất thiết bị',
      refresh_reuse_revoked: 'Phát hiện token bị dùng lại - đã thu hồi thiết bị',
    } as Record<string, string>,
    proLoi: 'Chưa kiểm tra được gói TsuDEV Pro lúc này. Dữ liệu trên thiết bị không bị ảnh hưởng.',
    proToi: 'TsuDEV Pro tới {x}: đồng bộ và sao lưu đám mây đang bật.',
    giaHan: 'Gia hạn',
    proMienPhi: 'Bản miễn phí: đồng bộ lên đám mây đang tắt. Bạn vẫn xem, tải về và xoá được dữ liệu đã có trên đám mây.',
    hanXoa: 'Bản sao trên đám mây còn tải về được tới ngày {x}.',
    thongKe: '{a} phiên đo · {b} hồ sơ hiệu chuẩn · {c} đã đo',
    khongTai: 'Không tải được dữ liệu: {x}',
    nhapXacNhan: 'Gõ "xoa-vinh-vien" để xác nhận xóa toàn bộ dữ liệu Sound Db:',
    sai: 'Chuỗi xác nhận không đúng - dữ liệu chưa bị xóa.',
  },
};

export type Dict = typeof vi;
