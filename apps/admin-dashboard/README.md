# Task Admin

Production Firebase control center for the Task home-services marketplace. The application uses Next.js App Router, TypeScript, Firebase Authentication, Cloud Firestore realtime subscriptions, Firebase Storage, Tailwind CSS, shadcn/ui, Lucide, and Recharts.

All marketplace records are loaded from Firestore. Customer, provider, order, service, category, banner, wallet, payment, complaint, notification, and support-conversation mutations write directly to Firestore and are protected by role-based Security Rules. Firebase Auth manages administrator identities and Firebase Storage holds private provider documents and uploaded brand assets.

## Firebase project setup

1. Create a Firebase project and add a Web app.
2. In **Authentication → Sign-in method**, enable **Email/Password**.
3. Create a Firestore database and a Storage bucket.
4. Copy `.env.example` to `.env.local` and paste the six Web SDK values shown in **Project settings → General → Your apps**.
5. For local server routes and seeding, generate a service-account key in **Project settings → Service accounts**. Paste the complete JSON on one line into `FIREBASE_SERVICE_ACCOUNT_JSON`.
6. Set a strong first-admin email and password in `FIREBASE_SEED_ADMIN_EMAIL` and `FIREBASE_SEED_ADMIN_PASSWORD`.
7. For dashboard invitations and password reset emails, set `ADMIN_DASHBOARD_URL`, `RESEND_API_KEY`, `RESEND_FROM_NAME`, `RESEND_FROM_EMAIL`, and optionally `RESEND_REPLY_TO_EMAIL`. `RESEND_FROM_EMAIL` must be a plain verified address such as `noreply@jeans-stop.com`.
8. For the AI Operations Executive, set `GEMINI_API_KEY` server-side only. Optionally set `GEMINI_MODEL=gemini-3.5-flash`.

Never commit `.env`, `.env.local`, or a service-account key.

## Run locally

```bash
npm install
npm run seed
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) and sign in with the seeded administrator. `npm run seed` is idempotent: it creates or updates the first Firebase Auth administrator, RBAC roles, dashboard settings, and the permanent provider-ID counter. Marketplace collections remain empty until records are created through the dashboard.

## Security Rules

`firestore.rules` and `storage.rules` deny access by default. Access requires an active document at `admins/{firebaseAuthUid}` and the required permission. Audit logs are append-only. Provider IDs are allocated by a Firestore transaction and are never recycled.

Deploy rules independently with:

```bash
npx firebase-tools use --add
npm run deploy:rules
```

## Firebase Hosting deployment

This repository uses Firebase's framework-aware Hosting configuration for the Next.js App Router. Use Node.js 22, select your project once, enable web-framework support in the CLI, and deploy through `npm run deploy` so the production environment preflight runs first:

```bash
npm install
npm run lint
npm run build
npx firebase-tools login
npx firebase-tools use --add
npx firebase-tools experiments:enable webframeworks
npm run deploy
```

Copy `.firebaserc.example` to `.firebaserc` if you prefer to set the project ID manually. In Firebase-managed server runtimes, the Admin SDK uses Application Default Credentials, so do not deploy a service-account JSON secret unless your environment explicitly requires one.

For production invitations and password resets on Firebase Hosting, create a private project-root `.env` before deploying. Firebase framework deploys load this file into the Cloud Run SSR backend on every deploy:

```bash
ADMIN_DASHBOARD_URL=https://task-admin-eg.web.app
RESEND_API_KEY=your-resend-api-key
RESEND_FROM_NAME=Task Admin
RESEND_FROM_EMAIL=noreply@jeans-stop.com
RESEND_REPLY_TO_EMAIL=
```

Inviting or resending an administrator creates a Firebase Auth password-reset setup link with the Admin SDK and sends it through Resend. Reset password uses the same Resend sender. If Resend is missing or rejects the email, the dashboard shows the real failure and stores it on `adminInvites/{uid}` for invitations.

`npm run deploy` runs `scripts/preflight-production-env.mjs` first and blocks deployment if the Resend variables are missing. This prevents a fresh Firebase deploy from silently removing the email runtime configuration.

## Gemini AI

The AI Operations Executive runs through the authenticated server route `POST /api/firebase/ai`. The browser sends only the admin prompt and page context; the server verifies the Firebase Auth admin token, reads live Firestore collections, calls Gemini with `GEMINI_API_KEY`, stores the execution in `aiExecutions`, updates AI memory/reports, and writes an audit log.

Local setup: add `GEMINI_API_KEY=...` to `.env.local` for `npm run dev`. Do not use a `NEXT_PUBLIC_` prefix.

Firebase deployment setup: add the same server-only value to the Firebase framework/runtime environment, typically a project-root `.env` used by `firebase deploy`:

```bash
GEMINI_API_KEY=your-gemini-key
GEMINI_MODEL=gemini-3.5-flash
```

The Settings → Integrations page checks Gemini readiness through a secure server route and never returns the key.

## Optional Google Maps

Enable Maps JavaScript API in Google Cloud, restrict the key to your production domains, and set `NEXT_PUBLIC_GOOGLE_MAPS_API_KEY`. Without it, the operations screen shows a clear configuration error instead of loading an invalid map.

Additional implementation details are in [docs/firebase-production-setup.md](docs/firebase-production-setup.md).
