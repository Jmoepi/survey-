-- CompliSA Validation Survey: Supabase schema + RLS
-- Run in Supabase SQL editor.

create table if not exists public.survey_responses (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),

  -- high-level fields for filtering / exports (mirrors payload where applicable)
  role text,
  name text,
  company text,
  email text,
  phone text,

  -- provenance / schema evolution for `payload` shape
  source text not null default 'web',
  survey_schema_version integer not null default 2,

  -- full response payload (includes answers, labels, `answer_codes`, `_meta`)
  payload jsonb not null,

  -- lightweight metadata (no IP captured from browser)
  user_agent text
);

-- Migrate older databases created before these columns existed
alter table public.survey_responses
  add column if not exists source text not null default 'web';

alter table public.survey_responses
  add column if not exists survey_schema_version integer not null default 2;

alter table public.survey_responses
  drop constraint if exists survey_responses_role_check;

alter table public.survey_responses
  add constraint survey_responses_role_check
    check (
      role is null
      or role in ('Employer', 'Practitioner')
    );

create index if not exists survey_responses_created_at_desc_idx
  on public.survey_responses (created_at desc);

create index if not exists survey_responses_role_created_at_idx
  on public.survey_responses (role, created_at desc);

alter table public.survey_responses enable row level security;

-- Allow anyone (anon) to insert responses.
drop policy if exists "survey_responses_insert_anon" on public.survey_responses;
create policy "survey_responses_insert_anon"
on public.survey_responses
for insert
to anon
with check (true);

-- Disallow reads/updates/deletes for anon by default (no policies = denied).

-- Admin allowlist for dashboard access
create table if not exists public.dashboard_admins (
  user_id uuid primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.dashboard_admins enable row level security;

drop policy if exists "dashboard_admins_self_read" on public.dashboard_admins;
create policy "dashboard_admins_self_read"
on public.dashboard_admins
for select
to authenticated
using (auth.uid() = user_id);

-- Authenticated admins can read survey responses
drop policy if exists "survey_responses_select_admins" on public.survey_responses;
create policy "survey_responses_select_admins"
on public.survey_responses
for select
to authenticated
using (exists (
  select 1 from public.dashboard_admins a
  where a.user_id = auth.uid()
));

-- Optional: allow admins to delete test rows from the dashboard
drop policy if exists "survey_responses_delete_admins" on public.survey_responses;
create policy "survey_responses_delete_admins"
on public.survey_responses
for delete
to authenticated
using (exists (
  select 1 from public.dashboard_admins a
  where a.user_id = auth.uid()
));

-- Realtime (for live dashboard updates).
-- Safe to run more than once. You can also enable Realtime for this table in the Supabase UI.
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'survey_responses'
  ) then
    execute 'alter publication supabase_realtime add table public.survey_responses';
  end if;
end $$;

