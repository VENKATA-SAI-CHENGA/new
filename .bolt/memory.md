# Project memory

## Product intent & audience

- QR code generator and management web app built with Vite + React.
- Supports both static and dynamic QR codes across multiple types: URL, email, WhatsApp, SMS, phone, and UPI.
- Dynamic codes track scans and redirect to real destinations; static codes encode data directly.
- Includes Analytics dashboard and per-code "Scans" tab for scan tracking.
- UPI support suggests Indian market relevance / payment QR use cases.

## Brand personality & voice

- Explanatory and helpful; walks users through testing steps and edge cases.
- Transparent about platform limitations (e.g., Bolt preview sign-in vs. published site).

## Visual design & UX direction

- Links input: multi-line textarea accepting one URL per line or comma-separated values.
- Per-code detail view uses tabs, including a "Scans" tab.
- Settings page includes a "Public site address for dynamic QR codes" field.
- Publish workflow exists to deploy the app to a public URL.
- App is mobile-aware since end-users interact via phone camera scanning.

## Decisions, constraints & rationale

- Dynamic QR codes require a configured public site address to function correctly for external scanners; Bolt preview URLs show a sign-in wall to non-authenticated users.
- Users must Publish and set the public address in Settings before generating dynamic codes for real-world use.
- Dynamic codes differentiate behavior by type: URL redirects, email/WhatsApp/SMS/phone/UPI open the native app instead of a web page.
- All dynamic code scans are recorded for analytics.

## Open questions & assumptions

- Assumption: backend or service layer exists for scan tracking and dynamic redirect resolution (not yet visible in context).
- Assumption: QR rendering and scanning rely on a client-side library or external service.
- Unknown: persistence model for codes (local storage vs. backend database).
- Unknown: authentication model for the app itself (Bolt preview sign-in is separate from app auth).