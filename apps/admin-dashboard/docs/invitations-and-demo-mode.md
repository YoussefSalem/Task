# Invitations and Demo Mode

## Admin invitation email setup

Invitations use Firebase Admin SDK to create the Auth user and generate a secure password setup link. Email delivery uses Resend when configured.

Required production environment variables:

- `ADMIN_DASHBOARD_URL=https://task-admin-eg.web.app`
- `RESEND_API_KEY`
- `RESEND_FROM_EMAIL`
- `RESEND_FROM_NAME`
- optional `RESEND_REPLY_TO_EMAIL`

`RESEND_FROM_EMAIL` must be a verified sender/domain in Resend. Keep the API key server-side only; never prefix it with `NEXT_PUBLIC_`.

If Resend is not configured or rejects delivery, the dashboard does not crash. It returns a generated activation link to the admin with a Copy Link button so the link can be sent manually until email is configured.

## Demo isolation model

The dashboard uses a single Firestore project with environment scoping:

- production records have no `isDemoData` flag, or `isDemoData !== true`
- demo records always have `isDemoData: true`

Demo users:

- read only demo-scoped operational records
- write only records with `isDemoData: true`
- cannot call production destructive APIs
- cannot manage real users, roles, settings, exports, payouts, or real notifications

Isolation is enforced in three places:

1. UI/action checks in `lib/demo-mode.ts`
2. repository record checks in `lib/firebase/repository.ts`
3. Firestore Security Rules in `firestore.rules`

## Reset demo data

From Terminal:

```bash
npm run seed:demo
```

From the dashboard:

- Sign in as Super Admin
- Open Admin Users
- Click **Reset demo data**

The reset is idempotent. It deletes only documents where `isDemoData == true`, then recreates realistic demo data for customers, providers, jobs, payments, wallets, complaints, conversations, services, categories, banners, promos, notifications, locations, Instapay review, payout, and analytics.

Production records are never deleted by the demo reset.
