import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { resolveDynamicQr, type ResolvedQr } from "../dynamic";
import { QrCode, ArrowRight, CircleHelp, Download, Globe, Mail, MessageCircle, Phone, Smartphone, UserRound, Wifi, FileText, Link2 } from "lucide-react";

const typeIcon: Record<string, any> = { url: Globe, "multi-url": Link2, vcard: UserRound, email: Mail, whatsapp: MessageCircle, sms: MessageCircle, phone: Phone, wifi: Wifi, upi: Smartphone, maps: Globe, text: FileText };

function vcardToHtml(form: Record<string, string>): string {
  const rows: [string, string][] = [
    ["Name", form.name], ["Title", form.title], ["Company", form.company],
    ["Phone", form.phone], ["Email", form.email], ["Website", form.website], ["Address", form.address],
  ];
  return rows.filter(([, v]) => v).map(([k, v]) => `<div class="vc-row"><span>${k}</span><b>${v.replace(/</g, "&lt;")}</b></div>`).join("");
}

function DestinationView({ qr, onDownload }: { qr: ResolvedQr; onDownload: () => void }) {
  const Icon = typeIcon[qr.qr_type] || QrCode;
  const form = qr.form || {};
  switch (qr.qr_type) {
    case "vcard":
      return <div className="vc-card"><div className="vc-head"><span className="vc-avatar"><Icon size={26}/></span><div><b>{form.name || qr.name}</b>{form.title && <small>{form.title}{form.company ? ` · ${form.company}` : ""}</small>}</div></div>{vcardToHtml(form)}</div>;
    case "wifi":
      return <div className="wifi-card"><span className="vc-avatar"><Wifi size={24}/></span><div><b>{form.ssid || qr.name}</b><small>Network password: {form.password || "none"}</small></div></div>;
    case "multi-url":
      return <div className="multi-card"><b>{form.title || qr.name}</b>{form.description && <p>{form.description}</p>}{(form.links || "").split(/\n|,/).map((l, i) => l.trim() && <a key={i} className="multi-link" href={l.trim()} target="_blank" rel="noopener noreferrer">{l.trim()} <ArrowRight size={13}/></a>)}</div>;
    default:
      return <div className="dest-card"><span className="vc-avatar"><Icon size={24}/></span><div><b>{qr.name}</b><small>{qr.payload.length > 120 ? qr.payload.slice(0, 120) + "…" : qr.payload}</small></div></div>;
  }
}

function isDirectUrl(qr: ResolvedQr): boolean {
  return qr.qr_type === "url" || (qr.qr_type === "maps" && /^https?:\/\//i.test(qr.payload));
}

export default function ScanRedirect() {
  const { shortId = "" } = useParams();
  const [state, setState] = useState<"loading"|"ready"|"notfound"|"error">("loading");
  const [qr, setQr] = useState<ResolvedQr | null>(null);

  useEffect(() => {
    let active = true;
    (async () => {
      try {
        const resolved = await resolveDynamicQr(shortId);
        if (!active) return;
        if (!resolved) { setState("notfound"); return; }
        setQr(resolved);
        setState("ready");
        if (isDirectUrl(resolved)) window.location.replace(resolved.payload);
      } catch {
        if (active) setState("error");
      }
    })();
    return () => { active = false; };
  }, [shortId]);

  async function downloadVcf() {
    if (!qr) return;
    const form = qr.form || {};
    const vcf = ["BEGIN:VCARD", "VERSION:3.0", `FN:${form.name || qr.name}`, `TITLE:${form.title}`, `ORG:${form.company}`, `TEL:${form.phone}`, `EMAIL:${form.email}`, `URL:${form.website}`, `ADR:;;${form.address};;;;`, "END:VCARD"].join("\n");
    const a = document.createElement("a");
    a.href = URL.createObjectURL(new Blob([vcf], { type: "text/vcard" }));
    a.download = `${form.name || "contact"}.vcf`;
    a.click();
  }

  return <div className="scan-page">
    <div className="scan-card">
      <span className="scan-brand"><QrCode size={20}/> QR<span>Flux</span></span>
      {state === "loading" && <div className="scan-body scan-center"><div className="scan-spinner"/><b>Opening your content…</b><small>Short link: /s/{shortId}</small></div>}
      {state === "notfound" && <div className="scan-body scan-center"><CircleHelp size={40} className="scan-err-icon"/><b>Link not found</b><small>This QR code link doesn't exist or is no longer active.</small></div>}
      {state === "error" && <div className="scan-body scan-center"><CircleHelp size={40} className="scan-err-icon"/><b>Something went wrong</b><small>Please try scanning the code again.</small></div>}
      {state === "ready" && qr && <>
        <div className="scan-body">
          <div className="scan-eyebrow">YOU SCANNED A {qr.qr_type.replace("-", " ").toUpperCase()} QR CODE</div>
          <DestinationView qr={qr} onDownload={downloadVcf} />
          {isDirectUrl(qr) && <p className="scan-note">Redirecting you automatically… if nothing happens, tap the button below.</p>}
          <div className="scan-actions">
            {qr.qr_type === "vcard" && <button className="scan-btn" onClick={downloadVcf}><Download size={16}/> Save contact</button>}
            {isDirectUrl(qr) && <a className="scan-btn" href={qr.payload}><Globe size={16}/> Open link</a>}
            {qr.qr_type === "whatsapp" && <a className="scan-btn" href={qr.payload}><MessageCircle size={16}/> Open WhatsApp</a>}
            {qr.qr_type === "email" && <a className="scan-btn" href={qr.payload}><Mail size={16}/> Compose email</a>}
            {qr.qr_type === "sms" && <a className="scan-btn" href={qr.payload}><MessageCircle size={16}/> Open messages</a>}
            {qr.qr_type === "phone" && <a className="scan-btn" href={qr.payload}><Phone size={16}/> Call now</a>}
            {qr.qr_type === "upi" && <a className="scan-btn" href={qr.payload}><Smartphone size={16}/> Pay with UPI</a>}
            {qr.qr_type === "maps" && !isDirectUrl(qr) && <a className="scan-btn" href={`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(qr.payload)}`}><Globe size={16}/> Open in Maps</a>}
            {qr.qr_type === "text" && <span className="scan-btn scan-btn-static"><FileText size={16}/> Text content shown above</span>}
          </div>
        </div>
        <div className="scan-foot">Powered by <Link to="/">QRFlux</Link></div>
      </>}
    </div>
  </div>;
}
