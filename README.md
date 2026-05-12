# CompliSA Validation Survey (Supabase + Live Dashboard)

This folder contains:

- `index.html` — the survey served at `/` on Vercel or any static host
- `dashboard.html` — an admin-only live dashboard (login required)
- `supabase_schema.sql` — database schema + Row Level Security policies

## Supabase setup

1) Create a Supabase project.

2) In Supabase **SQL Editor**, run `supabase_schema.sql`.

3) Enable Realtime for the table (if needed):
- In Supabase UI, go to **Database → Replication** and enable **Realtime** for `survey_responses`.

## Vercel + environment variables

Vercel does not expose env vars to static HTML at **runtime**, so this project uses a **build step** that bakes the values into the files.

1. In Vercel: **Project → Settings → Environment Variables**, add (for **Production** and **Preview** as needed):

   | Name | Value |
   |------|--------|
   | `NEXT_PUBLIC_SUPABASE_URL` | `https://YOUR_PROJECT.supabase.co` |
   | `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase **anon** public key (API settings) |

   The inject script also accepts `SUPABASE_URL` and `SUPABASE_ANON_KEY` if you prefer those names.

2. Ensure Vercel runs a build: **`vercel.json`** sets **`outputDirectory`** to **`public`**. The script **`scripts/inject-env.js`** copies **`index.html`** and **`dashboard.html`** from the repo root into **`public/`** with env vars injected (root files stay as templates with placeholders).

3. If your Vercel project still has a **wrong Output Directory** in the dashboard UI, either clear it or set it to **`public`** so it matches **`vercel.json`**.

4. Redeploy after changing env vars.

**Important:** Use only the **anon** key here (it is designed to be public with RLS). Never put the **service_role** key in env vars that get injected into HTML.

**Variable names:** The build script only reads these names (copy exactly):

- `NEXT_PUBLIC_SUPABASE_URL` **or** `SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` **or** `SUPABASE_ANON_KEY`

If you used different names in Vercel (for example only `SUPABASE_ANON_KEY` without `NEXT_PUBLIC_`), either rename them to match **or** add duplicate entries with the names above pointing at the same values.

After changing env vars, trigger a **new deployment** (Redeploy); static HTML does not pick up new env until build runs again.

If you run **`npm run vercel-build`** locally without env vars set, **`public/`** will contain HTML with empty credentials — delete **`public/`** or rerun with env set. Root **`index.html`** / **`dashboard.html`** are no longer overwritten by the inject script.

## Configure the survey (without Vercel)

Open `index.html` and use **`'<meta name="complisa-supabase-…">'`** (see below), **or** rely on build injection above:

```html
<meta name="complisa-supabase-url" content="https://YOUR_PROJECT.supabase.co">
<meta name="complisa-supabase-anon-key" content="YOUR_ANON_KEY">
```

Both values are under Supabase **Project Settings → API**.

Each row inserts into `survey_responses` with **`payload`** (answers + **`answer_codes`**, **`_meta`**) plus top-level **`source`** (`web`) and **`survey_schema_version`** (default `2`). If your database was created from an older file without those columns, re-run `supabase_schema.sql` migrations or submissions fall back automatically to a minimal insert.

## Configure dashboard access (admin allowlist)

The dashboard requires a Supabase Auth user that is allowlisted in `dashboard_admins`.

1) Create a user in **Authentication → Users** (email/password).
2) Add them to the allowlist by inserting their `user_id` into `dashboard_admins`.

Example:

```sql
insert into public.dashboard_admins (user_id)
values ('00000000-0000-0000-0000-000000000000');
```

## Using the dashboard

Open `dashboard.html` in a browser:

1) If you deployed with Vercel env injection, URL + anon key are prefilled from the build. Otherwise paste them manually (stored in your browser local storage when you click **Save config**).
2) Log in
3) You’ll see live updates as new survey responses arrive
4) Export data via **Export CSV** or **Export Excel**

## Notes / security

- The survey allows **anon inserts only** (no anonymous reads).
- The dashboard reads are limited via RLS to users present in `dashboard_admins`.

