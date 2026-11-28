-- QRFlux: enable dynamic QR resolution and scan analytics.
-- Run this once in Supabase SQL Editor AFTER 001_qrflux.sql.
-- This does not drop tables or delete existing data.

create index if not exists qr_scans_code_time_idx
  on public.qr_scans(qr_code_id, scanned_at desc);

create or replace function public.resolve_dynamic_qr(
  p_short_id text,
  p_device_type text default null
)
returns table (
  qr_code_id uuid,
  name text,
  qr_type text,
  payload text,
  form jsonb
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_record public.qr_codes%rowtype;
begin
  if p_short_id is null or length(trim(p_short_id)) = 0 then
    return;
  end if;

  select *
    into v_record
    from public.qr_codes
   where qr_mode = 'dynamic'
     and short_id = trim(p_short_id)
   limit 1;

  if v_record.id is null then
    return;
  end if;

  insert into public.qr_scans (qr_code_id, device_type)
  values (
    v_record.id,
    nullif(trim(coalesce(p_device_type, '')), '')
  );

  return query
  select
    v_record.id,
    v_record.name,
    v_record.qr_type,
    coalesce(
      nullif(trim(coalesce(v_record.qr_content->>'target', '')), ''),
      v_record.qr_content->>'payload'
    ),
    v_record.qr_content->'form';
end;
$$;

revoke execute on function public.resolve_dynamic_qr(text, text) from public;
grant execute on function public.resolve_dynamic_qr(text, text) to anon, authenticated;

create or replace function public.qr_codes_touch_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists qr_codes_touch_updated_at_trigger on public.qr_codes;
create trigger qr_codes_touch_updated_at_trigger
before update on public.qr_codes
for each row
execute procedure public.qr_codes_touch_updated_at();

-- Keep scanner access narrow: the resolver is the only public lookup surface.
-- qr_codes and qr_scans remain protected by their existing RLS policies.
