import { cloudflareTest, readD1Migrations } from '@cloudflare/vitest-pool-workers';
import { defineConfig } from 'vitest/config';

export default defineConfig(async () => {
  const migrations = await readD1Migrations('./migrations');
  return {
    plugins: [
      cloudflareTest({
        wrangler: { configPath: './wrangler.test.jsonc' },
        miniflare: {
          bindings: {
            TEST_MIGRATIONS: migrations,
            SESSION_SECRET: 'test-secret-test-secret-test-secret-0123456789',
            IP_HASH_SALT: 'test-salt',
            // Ghim ở đây vì .dev.vars của máy dev (PUBLIC_ORIGIN=http://localhost:8787) đè `vars` của wrangler.test.jsonc.
            PUBLIC_ORIGIN: 'https://sounddb.tsudev.com',
          },
        },
      }),
    ],
    test: { setupFiles: ['./test/apply-migrations.ts'] },
  };
});
