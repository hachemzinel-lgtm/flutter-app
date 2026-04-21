/// Canonical verification statuses used throughout the app.
///
/// Each value's [name] property matches the string stored in Firestore.
enum VerificationStatus {
  unverified,
  pending,
  approved,
  rejected,
  ;

  /// Parse a raw Firestore string into a [VerificationStatus],
  /// defaulting to [unverified] for unknown values.
  static VerificationStatus fromString(String? value) {
    switch (value) {
      case 'pending':
        return VerificationStatus.pending;
      case 'approved':
      case 'ai_verified':
      case 'admin_verified':
        return VerificationStatus.approved;
      case 'rejected':
        return VerificationStatus.rejected;
      case 'unverified':
      default:
        return VerificationStatus.unverified;
    }
  }
}
