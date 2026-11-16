#!/usr/bin/env bash
# Dựng lõi DSP Rust thành WebAssembly cho máy đo trên trình duyệt (apps/web/public/wasm/).
# Cần: rustup target add wasm32-unknown-unknown; cargo install wasm-bindgen-cli --version <khớp Cargo.lock>.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=apps/web/public/wasm
want=$(awk '/name = "wasm-bindgen"/{getline; gsub(/[^0-9.]/,""); print; exit}' Cargo.lock)
have=$(wasm-bindgen --version 2>/dev/null | awk '{print $2}')
if [ "$want" != "$have" ]; then
  echo "wasm-bindgen-cli $have không khớp thư viện $want: cargo install wasm-bindgen-cli --version $want --locked" >&2
  exit 1
fi
cargo build -p sounddb-dsp --release --target wasm32-unknown-unknown --features wasm
rm -rf "$OUT" && mkdir -p "$OUT"
wasm-bindgen --target web --no-typescript --out-dir "$OUT" target/wasm32-unknown-unknown/release/sounddb_dsp.wasm
ls -l "$OUT"
