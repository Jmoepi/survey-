# CompliSA Validation Survey (Supabase + Live Dashboard)

This folder contains:

- `CompliSA-Validation-Survey Final.html` — the survey (public link)
- `dashboard.html` — an admin-only live dashboard (login required)
- `supabase_schema.sql` — database schema + Row Level Security policies

## Supabase setup

1) Create a Supabase project.

2) In Supabase **SQL Editor**, run `supabase_schema.sql`.

3) Enable Realtime for the table (if needed):
- In Supabase UI, go to **Database → Replication** and enable **Realtime** for `survey_responses`.

## Configure the survey

Open `CompliSA-Validation-Survey Final.html` and set:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

These are in your Supabase project settings (API).

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

1) Paste `Supabase Project URL` + `anon key` (stored in your browser local storage)
2) Log in
3) You’ll see live updates as new survey responses arrive
4) Export data via **Export CSV** or **Export Excel**

## Notes / security

- The survey allows **anon inserts only** (no anonymous reads).
- The dashboard reads are limited via RLS to users present in `dashboard_admins`.

