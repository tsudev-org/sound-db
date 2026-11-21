# Contributing to Sound Db

_Tiếng Việt: mọi đóng góp đều được chào đón. Bạn có thể viết issue và pull request bằng tiếng Việt hoặc tiếng Anh._

Sound Db is the precision sound level meter of the TsuDEV ecosystem (IEC 61672-1 levels, FFT spectrum, spectrogram,
1/1 and 1/3 octave bands per IEC 61260-1, pitch, noise dose, signal generator) for Android, iOS, Windows, macOS, Linux
and the web. The repository is a monorepo:

| Directory | What | Stack |
| --- | --- | --- |
| `packages/dsp-core` | Reference DSP core (the accuracy of every platform) + WebAssembly wrapper | Rust |
| `packages/dsp-dart` | Dart port of the core, must match `conformance/vectors.json` | Dart |
| `apps/app` | Mobile + desktop app | Flutter (version pinned in `.fvmrc`) |
| `apps/web` | Website, in-browser meter and account dashboard | Astro, TypeScript |
| `services/sync-api` | Sign-in (OIDC relying party of tsudev.com), app tokens, sync | Cloudflare Workers + D1, Hono |

Architecture: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). Measurement method and limits:
[docs/MEASUREMENT.md](docs/MEASUREMENT.md). Design decisions: [docs/adr/](docs/adr/).

## Reporting bugs and requesting features

- **Bug**: open an issue with the *Bug report* form: <https://github.com/tsudev-org/sound-db/issues/new/choose>.
  Include the platform (Android, iOS, Windows, macOS, Linux or web), app version (release tag),
  device/microphone and steps to reproduce. For a measurement error, include the reference value and how it was made.
- **Feature**: use the *Feature request* form.
- **Security vulnerability**: never in a public issue - see [SECURITY.md](SECURITY.md) (private vulnerability
  reporting on the Security tab).

## Getting the source, building and testing

```bash
git clone https://github.com/tsudev-org/sound-db.git
cd sound-db

# Rust reference DSP core: format, clippy (warnings are errors), unit + accuracy + fuzz tests
cargo fmt --all --check
cargo clippy -p sounddb-dsp --all-targets -- -D warnings
cargo test -p sounddb-dsp

# Dart port: must reproduce the Rust conformance vectors
(cd packages/dsp-dart && dart pub get && dart analyze --fatal-infos && dart test)

# Flutter app (Flutter version from .fvmrc)
(cd apps/app && flutter pub get && flutter analyze && flutter test)

# Website + server (npm >= 11)
npm ci
npm run wasm && npm --workspace apps/web run build
npm --workspace apps/web run typecheck
npm --workspace services/sync-api run typecheck
npm --workspace services/sync-api test        # API tests on the real workerd runtime

# TsuDEV standards
./scripts/check-standards.sh && ./scripts/sync-standards.sh --check
```

CI ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)) runs these steps on every pull request and push to `main`,
plus Linux, iOS and macOS build checks, `npm audit --omit=dev --audit-level=high` and a gitleaks scan of the full
history. CodeQL ([`.github/workflows/codeql.yml`](.github/workflows/codeql.yml)) and OpenSSF Scorecard run as well.

## Pull request requirements

Every change goes through a pull request into `main` (direct pushes are blocked by a ruleset) and is squash-merged.

1. **One change per pull request**, with a description of what and why. Commit messages follow
   [Conventional Commits](https://www.conventionalcommits.org/) (`feat: ...`, `fix: ...`, `docs: ...`).
2. **Tests**: every change in behaviour comes with tests in the same pull request. A bug fix comes with a regression
   test that fails without the fix. Changes to sign-in, tokens or sync also need a negative test (expired, tampered,
   replayed or foreign-user input is rejected).
3. **One DSP, two implementations**: a change to the signal processing goes into the Rust reference first, then the
   Dart port, and `conformance/vectors.json` is regenerated in the same pull request; CI fails if the vectors do not
   match the code.
4. **CI must be green**, with no new warnings (clippy `-D warnings`, `dart analyze --fatal-infos`, `flutter analyze`,
   strict TypeScript).
5. **Cryptography**: no home-made primitives. Use WebCrypto / `jose` on the server and the platform secure random
   generator and key store in the app.
6. **User-visible changes** get an entry in [CHANGELOG.md](CHANGELOG.md) under "Chưa phát hành" (Unreleased).

## Versioning and releases

Versions are calendar based, `YY.M.DDNN` (for example `26.11.1705`, see the TsuDEV `VERSIONING.md`); each release is
a git tag `v<version>` on `main`. The release workflow builds every platform from the tag and publishes the files with
`SHA256SUMS` and GitHub build provenance attestations.

## License

By contributing you agree that your contribution is licensed under the [Apache License 2.0](LICENSE).
