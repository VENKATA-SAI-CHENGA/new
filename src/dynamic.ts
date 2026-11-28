import { supabase } from "./supabase";

export type ResolvedQr = {
  qr_code_id: string;
  name: string;
  qr_type: string;
  payload: string;
  form: Record<string, string> | null;
};

export function detectDevice(): string {
  const ua = navigator.userAgent;
  if (/iPad|Tablet|PlayBook|Silk/i.test(ua) || (/Android/i.test(ua) && !/Mobile/i.test(ua))) return "Tablet";
  if (/Mobi|iPhone|Android|Windows Phone|BlackBerry/i.test(ua)) return "Mobile";
  return "Desktop";
}

const ALPHABET = "abcdefghjkmnpqrstuvwxyz23456789";
export function makeShortId(): string {
  const bytes = new Uint8Array(8);
  crypto.getRandomValues(bytes);
  let id = "";
  for (const b of bytes) id += ALPHABET[b % ALPHABET.length];
  return id;
}

export const SITE_URL_KEY = "qrflux_site_url";
export function getSiteUrl(): string {
  const saved = (localStorage.getItem(SITE_URL_KEY) || "").trim().replace(/\/+$/, "");
  if (saved && /^https?:\/\//i.test(saved)) return saved;
  return window.location.origin;
}

export function shortLinkFor(shortId: string): string {
  return `${getSiteUrl()}/s/${shortId}`;
}

export async function resolveDynamicQr(shortId: string): Promise<ResolvedQr | null> {
  const { data, error } = await supabase.rpc("resolve_dynamic_qr", {
    p_short_id: shortId,
    p_device_type: detectDevice(),
  });
  if (error) throw error;
  const row: any = Array.isArray(data) ? data[0] : data;
  if (!row || !row.payload) return null;
  return {
    qr_code_id: row.qr_code_id,
    name: row.name,
    qr_type: row.qr_type,
    payload: row.payload,
    form: (row.form ?? null) as Record<string, string> | null,
  };
}
