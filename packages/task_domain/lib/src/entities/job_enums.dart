/// How quickly the customer needs the job done.
enum Urgency { flexible, soon, urgent, emergency }

/// The kind of property the job is at (collected in the creation flow, slice 2).
enum PropertyType { apartment, villa, office, other }

/// Who made a given price proposal inside an [Offer] thread.
enum ProposalAuthor { customer, technician }

/// Lifecycle of a single technician's negotiation thread for a job.
enum OfferStatus { pending, countered, accepted, declined, withdrawn }
