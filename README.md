# Sound Db

[![OpenSSF Best Practices](https://www.bestpractices.dev/projects/16974/badge)](https://www.bestpractices.dev/projects/16974)

Máy đo âm thanh chính xác của hệ sinh thái [TsuDEV](https://tsudev.com): mức âm (dB) theo IEC 61672-1, phổ
tần số FFT, phổ đồ, dải octave 1/1 và 1/3 (IEC 61260-1), cao độ/nốt nhạc, liều tiếp xúc tiếng ồn, bộ phát tín
hiệu và hiệu chuẩn - trên **Android, iOS, Windows, macOS, Linux** và **trình duyệt**.
Đăng nhập tài khoản TsuDEV (không bắt buộc) để đồng bộ lịch sử đo và hiệu chuẩn giữa các thiết bị.

- Website: <https://sound.tsudev.com> · máy đo trên web: <https://sound.tsudev.com/do/>
- Hạng sản phẩm: **B - app có kết nối** (`.standards/docs/AUTH_AND_ACCOUNT.md` mục 1): mọi chức năng đo chạy
  ngoại tuyến ở chế độ khách; đăng nhập chỉ mở thêm đồng bộ.
- Giấy phép: [Apache 2.0](LICENSE).

## Cấu trúc (hình trạng B - monorepo)

| Thư mục | Là gì | Công nghệ |
| --- | --- | --- |
| `packages/dsp-core` | Lõi DSP **tham chiếu** (độ chính xác của cả hệ) + lớp vỏ WASM | Rust |
| `packages/dsp-dart` | Bản Dart của lõi, phải khớp `conformance/vectors.json` | Dart |
| `apps/app` | App di động + desktop | Flutter 3.47.9 (`.fvmrc`) |
| `apps/web` | Website + máy đo trên trình duyệt + bảng điều khiển tài khoản | Astro, TypeScript |
| `services/sync-api` | Đăng nhập (RP OIDC của tsudev.com), token app, đồng bộ; phục vụ luôn website tĩnh | Cloudflare Workers + D1, Hono |
| `tokens/` | Khối token riêng (bảng đen tuyền + xanh logo, màu biểu đồ) ghép lên `.standards/tokens` | JSON |

Kiến trúc và lý do chọn: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md). Phương pháp đo và giới hạn:
[`docs/MEASUREMENT.md`](docs/MEASUREMENT.md). Triển khai: [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md).

## Chạy trong 5 phút

```bash
# Lõi DSP + vector đối chiếu
cargo test -p sounddb-dsp
(cd packages/dsp-dart && dart test)

# App (cần Flutter 3.47.9)
cd apps/app && flutter pub get && flutter run            # thêm --dart-define=SOUNDDB_API=http://127.0.0.1:8787 để dùng máy chủ local

# Website + máy chủ (cần npm >= 11: `npx npm@11 install`)
npm install
npm run wasm && npm --workspace apps/web run build
npm --workspace services/sync-api run migrate:local
npm --workspace services/sync-api run dev                # http://127.0.0.1:8787 (cần services/sync-api/.dev.vars)
npm test                                                  # 17 test API trên workerd thật
```

`services/sync-api/.dev.vars` (không commit) - sinh ngẫu nhiên tại máy, không chép bí mật thật vào đây:

```bash
printf 'SESSION_SECRET=%s\nIP_HASH_SALT=%s\nPUBLIC_ORIGIN=http://localhost:8787\n' \
  "$(openssl rand -base64 48)" "$(openssl rand -base64 24)" > services/sync-api/.dev.vars && chmod 600 services/sync-api/.dev.vars
```

Bí mật thật (Cloudflare, khoá ký...) chỉ nhận bằng `tsu-nhan-bi-mat`, không dán vào chat/tệp - `docs/DEPLOYMENT.md` mục 2.

## Cổng kiểm

```bash
./scripts/check-standards.sh                 # quy ước tsudev
./scripts/sync-standards.sh --check          # bản sao .standards/ còn nguyên vẹn
node scripts/build-tokens.mjs --check        # token sinh ra khớp nguồn + tương phản WCAG AA
node apps/web/scripts/brand-assets.mjs --check
```

## English summary

Sound Db (Apache-2.0) is the precision sound level meter of the [TsuDEV](https://tsudev.com) ecosystem: sound level
(dB) per IEC 61672-1 with A/C/Z frequency and Fast/Slow/Impulse time weightings, Leq, percentiles and noise dose,
FFT spectrum and spectrogram, 1/1 and 1/3 octave bands per IEC 61260-1, pitch/note detection, a signal generator and
calibration - on Android, iOS, Windows, macOS, Linux and in the browser (<https://sound.tsudev.com>).

- **One DSP, two implementations**: the Rust core in `packages/dsp-core` is the reference (also compiled to
  WebAssembly for the web meter); the Dart port in `packages/dsp-dart` used by the Flutter app must reproduce the
  Rust conformance vectors (`conformance/vectors.json`), checked in CI.
- **Offline first**: every measurement works without an account; signing in with a TsuDEV account (OIDC against
  tsudev.com) only adds sync of measurement history and calibration.
- **Build and test**: see [CONTRIBUTING.md](CONTRIBUTING.md) (English). Security: [SECURITY.md](SECURITY.md).
