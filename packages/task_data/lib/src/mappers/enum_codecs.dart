import 'package:task_domain/task_domain.dart';

/// Bidirectional enum <-> Firestore-string codecs using the EXACT wire values
/// fixed by the PRD schema (snake_case). Centralised so the Flutter clients and
/// the Cloud Functions contract share a single vocabulary — drift here would
/// silently break security rules and dispatch logic.
///
/// Parsing is total at the call site: unknown values throw [FormatException],
/// which the repository layer maps to a `ValidationFailure`.

extension UserRoleCodec on UserRole {
  String toWire() => switch (this) {
        UserRole.customer => 'customer',
        UserRole.technician => 'technician',
        UserRole.admin => 'admin',
      };

  static UserRole fromWire(String v) => switch (v) {
        'customer' => UserRole.customer,
        'technician' => UserRole.technician,
        'admin' => UserRole.admin,
        _ => throw FormatException('Unknown UserRole: $v'),
      };
}

extension KycStatusCodec on KycStatus {
  String toWire() => switch (this) {
        KycStatus.applied => 'applied',
        KycStatus.underReview => 'under_review',
        KycStatus.approved => 'approved',
        KycStatus.rejected => 'rejected',
        KycStatus.suspended => 'suspended',
      };

  static KycStatus fromWire(String v) => switch (v) {
        'applied' => KycStatus.applied,
        'under_review' => KycStatus.underReview,
        'approved' => KycStatus.approved,
        'rejected' => KycStatus.rejected,
        'suspended' => KycStatus.suspended,
        _ => throw FormatException('Unknown KycStatus: $v'),
      };
}

extension TechnicianTierCodec on TechnicianTier {
  String toWire() => switch (this) {
        TechnicianTier.bronze => 'bronze',
        TechnicianTier.silver => 'silver',
        TechnicianTier.gold => 'gold',
        TechnicianTier.platinum => 'platinum',
      };

  static TechnicianTier fromWire(String v) => switch (v) {
        'bronze' => TechnicianTier.bronze,
        'silver' => TechnicianTier.silver,
        'gold' => TechnicianTier.gold,
        'platinum' => TechnicianTier.platinum,
        _ => throw FormatException('Unknown TechnicianTier: $v'),
      };
}

extension JobStatusCodec on JobStatus {
  String toWire() => switch (this) {
        JobStatus.searching => 'searching',
        JobStatus.pendingScheduled => 'pending_scheduled',
        JobStatus.biddingActive => 'bidding_active',
        JobStatus.accepted => 'accepted',
        JobStatus.enRoute => 'en_route',
        JobStatus.inProgress => 'in_progress',
        JobStatus.pausedForApproval => 'paused_for_approval',
        JobStatus.completed => 'completed',
        JobStatus.disputed => 'disputed',
        JobStatus.cancelled => 'cancelled',
      };

  static JobStatus fromWire(String v) => switch (v) {
        'searching' => JobStatus.searching,
        'pending_scheduled' => JobStatus.pendingScheduled,
        'bidding_active' => JobStatus.biddingActive,
        'accepted' => JobStatus.accepted,
        'en_route' => JobStatus.enRoute,
        'in_progress' => JobStatus.inProgress,
        'paused_for_approval' => JobStatus.pausedForApproval,
        'completed' => JobStatus.completed,
        'disputed' => JobStatus.disputed,
        'cancelled' => JobStatus.cancelled,
        _ => throw FormatException('Unknown JobStatus: $v'),
      };
}

extension PaymentMethodCodec on PaymentMethod {
  String toWire() => switch (this) {
        PaymentMethod.cash => 'cash',
        PaymentMethod.card => 'card',
        PaymentMethod.wallet => 'wallet',
        PaymentMethod.instapay => 'instapay',
      };

  static PaymentMethod fromWire(String v) => switch (v) {
        'cash' => PaymentMethod.cash,
        'card' => PaymentMethod.card,
        'wallet' => PaymentMethod.wallet,
        'instapay' => PaymentMethod.instapay,
        _ => throw FormatException('Unknown PaymentMethod: $v'),
      };
}

extension PaymentStatusCodec on PaymentStatus {
  String toWire() => switch (this) {
        PaymentStatus.pending => 'pending',
        PaymentStatus.pendingAdminApproval => 'pending_admin_approval',
        PaymentStatus.authorized => 'authorized',
        PaymentStatus.captured => 'captured',
        PaymentStatus.failed => 'failed',
        PaymentStatus.refunded => 'refunded',
      };

  static PaymentStatus fromWire(String v) => switch (v) {
        'pending' => PaymentStatus.pending,
        'pending_admin_approval' => PaymentStatus.pendingAdminApproval,
        'authorized' => PaymentStatus.authorized,
        'captured' => PaymentStatus.captured,
        'failed' => PaymentStatus.failed,
        'refunded' => PaymentStatus.refunded,
        _ => throw FormatException('Unknown PaymentStatus: $v'),
      };
}

extension BookingTypeCodec on BookingType {
  String toWire() => switch (this) {
        BookingType.asap => 'asap',
        BookingType.scheduled => 'scheduled',
        BookingType.quote => 'quote',
      };

  static BookingType fromWire(String v) => switch (v) {
        'asap' => BookingType.asap,
        'scheduled' => BookingType.scheduled,
        'quote' => BookingType.quote,
        _ => throw FormatException('Unknown BookingType: $v'),
      };
}

extension SenderRoleCodec on SenderRole {
  String toWire() => switch (this) {
        SenderRole.customer => 'customer',
        SenderRole.technician => 'technician',
      };

  static SenderRole fromWire(String v) => switch (v) {
        'customer' => SenderRole.customer,
        'technician' => SenderRole.technician,
        _ => throw FormatException('Unknown SenderRole: $v'),
      };
}

extension WalletTransactionTypeCodec on WalletTransactionType {
  String toWire() => switch (this) {
        WalletTransactionType.referral => 'referral',
        WalletTransactionType.refund => 'refund',
        WalletTransactionType.credit => 'credit',
        WalletTransactionType.debit => 'debit',
      };

  static WalletTransactionType fromWire(String v) => switch (v) {
        'referral' => WalletTransactionType.referral,
        'refund' => WalletTransactionType.refund,
        'credit' => WalletTransactionType.credit,
        'debit' => WalletTransactionType.debit,
        _ => throw FormatException('Unknown WalletTransactionType: $v'),
      };
}

extension NotificationTypeCodec on NotificationType {
  String toWire() => switch (this) {
        NotificationType.message => 'message',
        NotificationType.offer => 'offer',
        NotificationType.hired => 'hired',
        NotificationType.jobStatus => 'job_status',
      };

  static NotificationType fromWire(String v) => switch (v) {
        'message' => NotificationType.message,
        'offer' => NotificationType.offer,
        'hired' => NotificationType.hired,
        'job_status' => NotificationType.jobStatus,
        _ => throw FormatException('Unknown NotificationType: $v'),
      };
}
