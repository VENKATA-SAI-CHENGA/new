# QRFlux

A React + TypeScript + Vite QR-code platform starter with a polished responsive interface, eleven QR payload formats, PNG/SVG export, Supabase Auth, saved QR library, and a database migration with RLS policies.

## Run locally

1. Install Node.js 20+.
2. Extract this project and open the folder in a terminal.
3. Install dependencies: `npm install`
4. Copy `.env.example` to `.env`.
5. Add your Supabase project URL and publishable/anon key to `.env`.
6. Run the SQL in `supabase/migrations/001_qrflux.sql` in Supabase SQL Editor.
7. In Supabase Authentication, enable email/password sign-in and configure your site URL and redirect URLs.
8. Start: `npm run dev`
9. Production build: `npm run build`

## Supabase configuration

Use only the Supabase project URL and publishable/anon key in the browser. Never place a service-role key in `.env` or frontend code. The migration creates profiles, qr_codes, qr_scans, and user_settings with RLS enabled.

The auth trigger creates a profile record on signup. The app's signup flow also upserts the profile as a safe convenience.

## Implemented in this starter

- Responsive marketing homepage and workspace shell.
- Email/password registration, login, session persistence, and password reset email.
- Exactly eleven QR types: URL, Multi-URL, Digital Visiting Card, Email, WhatsApp, SMS, Phone, Wi-Fi, UPI Payments, Google Maps, and Simple Text.
- Input validation and QR payload generation.
- Live QR preview, foreground/background colors, size and error correction controls.
- PNG and SVG downloads.
- Save, list, search, filter, and delete saved QR codes.
- Supabase migration and ownership RLS policies.

## Important scope notes before production

- Multi-URL currently encodes a readable list of links into a static QR payload. A hosted multi-link landing page requires a deployed public page and a controlled publishing endpoint.
- Dynamic URL, Multi-URL, and vCard redirects are not enabled yet. The migration deliberately does not expose private QR records publicly. Implement a dedicated Edge Function or narrowly scoped RPC that resolves only published dynamic records before enabling public redirects.
- Analytics scan tracking is not yet wired to a public scan endpoint; avoid collecting scanner identifiers or unnecessary personal data.
- Profile image upload/storage, password update UI, advanced logo/corner/dot styling, pagination, and automated end-to-end tests remain production follow-ups.
- Test all payload types on real Android and iOS devices before printing or relying on them. UPI intent support varies by payment app.
- For best security, review the SQL policies in a staging project and configure Supabase email templates, rate limits, backups, and allowed redirect URLs.

## Project structure

- `src/App.tsx` — routes, public pages, auth, workspace, QR generation and management.
- `src/supabase.ts` — Supabase client.
- `src/styles.css` — responsive visual system.
- `supabase/migrations/` — database schema and RLS policies.
