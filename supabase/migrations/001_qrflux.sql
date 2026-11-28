-- Run this migration in the Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  email text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.qr_codes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  qr_type text not null check (qr_type in ('url','multi-url','vcard','email','whatsapp','sms','phone','wifi','upi','maps','text')),
  qr_content jsonb not null,
  qr_mode text not null default 'static' check (qr_mode in ('static','dynamic')),
  short_id text unique,
  customization jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists qr_codes_user_created_idx on public.qr_codes(user_id, created_at desc);

create table if not exists public.qr_scans (
  id uuid primary key default gen_random_uuid(),
  qr_code_id uuid not null references public.qr_codes(id) on delete cascade,
  scanned_at timestamptz not null default now(),
  device_type text,
  country text
);

create table if not exists public.user_settings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles(id) on delete cascade,
  theme text not null default 'light',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.qr_codes enable row level security;
alter table public.qr_scans enable row level security;
alter table public.user_settings enable row level security;

create policy "profile_select_own" on public.profiles for select using (auth.uid() = id);
create policy "profile_insert_own" on public.profiles for insert with check (auth.uid() = id);
create policy "profile_update_own" on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);

create policy "qr_select_own" on public.qr_codes for select using (auth.uid() = user_id);
create policy "qr_insert_own" on public.qr_codes for insert with check (auth.uid() = user_id);
create policy "qr_update_own" on public.qr_codes for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "qr_delete_own" on public.qr_codes for delete using (auth.uid() = user_id);

-- Scan rows are private to the owner of the associated QR code.
create policy "scan_select_owner" on public.qr_scans for select
using (exists (select 1 from public.qr_codes q where q.id = qr_code_id and q.user_id = auth.uid()));
create policy "settings_select_own" on public.user_settings for select using (auth.uid() = user_id);
create policy "settings_insert_own" on public.user_settings for insert with check (auth.uid() = user_id);
create policy "settings_update_own" on public.user_settings for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Create a profile row whenever a new auth user is registered.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name',''), new.email)
  on conflict (id) do update set email = excluded.email;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Public dynamic QR routes are intentionally not enabled by this starter migration.
-- Add a separate, narrowly scoped public resolver (Edge Function/RPC) before exposing
-- dynamic destinations. Never make the entire qr_codes table publicly readable.
