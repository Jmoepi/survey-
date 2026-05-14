/**
 * Build-time injection for Vercel (and local): reads template HTML from repo root,
 * replaces placeholders, writes to public/ (Vercel output directory).
 *
 * Reads: NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY
 *        or SUPABASE_URL, SUPABASE_ANON_KEY
 */
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const outDir = path.join(root, 'public');
const files = ['index.html', 'dashboard.html'];

const url =
  process.env.NEXT_PUBLIC_SUPABASE_URL ||
  process.env.SUPABASE_URL ||
  '';
const anon =
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
  process.env.SUPABASE_ANON_KEY ||
  '';

function inject(content) {
  return content
    .replace(/'__FINTEGRIS_TOKEN_SUPABASE_URL__'/g, JSON.stringify(url))
    .replace(/'__FINTEGRIS_TOKEN_SUPABASE_ANON_KEY__'/g, JSON.stringify(anon));
}

fs.mkdirSync(outDir, { recursive: true });

for (const name of files) {
  const src = path.join(root, name);
  if (!fs.existsSync(src)) continue;
  const raw = fs.readFileSync(src, 'utf8');
  fs.writeFileSync(path.join(outDir, name), inject(raw), 'utf8');
}

if (!url || !anon) {
  console.warn(
    'inject-env: NEXT_PUBLIC_SUPABASE_URL / NEXT_PUBLIC_SUPABASE_ANON_KEY not both set — placeholders left empty strings.'
  );
} else {
  console.log('inject-env: wrote Supabase-injected', files.join(', '), 'to public/');
}
