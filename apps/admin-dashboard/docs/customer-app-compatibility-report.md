# Task Customer App Compatibility Report

Audit source: `/Users/pilot/Desktop/Unitas/TASK APP/Task/apps/customer`

## Existing Firebase project

- Customer app Firebase project: `task-app-20c5f`
- Current admin dashboard local Firebase project: `task-admin-eg`
- Compatibility requirement: the admin dashboard must be configured with the same Firebase Web SDK values and Admin SDK credentials as `task-app-20c5f` before production deployment, otherwise both apps will still use separate databases.

## Existing Firestore collections

From the customer app, shared packages, and backend rules:

- `users`
  - Shared collection for customers, technicians, and admins.
  - `role`: `customer`, `technician`, `admin`
  - Customer fields include: `first_name`, `last_name`, `email`, `phone`, `phone_number`, `addresses`, wallet metadata.
  - Technician fields include: `first_name`, `last_name`, `primary_category`, `rating`, `jobs_done`, `tier`, `photo_url`, `kyc_status`.
- `users/{uid}/notifications/{notificationId}`
- `users/{uid}/fcm_tokens/{token}`
- `users/{uid}/wallet/summary`
  - `balance_minor`, `currency`, `updated_at`
- `users/{uid}/wallet_transactions/{txnId}`
  - `type`, `amount_minor`, `title`, `created_at`
- `addresses`
  - `user_id`, address details, optional coordinates.
- `jobs`
  - Source of truth for customer requests/bookings.
  - Core fields: `customer_id`, `category`, `title`, `description`, `fixed_price`, `currency`, `urgency`, `property_type`, `floor`, `parking`, `photos`, `location_label`, `notes`, `status`, `offers`, `created_at`, `cancellation_reason`, `cancelled_at`.
- `jobs/{jobId}/quotes/{technicianId}`
  - Sealed-bid/quote subcollection in rules.
- `jobs/{jobId}/tracking/{pointId}`
  - `lat`, `lng`, `at`, `eta_minutes`.
- `jobs/{jobId}/threads/{technicianId}`
  - `customer_id`, `technician_id`, `technician_name`, `last_message`, `last_message_at`, read cursors, typing stamps.
- `jobs/{jobId}/threads/{technicianId}/messages/{messageId}`
  - `sender_id`, `sender_role`, `text`, `created_at`.
- `jobs/{jobId}/reviews/{reviewerId}`
- `promotions`
  - `headline`, `subtitle`, `badge`, `accent_hex`, `icon_name`, `active`, `order`.

## Existing domain models and enums

Canonical domain package: `packages/task_domain`.

- `UserRole`: `customer`, `technician`, `admin`
- `KycStatus`: `applied`, `underReview`, `approved`, `rejected`, `suspended`
- `TechnicianTier`: `bronze`, `silver`, `gold`, `platinum`
- `JobStatus`: `searching`, `pendingScheduled`, `biddingActive`, `accepted`, `enRoute`, `inProgress`, `pausedForApproval`, `completed`, `disputed`, `cancelled`
- `PaymentMethod`: `cash`, `card`, `wallet`, `instapay`
- `PaymentStatus`: `pending`, `pendingAdminApproval`, `authorized`, `captured`, `failed`, `refunded`
- `BookingType`: `asap`, `scheduled`, `quote`
- `Urgency`: `flexible`, `soon`, `urgent`, `emergency`
- `PropertyType`: `apartment`, `villa`, `office`, `other`
- `OfferStatus`: `pending`, `countered`, `accepted`, `declined`, `withdrawn`

Important implementation nuance: `task_data` has snake_case enum codecs, but the current customer app marketplace repository writes Dart enum `.name` values for jobs/offers, for example `biddingActive`, `pendingScheduled`, `accepted`, `cancelled`. The admin adapter now supports both forms when reading.

## Existing business logic

- Customer app publishes fixed-price jobs to top-level `jobs`.
- Customer jobs are scoped with `customer_id`.
- Customer app watches only `jobs where customer_id == auth.uid`.
- Job offers currently live inline in `jobs.offers`.
- Rules also define sealed quotes under `jobs/{jobId}/quotes/{technicianId}` for future/technician-side implementation.
- Customer accepts an offer by marking the selected offer `accepted`, other offers `declined`, and job `status` as `accepted`.
- Customer cancellation updates job `status` to `cancelled`, `cancelled_at`, and optional `cancellation_reason`.
- Customer reviews are stored under `jobs/{jobId}/reviews/{reviewerId}`.
- Wallet data is read-only to customers and stored under the user document subcollections.
- Notifications are stored per user under `users/{uid}/notifications`.
- Push tokens are stored under `users/{uid}/fcm_tokens`.
- Technician directory reads `users where role == technician`, ordered by `rating`.

## Dashboard changes made

- Production Customers now read from `users` where `role == customer`.
- Production Technicians/Providers now read from `users` where `role == technician`.
- Production Jobs now read from `jobs`, not `orders`.
- Added adapter mapping from customer app documents to existing dashboard view models.
- Admin customer creation now writes a `users/{id}` document with `role: customer`.
- Admin technician creation now writes a `users/{id}` document with `role: technician`, `provider_id`, `primary_category`, `kyc_status`, and existing dashboard metadata.
- Admin manual job creation now writes to `jobs/{jobId}` with customer-app fields:
  - `customer_id`
  - `service_id`
  - `category`
  - `title`
  - `description`
  - `fixed_price`
  - `urgency`
  - `property_type`
  - `location_label`
  - `status`
  - `booking_type`
  - `scheduled_at`
  - `offers`
  - `payment_status`
  - `payment_method`
  - `created_at`
- Admin provider assignment now updates canonical job fields:
  - `provider_id`
  - `provider_name`
  - `status: accepted`
- Admin job status changes now translate dashboard statuses to customer-app status values.
- Admin wallet adjustments for production now write to:
  - `users/{customerId}/wallet/summary`
  - `users/{customerId}/wallet_transactions/{txnId}`
- Admin refunds for production now update:
  - `jobs/{jobId}.payment_status`
  - `users/{customerId}/wallet/summary`
  - `users/{customerId}/wallet_transactions/{txnId}`
- Firestore rules were updated locally to cover canonical:
  - `users`
  - `users/{uid}/wallet`
  - `users/{uid}/wallet_transactions`
  - `jobs`
  - `jobs/{jobId}/quotes`
  - `jobs/{jobId}/tracking`
  - `jobs/{jobId}/threads`
  - `jobs/{jobId}/threads/{technicianId}/messages`
  - `jobs/{jobId}/reviews`

## Schema conflicts found

- Admin dashboard was using `customers`, `providers`, and `orders`; customer app uses `users` and `jobs`.
- Admin wallet model was top-level `wallets` and `transactions`; customer app wallet model is nested under `users/{uid}`.
- Admin used title-case statuses like `Scheduled`, `Assigned`, `Completed`; customer app uses Dart enum names like `pendingScheduled`, `biddingActive`, `accepted`.
- Admin used `providers`; customer app calls the same role `technician` in `users.role`.
- Admin local Firebase config currently targets `task-admin-eg`; customer app targets `task-app-20c5f`.
- Customer app has `promotions`; admin has `banners` and `promos`. This still needs a marketing/content bridge if the mobile home banners must be fully admin-managed through the same collection.
- Customer app payment screen still has prototype-local wallet deduction for one UI path, though shared Firestore wallet repositories already exist.

## Improvements made

- Added production adapter layer to avoid duplicate collections for core operational data.
- Preserved demo isolation by keeping demo admin data in existing demo-scoped admin collections.
- Made admin job reads tolerant of both snake_case and Dart enum-name status values.
- Made admin job notes compatible with customer app’s `notes: string` field.
- Added Firestore rules for the canonical customer app schema.
- Kept existing dashboard UI view models stable so pages do not need a full redesign.

## Unified backend confirmation

After configuring the admin dashboard to use the customer app Firebase project (`task-app-20c5f`), the Customer App, future Technician App, and Admin Dashboard will share the same backend architecture for the core marketplace model:

- People: `users`
- Requests/bookings: `jobs`
- Technician offers/quotes: `jobs.offers` and/or `jobs/{jobId}/quotes`
- Tracking: `jobs/{jobId}/tracking`
- Chat: `jobs/{jobId}/threads/{technicianId}/messages`
- Reviews: `jobs/{jobId}/reviews`
- Wallet: `users/{uid}/wallet` and `users/{uid}/wallet_transactions`
- Notifications: `users/{uid}/notifications`

Remaining follow-up for full parity: switch admin Firebase environment variables and service account from `task-admin-eg` to `task-app-20c5f`, deploy the updated Firestore rules to that project, and bridge admin marketing banners to the customer app `promotions` collection.
