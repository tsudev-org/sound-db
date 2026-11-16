// Bọc lõi DSP WebAssembly (packages/dsp-core, dựng bằng scripts/build-wasm.sh vào public/wasm/).
// Bố cục mảng mức âm khớp `LevelSnapshot::to_flat` (Rust) - 46 số.

export interface Levels {
  instant: number[][]; // [A,C,Z][F,S,I]
  leq: number[];
  max: number[][];
  min: number[][];
  peak: number[];
  percentiles: number[]; // 1,5,10,50,90,95,99
  selA: number;
  doseNiosh: number;
  doseOsha: number;
  twaNiosh: number;
  twaOsha: number;
  elapsed: number;
}

export function decodeLevels(f: Float64Array | number[]): Levels {
  const a = Array.from(f);
  const grid = (o: number) => [a.slice(o, o + 3), a.slice(o + 3, o + 6), a.slice(o + 6, o + 9)];
  return {
    instant: grid(0),
    leq: a.slice(9, 12),
    max: grid(12),
    min: grid(21),
    peak: a.slice(30, 33),
    percentiles: a.slice(33, 40),
    selA: a[40]!,
    doseNiosh: a[41]!,
    doseOsha: a[42]!,
    twaNiosh: a[43]!,
    twaOsha: a[44]!,
    elapsed: a[45]!,
  };
}

export interface WasmEngine {
  push(samples: Float32Array): void;
  setCalibration(offset: number): void;
  levels(): Float64Array;
  spectrum(weighting: number, peakHold: boolean): Float32Array;
  dominantPeak(minHz: number, maxHz: number): Float64Array;
  pitch(): Float64Array;
  bandCenters(fraction: number): Float64Array;
  bandLevels(fraction: number, weighting: number): Float64Array;
  binHz(): number;
  resetSession(): void;
  free(): void;
}

interface WasmModule {
  default: (init: { module_or_path: string }) => Promise<unknown>;
  WasmEngine: new (sampleRate: number, fftSize: number, window: number, offset: number) => WasmEngine;
}

export async function loadEngine(sampleRate: number, offsetDb: number): Promise<WasmEngine> {
  const path = '/wasm/sounddb_dsp.js';
  const mod = (await import(/* @vite-ignore */ path)) as WasmModule;
  await mod.default({ module_or_path: '/wasm/sounddb_dsp_bg.wasm' });
  return new mod.WasmEngine(sampleRate, 8192, 1, offsetDb);
}
