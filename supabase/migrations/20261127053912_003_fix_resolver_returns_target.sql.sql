/*
# Fix dynamic resolver to return the true destination

1. Purpose
- Bug fix: for dynamic QR codes the resolver returned the short link stored in
  qr_content->>'payload' (which is what gets encoded in the QR image) instead of
  the owner's real destination stored in qr_content->>'target'. Scanners were
  redirected back to the scan page in a loop, and action buttons (email,
  WhatsApp, phone, UPI) opened the short link instead of the real action.

2. Modified functions
- `public.resolve_dynamic_qr(p_short_id text, p_device_type text)`: now returns
  coalesce(qr_content->>'target', qr_content->>'payload') as the payload, so
  dynamic codes resolve to the destination the owner set. Static codes are
  unaffected (they are never resolved through this function).

3. Security changes
- None. Same grants as before: EXECUTE revoked from PUBLIC, granted to anon and
  authenticated only.
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
         coalesce(nullif(trim(coalesce(v_record.qr_content->>'target','')),''), v_record.qr_content->>'payload'),
         v_record.qr_content->'form';
end;
$$;

revoke execute on function public.resolve_dynamic_qr(text, text) from public;
revoke execute on function public.resolve_dynamic_qr(text, text) from anon;
grant execute on function public.resolve_dynamic_qr(text, text) to anon, authenticated;
