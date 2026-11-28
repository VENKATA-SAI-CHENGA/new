/*
# Dynamic QR codes and public scan tracking

1. Purpose
- Enables every QR type (URL, Multi-URL, vCard, Email, WhatsApp, SMS, Phone,
  Wi-Fi, UPI, Maps, Text) to work in "dynamic" mode: the printed QR code encodes
  a short link (/s/<short_id>) instead of the final destination. The owner can
  change the destination later, and every scan is recorded for analytics.

2. New functions
- `public.resolve_dynamic_qr(p_short_id text, p_device_type text)`
  SECURITY DEFINER resolver for scanners (who are never signed in):
  - Looks up a single dynamic qr_codes row by short_id (short_id is UNIQUE).
  - Inserts one qr_scans row (the scan event) for that code.
  - Returns only what a scanner needs: qr_code_id, name, qr_type, the encoded
    payload and the original form values. Returns nothing if no dynamic code
    matches. It never exposes other users' rows or any owner identity.

3. Modified tables
- `public.qr_scans`: index on (qr_code_id, scanned_at desc) for per-code
  analytics queries.

4. Security changes
- resolve_dynamic_qr is the ONLY public surface for dynamic redirects.
- The qr_codes and qr_scans tables keep RLS with owner-only policies; no new
  table policies are added and no table-level grants are given to anon.
- EXECUTE on resolve_dynamic_qr is revoked from PUBLIC and granted explicitly
  to anon + authenticated (scanners are anonymous by design; the function is
  narrowly scoped to one lookup-by-short-id plus one scan insert).
- New trigger `qr_codes_touch_updated_at` keeps updated_at fresh on edits.

5. Notes
- Only rows with qr_mode = 'dynamic' and a non-null short_id are resolvable,
  so existing static codes stay fully private.
*/

create or replace function public.resolve_dynamic_qr(p_short_id text, p_device_type text default null)
returns table (qr_code_id uuid, name text, qr_type text, payload text, form jsonb)
language plpgsql security definer set search_path = public
as $$
declare
  v_record public.qr_codes%rowtype;
begin
  if p_short_id is null or length(trim(p_short_id)) = 0 then
    return;
  end if;

  select * into v_record
  from public.qr_codes
  where qr_mode = 'dynamic' and short_id = trim(p_short_id)
  limit 1;

  if v_record.id is null then
    return;
  end if;

  insert into public.qr_scans (qr_code_id, device_type)
  values (v_record.id, nullif(trim(coalesce(p_device_type, '')), ''));

  return query
  select v_record.id,
         v_record.name,
         v_record.qr_type,
         v_record.qr_content->>'payload',
         v_record.qr_content->'form';
end;
$$;

revoke execute on function public.resolve_dynamic_qr(text, text) from public;
revoke execute on function public.resolve_dynamic_qr(text, text) from anon;
grant execute on function public.resolve_dynamic_qr(text, text) to anon, authenticated;

create index if not exists qr_scans_code_time_idx on public.qr_scans(qr_code_id, scanned_at desc);

create or replace function public.qr_codes_touch_updated_at()
returns trigger language plpgsql set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists qr_codes_touch_updated_at_trigger on public.qr_codes;
create trigger qr_codes_touch_updated_at_trigger
before update on public.qr_codes
for each row execute procedure public.qr_codes_touch_updated_at();
