# Firebase data access

The dashboard uses the modular Firebase Web SDK for authenticated realtime reads, Firestore transactions, and Storage uploads. `lib/firebase/repository.ts` is the single marketplace data layer. There is no generic REST mutation route or browser-local repository.

## Trusted server route

| Method | Route | Purpose |
|---|---|---|
| `POST` | `/api/firebase/admin-users` | Create, edit, enable, disable, revoke, and resend Firebase Auth administrator invitations; synchronizes Firestore roles/claims and sends Resend invitation email |
| `POST` | `/api/firebase/ai` | Authenticates the admin, reads live Firestore data, calls Gemini server-side with `GEMINI_API_KEY`, stores `aiExecutions`/memory/reports, and audits the run |
| `GET` | `/api/firebase/integration-status` | Returns configured/missing status for server integrations such as Resend and Gemini without exposing secrets |

Trusted routes require a Firebase ID token in `Authorization: Bearer …`. Marketplace CRUD is authorized by `firestore.rules`; private file access is authorized by `storage.rules`.

## Realtime collections

The admin subscribes only to collections allowed by its Firestore role: AI executions, AI memories, AI reports, customers, providers, orders, categories, services, banners, conversations, wallets, transactions, complaints, administrators, invitations, roles, promotions, notifications, payouts, audit logs, provider locations, Instapay reviews, and verification requirements.
