-- CompliSA survey dashboard RLS policies
-- Review before running in Supabase SQL Editor.

-- 1) Enable RLS on both tables.
alter table public.dashboard_admins enable row level security;
alter table public.survey_responses enable row level security;

-- 2) dashboard_admins: an authenticated user can only check their own allowlist row.
drop policy if exists "dashboard admins can read own allowlist row" on public.dashboard_admins;
create policy "dashboard admins can read own allowlist row"
on public.dashboard_admins
for select
to authenticated
using (auth.uid() = user_id);

-- 3) survey_responses: public survey form can insert responses using the anon key.
-- Tighten the WITH CHECK if your form has stricter validation needs.
drop policy if exists "public can submit survey responses" on public.survey_responses;
create policy "public can submit survey responses"
on public.survey_responses
for insert
to anon, authenticated
with check (
  payload is not null
  and coalesce(source, 'web') = 'web'
);

-- 4) survey_responses: only allowlisted dashboard admins can read responses.
drop policy if exists "allowlisted admins can read survey responses" on public.survey_responses;
create policy "allowlisted admins can read survey responses"
on public.survey_responses
for select
to authenticated
using (
  exists (
    select 1
    from public.dashboard_admins da
    where da.user_id = auth.uid()
  )
);

-- 5) Optional: allow allowlisted admins to delete test responses.
-- Keep disabled unless you intentionally need delete access from client-side admin tools.
-- drop policy if exists "allowlisted admins can delete survey responses" on public.survey_responses;
-- create policy "allowlisted admins can delete survey responses"
-- on public.survey_responses
-- for delete
-- to authenticated
-- using (
--   exists (
--     select 1
--     from public.dashboard_admins da
--     where da.user_id = auth.uid()
--   )
-- );

-- 6) Add your admin user after creating the user in Supabase Authentication.
-- Replace the UUID below with the user's auth.users.id value.
-- insert into public.dashboard_admins (user_id)
-- values ('00000000-0000-0000-0000-000000000000')
-- on conflict (user_id) do nothing;
