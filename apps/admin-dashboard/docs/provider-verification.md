# Provider verification and Firebase Storage

Document requirements are persisted in the `verificationRequirements` collection and created by the Firebase seed. New providers snapshot the required document types so later policy changes cannot silently alter an in-progress verification case.

Files upload to `provider-documents/{providerId}/…` in Firebase Storage. Firestore stores the file name, type, size, MIME type, checksum, Storage URL/path, uploader, timestamp, expiry, review status, reviewer notes, and version history.

A provider cannot receive an order unless all mandatory documents are approved, the background check is complete, the contract is signed, and the provider is active and verified. Storage Rules restrict document read/write access to administrators with provider verification permission. Preview, download, upload, replacement, review, rejection, and deletion append audit records.
