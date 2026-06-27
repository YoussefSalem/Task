# Production Firebase Wiring — Customer App

## Goal
Replace all timer-driven simulations and placeholder screens with Firestore-reactive behavior so the customer app is production-ready. Payment/wallet excluded.

## Data Model

### New: `jobs/{jobId}/reviews/{reviewerId}`
- `rating`: int (1-5)
- `tags`: string[]
- `note`: string
- `reviewer_id`: string
- `technician_id`: string
- `created_at`: timestamp

### Job doc fields written on hire
- `status`: `'accepted'`
- `accepted_offer_id`: string (technician uid)
- `accepted_at`: timestamp

## Screen Changes

### Matching Screen
Keep radar animation. Stream job doc + quotes subcollection. Phase transitions driven by real quote count, not timers. Timer becomes a timeout fallback.

### ASAP Dispatch Screen
Keep expanding-radius animation. Watch job doc for `status == 'accepted'`. Timer becomes timeout.

### Job Tracking Screen
Stream `jobs/{jobId}.status` for stage progression. Keep map animation but drive `_stageIndex` from Firestore. Stream `jobs/{jobId}/tracking` for live location.

### Offers Screen (hire action)
Write `status: accepted`, `accepted_offer_id`, `accepted_at` on hire tap. Navigate to tracking.

### Rating Screen
Write review to `jobs/{jobId}/reviews/{uid}`. Read technician name from job data (remove hardcoded name). Update job status to `completed`.

### Messages Inbox
Replace placeholder with live thread list. Query customer's jobs for threads with last message preview.

## Domain Layer

### JobMarketplaceRepository — new methods
- `acceptOffer(jobId, technicianId)`
- `submitReview(jobId, Review)`
- `cancelJob(jobId)`

### MessagingRepository — new method
- `watchThreadsForUser(uid)` — all threads with last message preview

### New model
- `Review` value class

## Firestore Rules

### Add reviews rule
```
match /jobs/{jobId}/reviews/{reviewerId} {
  allow create: if isSelf(reviewerId);
  allow read: if isSignedIn();
  allow update, delete: if isAdmin();
}
```

### Tighten job update
- Customer (owner): status to `accepted`/`cancelled`, plus `accepted_offer_id`, `accepted_at`
- Technician: status to `en_route`/`in_progress`/`completed`
- Admin: unrestricted
