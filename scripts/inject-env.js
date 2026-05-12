/**
 * Build-time injection for Vercel (and local): replaces placeholders in HTML with env vars.
 * Reads: NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY
 *        or SUPABASE_URL, SUPABASE_ANON_KEY
 */
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
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
    .replace(/'__COMPLISA_TOKEN_SUPABASE_URL__'/g, JSON.stringify(url))
    .replace(/'__COMPLISA_TOKEN_SUPABASE_ANON_KEY__'/g, JSON.stringify(anon));
}

for (const name of files) {
  const fp = path.join(root, name);
  if (!fs.existsSync(fp)) continue;
  const raw = fs.readFileSync(fp, 'utf8');
  fs.writeFileSync(fp, inject(raw), 'utf8');
}

if (!url || !anon) {
  console.warn(
    'inject-env: NEXT_PUBLIC_SUPABASE_URL / NEXT_PUBLIC_SUPABASE_ANON_KEY not both set — placeholders left empty strings.'
  );
} else {
  console.log('inject-env: injected Supabase URL + anon key into', files.join(', '));
}
