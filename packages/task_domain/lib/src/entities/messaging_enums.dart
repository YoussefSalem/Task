/// Which side of a job conversation authored a message. A thread always has
/// exactly one customer and one technician.
enum SenderRole { customer, technician }

/// The kind of event a notification represents. Drives the icon, copy, and the
/// destination a tap routes to in the in-app feed.
enum NotificationType {
  /// A new chat message arrived in one of the recipient's threads.
  message,

  /// A technician posted an offer on the customer's job.
  offer,

  /// The customer accepted the technician's offer (technician was hired).
  hired,

  /// A job moved to a new lifecycle state (on the way, arrived, completed…).
  jobStatus,
}
