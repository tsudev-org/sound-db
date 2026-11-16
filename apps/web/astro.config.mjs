import { defineConfig } from 'astro/config';

// Trang tĩnh. Script phía trình duyệt là tệp cùng nguồn (CSP script-src 'self'), không nội tuyến:
// assetsInlineLimit 0 để Vite không nhét script/CSS nhỏ vào HTML.
export default defineConfig({
  site: 'https://sounddb.tsudev.com',
  trailingSlash: 'always',
  compressHTML: true,
  build: { format: 'directory', inlineStylesheets: 'never' },
  vite: {
    server: { fs: { allow: ['../..'] } },
    build: { assetsInlineLimit: 0 },
  },
});
