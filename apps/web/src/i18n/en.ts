// English UI strings of sound.tsudev.com. Same keys as vi.ts (enforced by the `Dict` type).
import { REPO_URL } from '../lib/site';
import type { Dict } from './vi';

export const en: Dict = {
  meta: { ogLocale: 'en_US', ten: 'English' },
  khung: {
    boQua: 'Skip to content',
    trangChu: 'Sound Db - Home',
    menuChinh: 'Main',
    menu: { do: 'Measure on the web', huongDan: 'Guide', baoMat: 'Security', taiKhoan: 'Account' },
    maNguon: 'Source code',
    taiVe: 'Download',
    gioiThieu: `Sound Db is the sound meter of the TsuDEV ecosystem, open source under the
      <a href="${REPO_URL}/blob/main/LICENSE" target="_blank" rel="noopener noreferrer">Apache 2.0 license</a>.`,
    heSinhThai: 'TsuDEV ecosystem',
    dieuKhoan: 'Terms of use',
    riengTu: 'Privacy policy',
    sanPhamKhac: 'Other products',
    duAn: 'Project',
    baoMatRiengTu: 'Security and privacy',
    baoLoi: 'Report a bug, give feedback',
    giaoDien: 'Theme',
    cheDo: { light: 'Light', dark: 'Dark', system: 'System' },
    ngonNgu: 'Language',
  },
  p404: {
    tieuDe: 'Page not found',
    moTa: 'The page you are looking for does not exist on Sound Db. Go back to the home page or open the browser sound meter to start measuring now.',
    veTrangChu: 'Back to home',
  },
  chu: {
    moTa: 'Sound Db: an accurate sound meter for Android, iOS, Windows, macOS, Linux and the web. Measure dB, frequency spectrum, octaves, pitch, noise dose.',
    nhan: 'A TsuDEV product',
    tieuDe: 'Measure sound <span class="nhan-mau">accurately</span>, on every device',
    dan: `Sound Db measures sound level, frequency spectrum, octave bands and pitch right on your device. Audio never
      leaves the device; the free version keeps all data on the device, syncing between devices is a TsuDEV Pro feature.`,
    doNgay: 'Measure in your browser',
    taiApp: 'Get the app',
    boCongCu: 'A complete measuring toolkit',
    boCongCuDan: `One signal processing core written in Rust runs identically on the web (WebAssembly) and is checked
        number by number against the version inside the app.`,
    tinhNang: [
      ['Sound level meter', 'A, C, Z frequency weighting and Fast/Slow/Impulse time weighting at once. Leq, Lmax, Lmin, Lpeak, LAF10/50/90, SEL.'],
      ['FFT spectrum', 'FFT up to 32768 points in the app (8192 on the web), 5 window types, peak hold, frequency cursor. Dominant frequency within 1% of a bin.'],
      ['Spectrogram', 'A waterfall over time on a log frequency axis to spot hum, whine and unusual tones.'],
      ['1/1 and 1/3 octave bands', 'Base-10 bands per IEC 61260-1, nominal band names from 16 Hz to 20 kHz.'],
      ['Pitch and musical notes', 'McLeod algorithm: error below 1 cent, shows the note and cent offset, adjustable A4.'],
      ['Noise exposure dose', 'Computed per NIOSH (85 dBA, 3 dB) and OSHA (90 dBA, 5 dB), with the 8-hour average level.'],
      ['Signal generator', 'Sine, square, sawtooth, triangle, white noise, pink noise, log sweep 20 Hz - 20 kHz.'],
      ['Calibration', 'With a 94/114 dB calibrator, against a reference meter, or by entering an offset; profiles stay on the device.'],
      ['Multi-device sync', 'With TsuDEV Pro: your measurement history on phone, computer and web under one account. Optional.'],
    ],
    chinhXac: 'Verified accuracy',
    chinhXacDan: `The weighting filters follow the IEC 61672-1 curves within 0.05 dB up to 12.5 kHz (the class 1
        tolerance of the standard is ±1 dB or more). Time weighting, percentiles and exposure dose have their own automated
        tests. A phone microphone is not a measurement microphone: calibrate it to bring the total error down to a few tenths of a dB.`,
    diemManh: [
      ['No hidden processing', 'Automatic gain, echo cancellation and noise suppression of the OS are turned off; Android uses the unprocessed source.'],
      ['Open source', 'Anyone can read and rerun the accuracy test suite. Apache 2.0 license.'],
      ['Secure by default', 'Sign-in through the system browser with PKCE, tokens in the OS secret store.'],
    ],
  },
  do: {
    tieuDe: 'Measure in the browser',
    moTa: 'A sound meter that runs right in your browser: A, C, Z weighted dB levels, Leq, Lmax, frequency spectrum and dominant frequency. Audio stays local.',
    h1: 'Browser sound meter',
    canhBao: `Computer and headset microphones vary a lot: results are only accurate after
      <a href="/en/huong-dan/">calibration</a>. Audio is processed in the browser and never sent anywhere.`,
    batDau: 'Start measuring',
    dung: 'Stop',
    datLai: 'Reset session',
    trongSoTanSo: 'Frequency weighting',
    trongSoThoiGian: 'Time weighting',
    thoiGian: ['Fast', 'Slow', 'Impulse'],
    tanSoTroi: 'Dominant frequency',
    thoiLuong: 'Duration',
    pho: 'Frequency spectrum on a log axis from 20 Hz',
    hieuChuan: 'Calibration for this browser',
    offsetHien: 'Current offset: <strong id="offset-hien">-</strong> dB. Level = 10·log10(mean square) + offset.',
    offsetMoi: 'New offset (dB)',
    apDung: 'Apply',
    loiQuyen: 'The browser has not allowed microphone access. Grant microphone permission to this page and try again.',
    loiKhongMicro: 'No microphone found.',
    loiKhoiDong: 'Could not start the meter in this browser.',
    loiOffset: 'The offset must be a number between 0 and 200 dB.',
    loiKhongHoTro: 'This browser does not support measuring with a microphone (HTTPS and a recent browser are required).',
  },
  huongDan: {
    tieuDe: 'Measuring guide',
    moTa: 'How to measure sound levels correctly with Sound Db: choosing A, C, Z weighting and time weighting, calibrating the microphone and reading the spectrum.',
    noiDung: `
    <h2>1. Choose the frequency weighting</h2>
    <ul>
      <li><strong>A</strong> (dBA): models the sensitivity of human hearing, used for environmental and occupational noise.</li>
      <li><strong>C</strong> (dBC): keeps low frequencies almost unchanged, used for music, machinery and LCpeak.</li>
      <li><strong>Z</strong> (dBZ): no weighting, for technical measurements and spectrum analysis.</li>
    </ul>
    <h2>2. Choose the time weighting</h2>
    <ul>
      <li><strong>Fast (F, 125 ms)</strong>: rapidly changing noise, the default for most measurements.</li>
      <li><strong>Slow (S, 1 s)</strong>: steady noise; the exposure dose is computed on this level.</li>
      <li><strong>Impulse (I)</strong>: hammering, short bangs.</li>
    </ul>
    <h2>3. Calibration</h2>
    <p>Microphones differ by up to 10 dB between devices. Before relying on a reading for anything important:</p>
    <ol>
      <li>With an acoustic calibrator (94 dB or 114 dB at 1 kHz): pick the matching method in Settings, measure for 10 seconds, apply.</li>
      <li>With a reference sound level meter: place both side by side in front of a steady noise source, measure for 10 seconds at the same time, enter the reference LAeq.</li>
      <li>If you already know the device offset: enter it manually.</li>
    </ol>
    <p>Calibration profiles are stored on the device (synced with TsuDEV Pro), but they are only valid for that exact device.</p>
    <h2>4. Reading the results</h2>
    <ul>
      <li><strong>Leq</strong>: the average energy level of the whole session, the number to compare against regulations.</li>
      <li><strong>LAF10 / LAF90</strong>: the level exceeded 10% / 90% of the time; LAF90 is the background noise.</li>
      <li><strong>Dose</strong>: 100% is the exposure limit for an 8-hour working day.</li>
    </ul>
    <h2>5. Limits to keep in mind</h2>
    <p>A phone is not a certified class 1/class 2 sound level meter. Phone microphones usually saturate around 100-120 dB
      and lose sensitivity below 50 Hz. Use Sound Db to survey, monitor and compare; for legally binding measurements, use
      certified equipment.</p>`,
  },
  baoMat: {
    tieuDe: 'Security and privacy',
    moTa: 'How Sound Db protects your data: audio never leaves the device, TsuDEV sign-in with PKCE, encrypted tokens, automatic data deletion and vulnerability reports.',
    noiDung: `
    <h2>What data is collected</h2>
    <ul>
      <li><strong>Audio: none.</strong> Audio is only processed in the device memory, never recorded, never sent.</li>
      <li><strong>When signed out:</strong> the app makes no network requests at all.</li>
      <li><strong>Signed in on the free version:</strong> only to check your TsuDEV Pro plan and manage devices; measurement
        data stays on the device and is not sent to the internet.</li>
      <li><strong>With TsuDEV Pro:</strong> only the numbers you choose to save are synced (session summaries, per-second LAeq
        series, 1/3 octave spectra, calibration profiles), plus device names so you can manage them. When Pro ends: syncing stops,
        your cloud copy can be downloaded for 90 days before it is deleted; data on your device stays intact.</li>
      <li>No ad tracking, no location, no selling of data.</li>
    </ul>
    <h2>Sign-in</h2>
    <p>Sound Db stores no passwords. You sign in with a TsuDEV account (Google, GitHub or email) through OpenID Connect with
      PKCE in the system browser, never in an embedded frame. Refresh tokens live in the OS secret store and rotate after every
      use; if a used token is replayed, that device is signed out immediately.</p>
    <h2>Your rights</h2>
    <ul>
      <li>See and revoke each device, download all your data as JSON, and delete all your data on the <a href="/en/bang-dieu-khien/">Account page</a>.</li>
      <li>Turn on <em>Fully offline mode</em> in the app to block every connection.</li>
      <li>The <em>Sign out and delete local data</em> button wipes all data on the device.</li>
    </ul>
    <h2>Reporting vulnerabilities</h2>
    <p>Send a private report through <a href="${REPO_URL}/security/advisories/new" target="_blank" rel="noopener noreferrer">GitHub Security Advisories</a>.
      See also <a href="/.well-known/security.txt">security.txt</a>.</p>`,
  },
  dangNhap: {
    tieuDe: 'Sign in',
    moTa: 'Sign in to Sound Db with your TsuDEV account (Google, GitHub or email) to view your measurement history, manage devices and synced data.',
    loi: 'Sign-in failed or was cancelled. Please try again.',
    dan: `Use your TsuDEV account to view your measurement history, manage devices and synced data. The tsudev.com sign-in
      page lets you choose <strong>Google</strong>, <strong>GitHub</strong> or a <strong>TsuDEV account</strong>.`,
    tiepTuc: 'Continue with TsuDEV account',
    chuaCo: 'No account yet? <a href="https://tsudev.com/register" target="_blank" rel="noopener noreferrer">Register at tsudev.com</a>.',
  },
  taiVe: {
    tieuDe: 'Download',
    moTa: 'Download Sound Db for Android, iOS, Windows, macOS and Linux. Every installer comes with a published SHA-256 so you can verify it before installing.',
    h1: 'Download Sound Db',
    banMoi: 'Latest version: <strong>{v}</strong>. Every build is produced automatically on GitHub Actions from the public source code, with SHA-256 and provenance attestation. Prefer not to install? <a href="/en/do/">Measure in your browser</a>.',
    cot: ['Platform', 'Requirements', 'Channel'],
    nenTang: [
      ['Windows', 'Windows 10/11 x64', '.zip file, extract and run sound_db.exe'],
      ['macOS', 'macOS 12 or later (Intel and Apple Silicon)', '.zip with Sound Db.app (not Apple-signed yet: right-click > Open)'],
      ['Linux', 'x64 (Debian 12, Ubuntu 22.04, Fedora or later)', 'APT/DNF package (see Install from the command line) or .tar.gz file'],
      ['Android', 'Android 7.0 or later (arm64 and x86_64)', 'Signed .apk on the releases page (allow installing from unknown sources)'],
      ['iOS and iPadOS', 'iOS 15 or later', 'App Store - in preparation'],
    ],
    moPhatHanh: 'Open the releases page',
    caiBangLenh: 'Install from the command line',
    lenhCai: 'Install command',
    tuCapNhat: 'Packages update themselves with each new release (SHA-256 hashes come from the release itself).',
    kiemChung: 'Verify your download',
    kiemChungDan: 'Every release includes a <code>SHA256SUMS</code> file. Check it before installing:',
    lenhKiem: 'Commands to verify the download',
    powershell: 'On Windows PowerShell:',
    lenhKiemWin: 'SHA-256 check command on Windows',
  },
  bang: {
    tieuDe: 'Account',
    moTa: 'Sound Db dashboard: view your synced measurement history, manage and revoke devices, download or delete all the data of your TsuDEV account.',
    h1: 'Sound Db account',
    dangTai: 'Loading...',
    chuaDangNhap: 'You are not signed in.',
    dangNhap: 'Sign in',
    goi: 'Plan and cloud sync',
    dangKiemPro: 'Checking your TsuDEV Pro plan...',
    mienPhi: `The free version includes every measuring feature; data is stored only on the device and never sent to the
          internet. Cloud sync and backup across devices is a TsuDEV Pro feature.`,
    // VERBATIM PRODUCT_POLICY 7.5 (en), {price} = 490.000 ₫ (7.2).
    dieuKhoan: 'TsuDEV Pro 490.000 ₫ for 1 year, does NOT renew automatically. Renewing early adds 1 year to your remaining time. If it expires without renewal, the app returns to the free version and stops syncing to the cloud; data on your device stays intact, and your cloud copy can be downloaded for 90 days before it is deleted.',
    xemPro: 'See Pro plan',
    ungHo: 'Support TsuDEV',
    taiJson: 'Download all data (JSON)',
    dangXuat: 'Sign out',
    phienDo: 'Measurement sessions',
    timTheoTen: 'Search by session name',
    bangPhien: 'Session table',
    cotPhien: ['Name', 'Started', 'Duration'],
    thaoTac: 'Actions',
    soDong: 'Rows per page',
    moiTrang: '/ page',
    truoc: 'Previous page',
    sau: 'Next page',
    thietBi: 'Signed-in devices',
    bangThietBi: 'Device table',
    cotThietBi: ['Device', 'Platform', 'Last seen'],
    hoatDong: 'Recent security activity',
    bangHoatDong: 'Security activity table',
    cotHoatDong: ['Event', 'Time'],
    xoaDuLieu: 'Delete data',
    xoaDan: 'Permanently delete all your measurement sessions, calibration profiles and devices on the Sound Db server. Your TsuDEV account is not affected.',
    nutXoa: 'Delete all Sound Db data',
  },
  js: {
    loiHttp: 'HTTP error {x}',
    loi: 'Error',
    thatBai: 'The action failed. Please try again.',
    phienDo: 'Measurement session',
    xoa: 'Delete',
    xacNhanXoaPhien: 'Delete session "{x}" on every device?',
    khongKhop: 'No matching sessions.',
    chuaCoPhien: 'No measurement sessions have been synced yet.',
    dangXuatThietBi: 'Sign out device',
    xacNhanDangXuat: 'Sign "{x}" out of your account?',
    suKien: {
      login: 'Signed in',
      device_added: 'Device added',
      device_revoked: 'Device revoked',
      logout: 'Device signed out',
      refresh_reuse_revoked: 'Token reuse detected - device revoked',
    },
    proLoi: 'Could not check your TsuDEV Pro plan right now. Data on your devices is not affected.',
    proToi: 'TsuDEV Pro until {x}: cloud sync and backup are on.',
    giaHan: 'Renew',
    proMienPhi: 'Free version: syncing to the cloud is off. You can still view, download and delete the data already in the cloud.',
    hanXoa: 'Your cloud copy can be downloaded until {x}.',
    thongKe: '{a} sessions · {b} calibration profiles · {c} measured',
    khongTai: 'Could not load data: {x}',
    nhapXacNhan: 'Type "xoa-vinh-vien" to confirm deleting all Sound Db data:',
    sai: 'The confirmation text does not match - nothing was deleted.',
  },
};
