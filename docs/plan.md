# Invoice Generator — Build Plan

Micro-invoicing and contract portal for freelancers, students and gig workers.
Create a clean invoice or micro-contract in under a minute, share it as a link or PDF,
let the client pay through the freelancer's own payment links (UPI, Stripe/Razorpay, PayPal),
and send polite automated reminders before and after the due date.

This document covers three things:

1. **Tech stack** — what to build with, and why
2. **Sections of the app** — pages, what is on each one, what each button does
3. **Backend design** — data model, API, reminder engine, PDF, payment links, security

Low-fidelity wireframes of every screen are in [`wireframes.html`](./wireframes.html)
(open it in a browser). They show layout and content only; the visual design is yours.

---

## 0. Five decisions that keep this small

**Web only, on every device.** One responsive web app runs in desktop and mobile browsers and
installs to the home screen as a PWA. No native apps, no app-store review, one codebase.

**Local-first.** The invoice editor works without an account. Drafts and generated PDFs are
saved in the browser (IndexedDB), so a student can make and download an invoice in 60 seconds
with zero sign-up. An account is only needed for share links and automatic reminders.

**We never touch money.** The app does not process payments. The freelancer saves their UPI ID,
Stripe/Razorpay payment link and/or PayPal.me handle once; the public invoice page shows those
as pay buttons. No PCI scope, no KYC, no fees, nothing to get banned for. "Mark as paid" is
manual in v1; a Stripe/Razorpay webhook can automate it later.

**WhatsApp v1 = deep links, not the Business API.** `https://wa.me/<number>?text=<message>`
opens WhatsApp with the message pre-filled and the freelancer taps Send. Free, no Meta business
verification. Truly automatic reminders go by email; for WhatsApp the system emails the
freelancer a one-tap "remind Rahul now" link on the scheduled day. Upgrade to the WhatsApp
Cloud API later if users ask for it.

**One PDF template, rendered in two places.** `@react-pdf/renderer` runs in the browser
(instant download, works offline) and in a Next.js route handler (the "Download PDF" button on
the public link). Same component, so the two never drift apart.

---

## 1. Tech stack

### Recommended: one codebase, one deploy, ₹0/month to start

| Layer | Pick | Why this one |
|---|---|---|
| App framework | **Next.js 16 (App Router) + TypeScript** | UI, API routes, public invoice pages and the cron endpoint in a single project. Server components give the public link fast loads and a proper preview card when the link is pasted into WhatsApp. |
| Styling / components | **Tailwind CSS + shadcn/ui** | Forms, tables, dialogs and dropdowns done in hours. Components are copied into your repo, so you can restyle everything to your own design. |
| Forms + validation | **react-hook-form + zod** | One zod schema validates the form in the browser and the same payload on the server. |
| Local device storage | **Dexie.js (IndexedDB)** | Drafts, offline copies of invoices and the generated PDF blobs. Survives refresh; works with no account. |
| PDF | **@react-pdf/renderer** (+ `file-saver`) | React components → PDF, in the browser and in Node. |
| QR codes | **qrcode** | UPI QR on the public page and inside the PDF. |
| Database, auth, files | **Supabase** (Postgres + Auth + Storage) | Generous free tier. Magic-link login (no passwords to manage). Row Level Security isolates each freelancer's data at the database. Logo uploads go to Storage. |
| Email | **Resend + react-email** | Free tier: 3,000 emails/month with a hard cap of 100/day, so reminders that overflow a day roll to the next run. Templates written in React. Also use it as Supabase's SMTP so magic links are not rate-limited. |
| WhatsApp | **wa.me deep links** now; WhatsApp Cloud API later | Zero cost and zero approval for v1. |
| Payments | **Stripe / Razorpay Payment Links, PayPal.me, UPI deep link + QR** | Links only. A provider-agnostic "custom link" field means anything with a URL works. |
| Scheduler | **Vercel Cron → `GET /api/cron/reminders`** | Hobby allows 2 cron jobs per project, each at most once a day, fired at some point inside the scheduled hour. Daily is all due-date reminders need. |
| Hosting | **Vercel (Hobby)** | Free, zero-config for Next.js, preview deploy per branch. Hobby is for personal, non-commercial use only: the moment you charge for the product, move to Pro ($20/month) or to Cloudflare (free plan allows commercial use; Next.js runs there through the OpenNext adapter, cron through Cron Triggers). |
| Rate limiting (public pages) | **@upstash/ratelimit** (optional) | Free Redis tier; protects `/i/[token]` and the PDF endpoint from scraping. |
| Tests | **Vitest** (totals, reminder dates, link builders) + **Playwright** (create invoice → download PDF) | Keep it light; test the money math and the date math hardest. |

Cost at launch: $0 while the product itself is free to use (Vercel Hobby forbids commercial use, see the
Hosting row). Add a custom domain (about $10/year) when you want `yourbrand.com/i/…` links. The first
paid step if you monetise is Vercel Pro at $20/month; everything else stays on free tiers for a long time.

### If you would rather keep frontend and backend separate

The sections and backend design below do not change; only the plumbing does.

| Layer | Pick |
|---|---|
| Frontend | Vite + React + TypeScript, Tailwind, React Router, same Dexie / react-pdf libraries |
| Backend | Node + **Hono** (or Express) + TypeScript with **Drizzle ORM**, on Render / Railway / Fly free tier. Or **FastAPI** if you prefer Python (PDF via WeasyPrint instead of react-pdf). |
| Database | Postgres on Supabase or Neon (free). MongoDB works too, but invoices → items → clients → reminders is relational data and Postgres makes totals and reports simpler. |
| Auth | Supabase Auth or Clerk (free up to 10k users) |
| Cron | cron-job.org (free) hitting your `/cron/reminders` endpoint, or `node-cron` inside a long-running server |

Trade-off: two deploys, CORS, and the public invoice page becomes a client-rendered route, so
WhatsApp link previews need a small server-rendered `/i/[token]` route of their own.

### Zero-backend weekend version

Phase 1 in section 4 needs no server at all: editor → totals → PDF → IndexedDB → "Share on
WhatsApp" with the text pre-filled and the PDF attached by hand. Ship that first, get feedback,
then add Supabase for links and reminders.

---

## 2. Sections of the app

Route map:

```
/                      Landing
/login                 Magic-link login
/i/[token]             Public invoice (what the client opens)
/c/[token]             Public contract (client reads and accepts)
/app                   Dashboard              ┐
/app/invoices          Invoices list          │
/app/invoices/new      Invoice editor         │  signed-in shell:
/app/invoices/[id]     Invoice editor (edit)  │  sidebar on desktop,
/app/contracts         Contracts              │  bottom tabs on mobile
/app/clients           Clients                │  (Home · Invoices · Clients · More)
/app/reminders         Reminders              │
/app/settings          Settings               ┘
```

### 2.1 Landing `/`
- Hero: one-line promise, primary button **Create an invoice** (opens the editor directly, no
  sign-up), secondary **See a sample invoice** (opens a demo `/i/demo`).
- "How it works" in 3 steps: Fill → Share link/PDF → Get paid and auto-remind.
- Feature grid: PDF in one click · Pay by UPI/card/PayPal · Polite reminders · Micro-contracts ·
  Works offline · Free.
- FAQ (Is it free? Do you take a cut? Where is my data stored?) and footer.

### 2.2 Public invoice `/i/[token]` — the most important screen
Opened from WhatsApp on a phone, so mobile first, no login, fast.
- Header: freelancer logo/name, invoice number, **status pill** (Due in 3 days / Due today /
  Overdue by 4 days / Paid ✓).
- **Amount due** large, with due date and issue date under it. "Billed to" client block.
- Line items table → subtotal, discount, tax, **total**.
- **Pay** card, showing only the methods the freelancer enabled:
  - *Pay with UPI* button (opens the UPI app chooser on phones) + QR code (desktop) + UPI ID as
    copyable text (fallback).
  - *Pay by card* (Stripe or Razorpay payment link), *PayPal*, *Custom link*.
  - "Paid already? Message {freelancer}" → wa.me link.
- Actions: **Download PDF**, **WhatsApp {freelancer}**.
- Notes and terms. Footer "Made with Invoice Generator" (free growth loop).
- Invisible: on load, `POST /api/public/invoices/[token]/view` → invoice becomes *Viewed*.
- Open Graph meta tags so WhatsApp shows a preview card: "INV-0012 · ₹5,000 · Due 3 Oct".

### 2.3 Public contract `/c/[token]`
- Title, parties (freelancer ↔ client), project summary.
- Scope, deliverables (checklist), price and payment terms, timeline, revisions, cancellation.
- **Accept** card: type full name → tick "I have read and agree" → **Accept contract**.
- After acceptance: confirmation with timestamp, "Download PDF", and the invoice link once one exists.
- Declined or expired: neutral message with the freelancer's WhatsApp link.

### 2.4 Login `/login`
- Email field → **Send magic link** → "Check your inbox" state. No passwords.
- If the visitor already has local drafts: "Your 3 local invoices will be synced to your account."

### 2.5 Dashboard `/app`
- Three stat tiles: **Outstanding**, **Overdue**, **Paid this month** (tap → filtered invoices list).
- **Needs attention** list: overdue and due-this-week invoices, each with one-tap *Remind on
  WhatsApp*, *Email reminder*, *Mark paid*.
- **Recent activity** feed: "Rahul viewed INV-0012 · 2h ago", "Reminder emailed for INV-0009",
  "INV-0007 marked paid".
- Persistent **New invoice** button.

### 2.6 Invoices list `/app/invoices`
- Filter tabs: All · Draft · Sent · Viewed · Overdue · Paid. Search by client or number.
- Row: number · client · amount · due date · status pill · ⋯ menu (Copy link, Send on WhatsApp,
  Send email, Download PDF, Mark paid, Duplicate, Delete).
- Empty state with a "Create your first invoice" button.

### 2.7 Invoice editor `/app/invoices/new` and `/app/invoices/[id]`
Two panes on desktop (form left, live preview right); stacked on mobile with a Preview toggle.

Form:
- **Client**: search existing or *Add new* inline (name, email, WhatsApp number, company).
- **Invoice number** (auto, editable), **Issue date**, **Due date** with quick chips *7 · 14 · 30 days*.
- **Line items**: description, qty, rate, amount; add / remove / reorder rows.
- **Discount** (amount or %), **Tax %** (GST label optional), live totals.
- **Notes** (visible to client) and **Terms** (late fee, bank details). Defaults come from Settings.
- **Payment methods**: toggles for the methods configured in Settings.
- **Reminders**: on/off + schedule preset (default: 3 days before · due day · 3 days after ·
  7 days after) + tone (Friendly / Neutral / Firm).

Action bar: **Save draft** · **Download PDF** · **Copy link** · **Send ▾** (WhatsApp / Email /
Both) · **Mark paid**. Sending assigns the invoice number if it is still a draft, sets status
*Sent*, and creates the reminder rows.

### 2.8 Contracts `/app/contracts`
- List with status pills (Draft · Sent · Accepted · Declined).
- New contract: pick a **template** (Design gig, Content writing, Tutoring, Development project,
  Custom) → fill fields (client, scope, deliverables, price, dates, revisions, payment terms,
  cancellation) → preview → **Send link** (WhatsApp / Email) or **Download PDF**.
- Accepted contract shows who accepted and when, plus **Create invoice from this contract**
  (pre-fills client, amount, description).

### 2.9 Clients `/app/clients`
- List with total billed and outstanding per client.
- Add/edit drawer: name, email, WhatsApp number (with country code), company, address, notes.
- Client detail: their invoices and contracts, quick actions.

### 2.10 Reminders `/app/reminders`
- **Upcoming**: date · client · invoice · channel · tone → *Send now* / *Skip* / *Reschedule*.
- **Sent log**: what went out, when, through which channel, delivered or failed.
- **Templates**: three tones with placeholders `{client_name} {invoice_number} {amount}
  {due_date} {link} {freelancer_name}`; live preview; reset to default.

### 2.11 Settings `/app/settings` (tabs)
- **Business**: name, logo upload, address, tax ID (GSTIN / VAT, optional), WhatsApp number.
- **Payments**: UPI ID · Stripe/Razorpay payment link · PayPal.me handle · custom link, each with
  an enable toggle and a "Test link" button.
- **Invoice defaults**: currency, number prefix and next number, default tax %, default due days,
  default notes and terms.
- **Reminders**: default schedule, default tone, channels, daily send time.
- **Data**: Export everything as JSON · Import · Delete account.

---

## 3. Backend design

### 3.1 Data model (Postgres on Supabase)

Money is stored as **integers in minor units** (paise / cents) to avoid floating-point errors.
`overdue` is **derived** (`status in ('sent','viewed') and due_date < today`), not stored, so no
nightly job is needed to flip statuses.

```
profiles        id uuid PK (= auth.users.id), email, name, business_name, logo_url,
                address, tax_id, phone_e164,
                currency text default 'INR', invoice_prefix text default 'INV-',
                next_invoice_number int default 1,
                default_tax_rate numeric(5,2), default_due_days int default 14,
                default_notes text, default_terms text,
                upi_id, upi_payee_name, upi_enabled bool,
                card_link, card_link_label, card_enabled bool,        -- Stripe / Razorpay
                paypal_handle, paypal_enabled bool,
                custom_link, custom_link_label, custom_enabled bool,
                reminder_preset jsonb default
                  '{"offsets":[-3,0,3,7],"tone":"auto","channels":["email","whatsapp"]}',
                created_at

clients         id uuid PK, user_id → profiles, name, email, phone_e164, company, address,
                notes, created_at

invoices        id uuid PK, user_id → profiles, client_id → clients,
                number text,                       -- null while draft; unique per user once set
                status text check in ('draft','sent','viewed','paid','cancelled'),
                issue_date date, due_date date, currency text,
                subtotal_minor bigint, discount_minor bigint, tax_rate numeric(5,2),
                tax_minor bigint, total_minor bigint,
                notes text, terms text,
                payment_methods text[],            -- e.g. {upi,card}
                public_token text unique,          -- nanoid(22)
                contract_id → contracts null,
                reminders_enabled bool, reminder_tone text,
                sent_at, first_viewed_at, paid_at, paid_via text, paid_note text,
                created_at, updated_at

invoice_items   id uuid PK, invoice_id → invoices (on delete cascade), description text,
                quantity numeric(10,2), unit_price_minor bigint, amount_minor bigint,
                sort_order int

contracts       id uuid PK, user_id, client_id, title, template_key,
                scope text, deliverables jsonb, price_minor bigint, currency,
                start_date, end_date, revisions int, payment_terms text,
                cancellation_terms text, body_md text,   -- rendered contract text
                status check in ('draft','sent','accepted','declined','expired'),
                public_token text unique,
                sent_at, accepted_at, accepted_name, accepted_ip, accepted_user_agent,
                created_at

reminders       id uuid PK, invoice_id → invoices (on delete cascade),
                offset_days int,                   -- -3, 0, 3, 7, 14
                scheduled_for date,
                channel check in ('email','whatsapp'), tone text,
                status check in ('pending','sending','sent','skipped','failed'),
                sent_at, error text, message_snapshot text

events          id bigserial PK, user_id, invoice_id null, contract_id null,
                type text,   -- invoice_created, invoice_sent, invoice_viewed, reminder_sent,
                             -- reminder_nudged, invoice_paid, contract_sent,
                             -- contract_viewed, contract_accepted
                meta jsonb, created_at
```

Indexes: `invoices(user_id, status)`, `invoices(public_token)`,
`reminders(status, scheduled_for)`, `events(user_id, created_at desc)`, `contracts(public_token)`.

**Row Level Security** on every table: `user_id = auth.uid()`. Public pages read by token
through a server-side client using the service-role key, which never reaches the browser.

### 3.2 API (Next.js route handlers under `app/api/`)

Auth: Supabase session cookie via `@supabase/ssr`. Every `/api/*` route except `public/*`,
`cron/*` and `webhooks/*` rejects unauthenticated calls.

```
Invoices
  GET    /api/invoices?status=&q=&client=     list (overdue computed in SQL)
  POST   /api/invoices                         create draft (server recomputes totals)
  GET    /api/invoices/:id
  PATCH  /api/invoices/:id                     drafts fully editable; sent: notes / due date only
  DELETE /api/invoices/:id                     drafts only; sent → status cancelled instead
  POST   /api/invoices/:id/send                { channels: ['whatsapp'|'email'] }
                                               assign number, status sent, create reminders,
                                               email the client if requested,
                                               return { url, whatsappUrl }
  POST   /api/invoices/:id/mark-paid           { paid_via, paid_at?, note? } → skip pending reminders
  POST   /api/invoices/:id/duplicate
  GET    /api/invoices/:id/pdf                 server-rendered PDF (owner)

Public (no auth, rate limited)
  page   /i/:token                             server component + OG metadata
  POST   /api/public/invoices/:token/view      first_viewed_at, status viewed, event
  GET    /api/public/invoices/:token/pdf
  page   /c/:token
  POST   /api/public/contracts/:token/view
  POST   /api/public/contracts/:token/accept   { name } → accepted, record ip/ua/time, email both
  GET    /api/public/contracts/:token/pdf

Contracts   GET/POST /api/contracts · GET/PATCH/DELETE /api/contracts/:id
            POST /api/contracts/:id/send · POST /api/contracts/:id/create-invoice
Clients     GET/POST /api/clients · GET/PATCH/DELETE /api/clients/:id
Reminders   GET /api/reminders?status= · PATCH /api/reminders/:id (skip / reschedule)
            POST /api/reminders/:id/send-now
Profile     GET/PATCH /api/profile · POST /api/profile/logo · GET /api/export
Cron        GET /api/cron/reminders            Authorization: Bearer $CRON_SECRET
Webhooks    POST /api/webhooks/stripe          (later) mark paid automatically
```

Rules enforced on the server, never only in the UI:
- Totals are recomputed from the items on every write; numbers sent by the client are ignored.
- Invoice numbers come from one atomic statement:
  `update profiles set next_invoice_number = next_invoice_number + 1 where id = $1
   returning next_invoice_number - 1`.
- Public tokens: `nanoid(22)` (about 130 bits). Never reused; "Regenerate link" is explicit.

### 3.3 Invoice lifecycle

```
draft ──send──▶ sent ──client opens link──▶ viewed ──mark paid / webhook──▶ paid
  │              │                            │
  └─ delete      └──────────── cancel ────────┴──▶ cancelled

overdue = (sent or viewed) and due_date < today      derived, shown as a pill
```

### 3.4 Reminder engine

**On send** (if reminders are enabled): for each offset in the preset and each enabled channel,
insert a reminder row with `scheduled_for = due_date + offset_days`. Offsets already in the
past are skipped. Tone `auto` escalates: before due → Friendly, on due day → Neutral, after
due → Firm. The user can pin a tone per invoice.

**Daily cron.** `vercel.json`:

```json
{ "crons": [{ "path": "/api/cron/reminders", "schedule": "30 3 * * *" }] }
```

(03:30 UTC = 09:00 IST. On the Hobby plan Vercel fires it somewhere inside that hour, so treat it as
"morning", not an exact minute.) The handler:

1. Claims rows atomically so a double run can never double-send:
   ```sql
   update reminders r set status = 'sending'
   from invoices i
   where r.invoice_id = i.id and r.status = 'pending' and r.scheduled_for <= current_date
     and i.status in ('sent','viewed')
   returning r.*, i.*;
   ```
2. Renders the message from the tone template and placeholders.
3. `channel = email` → Resend to the client → `status = sent`, event `reminder_sent`.
4. `channel = whatsapp` → email (and in-app notification) to the **freelancer**: "Tap to remind
   Rahul about INV-0012" with the `wa.me` link pre-filled → `status = sent`, event
   `reminder_nudged`. The Dashboard keeps showing the one-tap link until the invoice is paid.
5. Failures → `status = failed`, `error` stored, picked up again on the next run.

**Mark paid** → all pending reminders for that invoice → `skipped`; optional "payment received,
thank you" email to the client.

Default templates:

```
Friendly (before due)
Hi {client_name}! Quick heads-up that invoice {invoice_number} for {amount} is due on
{due_date}. You can view and pay it here: {link}. Thanks so much! – {freelancer_name}

Neutral (due day)
Hi {client_name}, invoice {invoice_number} for {amount} is due today. Here is the link to
view and pay: {link}. Thank you! – {freelancer_name}

Firm (after due)
Hi {client_name}, invoice {invoice_number} for {amount} was due on {due_date} and is still
outstanding. Please complete the payment here: {link}, or let me know if there is an issue.
Thanks – {freelancer_name}
```

WhatsApp link builder (number in E.164 without the `+`):

```ts
export const waLink = (phoneE164: string, message: string) =>
  `https://wa.me/${phoneE164.replace(/\D/g, "")}?text=${encodeURIComponent(message)}`;
```

### 3.5 PDF

- `components/invoice/InvoicePdf.tsx` — one `@react-pdf/renderer` document: logo and parties,
  items table, totals, pay section (UPI QR + IDs and links), notes and terms.
- Browser: `pdf(<InvoicePdf …/>).toBlob()` → `saveAs()`, and store the blob in Dexie so
  "Download again" works offline.
- Server: `renderToBuffer(<InvoicePdf …/>)` in `/api/.../pdf` → `Content-Type: application/pdf`,
  `Content-Disposition: attachment; filename="INV-0012.pdf"`.
- QR: `qrcode.toDataURL(upiString)` → `<Image src=…/>` inside the PDF.

### 3.6 Payment links

| Method | Link | Notes |
|---|---|---|
| UPI | `upi://pay?pa={upi_id}&pn={payee}&am={amount}&cu=INR&tn={invoice_number}` | Opens the UPI app chooser on phones; render the same string as a QR for desktop. GPay/PhonePe often **decline intent links from personal (non-merchant) UPI IDs**, so always show the QR and the UPI ID as copyable text. Freelancers with a merchant VPA (Paytm for Business, Razorpay) get full support. |
| Card | Stripe or Razorpay Payment Link pasted from their dashboard | Stripe has been invite-only for new Indian businesses since May 2024 and still is, so label the button "Pay by card" and let the user paste a Razorpay (or Stripe, if they have it) link. Later: create links via API with `client_reference_id = invoice.id` so a webhook can mark paid automatically. |
| PayPal | `https://paypal.me/{handle}/{amount}{CUR}` | e.g. `…/priya/50USD`. |
| Custom | any URL | Wise, a bank-details page, anything. |

Amounts are formatted with `Intl.NumberFormat(locale, { style: "currency", currency })`.
INR is the default; any ISO 4217 code works.

### 3.7 Local device storage (Dexie)

```
drafts          id, payload (invoice JSON), updatedAt
invoices_cache  id, payload, updatedAt          -- read-only mirror for offline viewing
pdfs            invoiceId, blob, createdAt
settings        key, value                      -- pre-login business details, UPI ID, defaults
```

Sync rule (keep it simple): when signed in, the server is the source of truth. Local drafts are
pushed on save; on first login, existing local invoices are imported once. No two-way merge.

### 3.8 Security and privacy

- RLS on every table; the service-role key exists only in server code.
- Token entropy ≥ 128 bits; public endpoints rate-limited per IP (for example 60 requests/min).
- `CRON_SECRET` bearer check on the cron route; Stripe/Razorpay webhook signature check later.
- zod validation on every API body; money and dates recomputed server-side.
- No client payment credentials are ever stored, only the freelancer's public payment handles.
- Contract acceptance records name, timestamp, IP and user agent, and emails a copy to both parties.
- Export (JSON) and delete-account are each one click.
- Supabase free projects pause after 7 days without database activity; the daily cron's queries count
  as activity and keep it awake.

### 3.9 Environment variables

```
NEXT_PUBLIC_APP_URL=https://yourapp.vercel.app
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=          # server only
RESEND_API_KEY=
EMAIL_FROM="Invoices <invoices@yourdomain.com>"
CRON_SECRET=                        # long random string; Vercel sends it as a Bearer token
UPSTASH_REDIS_REST_URL=             # optional, rate limiting
UPSTASH_REDIS_REST_TOKEN=
STRIPE_WEBHOOK_SECRET=              # later
```

### 3.10 Suggested folder layout

```
app/
  page.tsx                         landing
  login/page.tsx
  i/[token]/page.tsx               public invoice (+ opengraph-image.tsx)
  c/[token]/page.tsx               public contract
  app/layout.tsx                   signed-in shell (sidebar / bottom tabs)
  app/page.tsx                     dashboard
  app/invoices/…  app/contracts/…  app/clients/…  app/reminders/…  app/settings/…
  api/…                            routes listed in 3.2
components/
  invoice/   InvoiceForm.tsx  LineItems.tsx  InvoicePreview.tsx  InvoicePdf.tsx  PayButtons.tsx
  contract/  ContractForm.tsx  ContractView.tsx
  ui/        shadcn components
lib/
  supabase/  client.ts  server.ts  admin.ts
  db/        invoices.ts  clients.ts  contracts.ts  reminders.ts  events.ts
  money.ts  dates.ts  tokens.ts  whatsapp.ts  upi.ts  paypal.ts
  reminders/ schedule.ts  templates.ts  send.ts
  pdf/       render.ts
  local/     dexie.ts
  validation/ invoice.ts  contract.ts  client.ts  profile.ts
emails/      InvoiceSent.tsx  Reminder.tsx  Nudge.tsx  PaidReceipt.tsx  ContractAccepted.tsx
supabase/    migrations/*.sql  (tables, indexes, RLS policies)
vercel.json
```

---

## 4. Build order

**Phase 1 — Invoice + PDF, no backend (week 1)**
- [ ] Scaffold Next.js + Tailwind + shadcn; app shell with sidebar / bottom tabs
- [ ] zod schemas for invoice, items, client, profile
- [ ] Invoice editor: line items, discount, tax, live totals, live preview
- [ ] PDF download with `@react-pdf/renderer`
- [ ] Dexie: save drafts, invoices and PDFs; invoices list from local data
- [ ] Settings stored locally (business details, UPI ID, defaults)
- [ ] "Share on WhatsApp" → wa.me link with the message text

**Phase 2 — Accounts, share links, payments (week 2)**
- [ ] Supabase project, migrations, RLS, magic-link auth (Resend as SMTP)
- [ ] Save to DB; import local invoices on first login
- [ ] Public invoice page: pay buttons, UPI QR, PDF, view beacon, OG preview card
- [ ] Mark as paid; Clients CRUD; Dashboard tiles

**Phase 3 — Reminders (week 3)**
- [ ] Reminder rows on send; Reminders page (upcoming, sent, templates)
- [ ] Email templates with react-email; daily cron; WhatsApp nudge email
- [ ] Dashboard "Needs attention" with one-tap remind

**Phase 4 — Contracts (week 4)**
- [ ] Templates, editor, preview, public accept page with name / timestamp / IP record
- [ ] Contract → invoice; accepted-contract emails

**Phase 5 — Polish**
- [ ] Landing page, FAQ, sample invoice
- [ ] PWA manifest + offline editor; export / import JSON
- [ ] Stripe / Razorpay webhook → auto mark paid
- [ ] Optional: WhatsApp Cloud API for fully automatic WhatsApp reminders; recurring invoices;
      partial payments; multi-currency per client

## 5. Deliberately not in v1

Teams and multiple users per business, expense tracking, GST e-invoicing / IRN, time tracking,
in-app payment processing, client accounts or logins, native mobile apps (the PWA covers it).

## 6. Facts checked on 22 Sep 2026

- Next.js current line is 16.3 (Aug 2026); 15.x is maintenance LTS. https://nextjs.org/blog/next-16-3
- Vercel Hobby cron: 2 jobs per project, daily only, fired within the scheduled hour.
  https://vercel.com/docs/cron-jobs/usage-and-pricing
- Vercel Hobby is for personal, non-commercial use. https://vercel.com/docs/limits/fair-use-guidelines
- Resend free tier: 3,000 emails/month and 100/day.
  https://resend.com/docs/knowledge-base/account-quotas-and-limits
- Supabase Free projects pause after 7 days of database inactivity; limits: 2 projects, 500 MB DB,
  1 GB storage, 50k MAU. https://supabase.com/docs/guides/platform/free-project-pausing
- Stripe accounts are invite-only in India for new businesses.
  https://support.stripe.com/questions/stripe-accounts-are-invite-only-in-india
