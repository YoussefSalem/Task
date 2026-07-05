# Firestore schema

| Collection | Purpose |
|---|---|
| `admins`, `adminInvites`, `roles` | Firebase Auth administrator profiles, invitations, and permissions |
| `customers`, `wallets` | Customer profiles and wallet balances |
| `providers`, `providerLocations`, `verificationRequirements` | Technician profiles, live coordinates, document policy, and embedded verification records |
| `orders` | Requests/jobs with customer/provider snapshots, offers, media, chat, calls, timeline, cancellation, and payment details |
| `categories`, `services`, `banners` | Customer/provider app catalog and merchandising content |
| `transactions`, `payouts`, `instapayReviews` | Financial ledger, provider payouts, and manual payment review |
| `complaints`, `conversations` | Trust-and-safety cases and support conversations |
| `promos`, `notifications` | Growth and app messaging controls |
| `auditLogs` | Append-only administrative action history |
| `aiExecutions`, `aiMemories`, `aiReports` | Task AI Operations Executive runs, record memory, recommendations, and generated operational reports |
| `settings`, `system` | Persisted branding/configuration and atomic counters |

Provider IDs are allocated in a transaction against `system/counters` and stored permanently on the provider document. Wallet adjustment, refund, payout hold, and their transaction ledger entry are committed together with Firestore transactions/batches.

Map tracking uses `providerLocations/{providerId}` for technician coordinates and `orders/{jobId}.gps` for customer/request coordinates. No synthetic fallback locations are stored by the dashboard.
