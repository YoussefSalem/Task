// Canonical enums fixed by the PRD. Kept free of serialization concerns —
// DTO mapping (string <-> enum) lives in `task_data`.

/// Distinguishes documents in the shared `users` collection (PRD §2.1).
enum UserRole { customer, technician, admin }

/// Technician verification lifecycle (PRD §2.1, §6.3).
enum KycStatus { applied, underReview, approved, rejected, suspended }

/// Technician ranking tier (PRD §2.1). Threshold math is Phase 2.
enum TechnicianTier { bronze, silver, gold, platinum }

/// The job state machine (PRD §2.3 / §3). Order is significant.
enum JobStatus {
  searching,
  pendingScheduled,
  biddingActive,
  accepted,
  enRoute,
  inProgress,
  pausedForApproval,
  completed,
  disputed,
  cancelled,
}

/// How the customer pays (PRD §2.3 + clarified v1 scope).
///
/// - [cash]: COD, state-synced customer↔technician.
/// - [card] / [wallet]: Paymob (card, Vodafone Cash).
/// - [instapay]: requires admin approval before confirmation.
enum PaymentMethod { cash, card, wallet, instapay }

/// Lifecycle of a payment record. [pendingAdminApproval] is InstaPay-specific.
enum PaymentStatus {
  pending,
  pendingAdminApproval,
  authorized,
  captured,
  failed,
  refunded,
}

/// Which booking engine produced the job (PRD §3).
enum BookingType { asap, scheduled, quote }
