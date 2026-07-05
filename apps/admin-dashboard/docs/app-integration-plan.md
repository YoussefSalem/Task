# Customer and provider app integration plan

The admin, customer app, and provider app should share the Firestore model in `lib/types.ts`. Customer and provider apps must use separate Security Rule branches scoped to their own Firebase Auth UID; they must never receive administrator claims.

- Customer app: subscribe to enabled categories/services/banners, its own profile, wallet, orders, offers, messages, payments, promos, and notifications.
- Provider app: subscribe to its provider profile, verification state, availability, nearby requests, offers, assigned orders, earnings, payouts, and notifications.
- Admin dashboard: subscribes to authorized operational collections through `lib/firebase/repository.ts`.
- Mobile location updates: write provider coordinates to `providerLocations/{providerId}` from a trusted provider session or ingestion function. Customer request creation should write request coordinates to `orders/{orderId}.gps`.
- AI operations: AI executions are stored in `aiExecutions`, durable record memory is stored in `aiMemories`, and generated executive reports are stored in `aiReports`. The AI layer runs through the server-only Gemini route, reads Firestore dashboard state, and only proposes sensitive actions until an admin confirms them.

Use Cloud Functions for mobile-facing workflows that require multi-party authorization, push delivery, payment-provider webhooks, or privileged state transitions. Firestore and Storage Rules remain the final client-access boundary.
