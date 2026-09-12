-- ============================================================
-- AcadNova — Supabase setup script
-- Paste this whole file into Supabase Dashboard → SQL Editor → New query → Run
-- ============================================================

-- Table: one row per message an applicant sends to a professor
create table if not exists professor_contacts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) not null,
  professor_id text not null,
  professor_name text not null,
  university_name text not null,
  message text not null,
  contact_method text not null default 'in_app_outbox', -- 'in_app_outbox' | 'mailto'
  created_at timestamptz default now()
);

-- Row Level Security: each applicant can only ever see/insert their own messages
alter table professor_contacts enable row level security;

create policy "Users can view their own messages"
  on professor_contacts for select
  using (auth.uid() = user_id);

create policy "Users can send their own messages"
  on professor_contacts for insert
  with check (auth.uid() = user_id);

-- ============================================================
-- That's it. After running this once, your app's "Register" / "Log in" /
-- "Message professor" / "My Outbox" features will work for real.
-- ============================================================
