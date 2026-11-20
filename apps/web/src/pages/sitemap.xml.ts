import { SITE } from '../lib/site';

const PAGES = ['/', '/do/', '/tai-ve/', '/huong-dan/', '/bao-mat/'].flatMap((p) => [p, `/en${p}`]);

export function GET() {
  const body = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${PAGES.map((p) => `  <url><loc>${SITE}${p}</loc></url>`).join('\n')}
</urlset>
`;
  return new Response(body, { headers: { 'Content-Type': 'application/xml; charset=utf-8' } });
}
