import { z } from 'zod';

/**
 * Hợp đồng dữ liệu đồng bộ - khớp `apps/app/lib/data/models.dart`. Mọi trường
 * có trần: một bản ghi phiên đo tối đa 7200 điểm chuỗi thời gian (~60 KB).
 */
const db = z.number().min(-100).max(250).nullable();
const finite = z.number().refine(Number.isFinite);

export const sessionData = z
  .object({
    v: z.literal(1),
    started_at: z.iso.datetime({ offset: true }),
    duration_s: finite.min(0).max(31 * 24 * 3600),
    label: z.string().max(120),
    note: z.string().max(2000),
    summary: z.partialRecord(
      z.enum(['laeq', 'lceq', 'lzeq', 'lafmax', 'lafmin', 'lasmax', 'lcpeak', 'l10', 'l50', 'l90', 'dose_niosh', 'dose_osha', 'twa_niosh', 'sel_a']),
      z.number().min(-1000).max(1e9).nullable(),
    ),
    series: z.object({ interval_s: finite.min(0.1).max(3600), laeq: z.array(db).max(7200) }),
    third_octave_lzeq: z.record(z.string().regex(/^\d{1,5}(\.\d)?$/), finite.min(-100).max(250)).refine((r) => Object.keys(r).length <= 40),
    calibration_offset_db: finite.min(-50).max(250),
    device_model: z.string().max(120),
    platform: z.string().max(20),
  })
  .strict();

const calibrationData = z
  .object({
    v: z.literal(1),
    name: z.string().min(1).max(120),
    offset_db: finite.min(-50).max(250),
    method: z.enum(['manual', 'calibrator_94', 'calibrator_114', 'reference_meter']),
  })
  .strict();

const KINDS = ['session', 'calibration'] as const;
export type Kind = (typeof KINDS)[number];

const change = z.object({
  kind: z.enum(KINDS),
  id: z.uuid(),
  updated_at: z.number().int().min(1_600_000_000_000),
  deleted: z.boolean(),
  data: z.record(z.string(), z.unknown()),
});

export const pushBody = z.object({ changes: z.array(change).min(1).max(50) });

export function validateData(kind: Kind, deleted: boolean, data: unknown): Record<string, unknown> {
  // Bia mộ (đã xóa) không giữ nội dung: xóa là xóa thật trên máy chủ.
  if (deleted) return {};
  return (kind === 'session' ? sessionData : calibrationData).parse(data) as Record<string, unknown>;
}

export const MAX_RECORD_BYTES = 200_000;
