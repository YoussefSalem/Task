# Firebase production wiring checklist

| Module | Status | Persistence |
|---|---|---|
| Admin authentication and sessions | Fully Firebase-backed | Firebase Auth + `admins/{uid}` + session subcollection |
| Customers and customer wallets | Fully Firebase-backed | Firestore transactions and realtime subscriptions |
| Providers, documents, verification, availability | Fully Firebase-backed | Firestore + Firebase Storage |
| Categories, services, pricing, and banners | Fully Firebase-backed | Firestore + image URL/Storage support |
| Orders, assignment, status, timeline, refunds | Fully Firebase-backed | Firestore transactions/batches |
| Offers, order media, chat, calls, and payments | Fully Firebase-backed | Embedded order records loaded from Firestore |
| Support conversations and complaints | Fully Firebase-backed | Firestore + Firebase Storage evidence |
| Transactions, payouts, Instapay review | Fully Firebase-backed | Firestore ledger and transactional balance updates |
| Promotions and notifications | Fully Firebase-backed | Firestore |
| Admin users, roles, invitations, and claims | Fully Firebase-backed | Firebase Admin SDK + Auth + Firestore |
| Account, theme, locale, settings, and branding | Fully Firebase-backed | Admin/settings Firestore documents + Storage |
| Audit logs | Fully Firebase-backed | Append-only Firestore collection |
| AI Operations Executive | Fully Firebase-backed | Server-only Gemini API + Firestore `aiExecutions`, `aiMemories`, `aiReports` plus audited confirmed actions |
| Google Maps and live tracking | Fully Firebase-backed | API key plus Firestore provider locations and order GPS coordinates |

Runtime mock state: **none**. Browser `localStorage`/`sessionStorage`: **none**. Seed data is used only to bootstrap Firebase Auth, roles, settings, verification policy, and the provider counter.
