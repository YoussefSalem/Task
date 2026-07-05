# Admin roles and permissions

Permission checks belong in navigation visibility, trusted Firebase Admin routes, and Firebase Security Rules. UI hiding alone is never authorization.

| Permission | Allows |
|---|---|
| `customers.read` | View profiles, bookings, complaints, addresses, wallets |
| `customers.write` | Create/edit/suspend customers and adjust wallet balance |
| `providers.read` | View profiles, documents, earnings, jobs |
| `providers.approve` | Approve/reject identity verification |
| `providers.suspend` | Suspend or ban provider accounts |
| `jobs.read` | View jobs, timeline, payment details |
| `jobs.write` | Create, assign, status-change, cancel, reopen jobs |
| `services.manage` | Manage categories, pricing, fees, coverage, availability |
| `payments.read` | View transactions, wallets, settlements |
| `payments.manage` | Refunds, cash reconciliation, payout verification |
| `trust.manage` | Create/assign/close incidents and attach evidence |
| `promotions.manage` | Promo code and campaign management |
| `notifications.send` | Send or schedule customer/provider messages |
| `admins.manage` | Invite/disable admins and assign roles |
| `audit.read` | View append-only audit activity |

Production permissions are stored on each Firestore role and copied into the active administrator document and Firebase custom claims. Firestore and Storage Rules enforce the document-level boundary; administrator identity changes use the Firebase Admin SDK route.
