# Firebase production setup

## Collections

The dashboard uses these top-level Firestore collections:

- `admins`, `adminInvites`, `roles`, and `auditLogs`
- `customers`, `providers`, `providerLocations`, and `orders`
- `categories`, `services`, and `banners`
- `wallets`, `transactions`, `payouts`, and `instapayReviews`
- `complaints`, `conversations`, `notifications`, and `promos`
- `settings` and `system`

`admins/{uid}/sessions` stores the browser sessions recorded for each Firebase Auth administrator. The Firebase Auth UID is always the administrator document ID.

## Credentials

Paste the Firebase Web SDK configuration into the `NEXT_PUBLIC_FIREBASE_*` variables in `.env.local`. These values identify the Firebase project and are safe to ship to the browser; Security Rules provide authorization.

`FIREBASE_SERVICE_ACCOUNT_JSON` is private. It is required only for local use of Firebase Admin operations such as creating an administrator and running the seed. The JSON must be stored on one line. Never prefix it with `NEXT_PUBLIC_`.

## Bootstrap

Run `npm run seed` once after creating Authentication, Firestore, and Storage. The seed:

1. creates or updates the first Email/Password Firebase Auth administrator;
2. assigns Firebase custom claims;
3. creates Firestore RBAC roles and the matching active admin document;
4. creates persisted dashboard settings and branding;
5. initializes the atomic provider-ID counter.

## Administrator invitations

Creating an admin uses a Firebase Admin SDK route, creates or updates the Firebase Auth identity, assigns claims, writes `admins`, `adminInvites`, and `auditLogs`, generates a secure password setup/reset link with `generatePasswordResetLink`, and sends the invitation through Resend.

Required email environment:

- `ADMIN_DASHBOARD_URL=https://task-admin-eg.web.app`
- `RESEND_API_KEY`
- `RESEND_FROM_NAME`
- `RESEND_FROM_EMAIL=noreply@jeans-stop.com`
- `RESEND_REPLY_TO_EMAIL` optional

The Resend sending address/domain must be verified. `RESEND_FROM_EMAIL` must be only the email address; put the display name in `RESEND_FROM_NAME`. If Resend is not configured or rejects the message, the route returns an error, writes `emailDeliveryStatus: "Failed"` and `lastEmailError` to `adminInvites/{uid}`, and leaves the invite visible so an administrator can resend it after fixing the provider configuration. Password reset emails use the same Resend configuration and Firebase Auth only generates the secure reset link.

For Firebase Hosting deployments, put these values in a private project-root `.env` file. The Firebase framework deploy copies `.env` into the generated Cloud Run SSR backend on every deploy. Use `npm run deploy`, not raw `firebase deploy`, so `scripts/preflight-production-env.mjs` can block deployments that would remove Resend configuration.

## Gemini AI Operations Executive

Set `GEMINI_API_KEY` only in server/runtime environments. For local development, put it in `.env.local`. For Firebase Hosting with the generated Next.js function, put it in the project-root `.env` used by `firebase deploy`, or configure the equivalent Firebase framework/runtime environment before deployment. Do not prefix the variable with `NEXT_PUBLIC_`.

Optional:

- `GEMINI_MODEL=gemini-3.5-flash`

The dashboard calls `POST /api/firebase/ai`; that route verifies the admin Firebase ID token, reads live Firestore data, sends a compact operational snapshot to Gemini, stores the AI execution/memory/report in Firestore, and writes `ai.gemini_execution_created` to audit logs. The client never receives or imports the Gemini API key.

## Storage paths

- `provider-documents/{providerId}/…`
- `branding/…`
- `services/…`
- `banners/…`
- `complaint-evidence/…`

Files are limited to 20 MB by both client validation and Storage Rules. Access requires an active administrator with the corresponding permission.

## Deployment checklist

1. Set the Firebase project with `npx firebase-tools use --add`.
2. Confirm Email/Password authentication and authorized domains.
3. Run `npm run deploy:rules`.
4. Run `npm run lint` and `npm run build`.
5. Enable framework-aware Hosting with `npx firebase-tools experiments:enable webframeworks`.
6. Run `firebase deploy`.
7. Sign in on the deployed URL and verify a create/edit/delete flow in each permitted module.
