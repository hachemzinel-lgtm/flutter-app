class DocumentVerificationResult {
  final bool isVerified;
  final bool isLegible;
  final bool isOfficialDocument;
  final String? detectedCategory;
  final String confidence;
  final String reason;

  DocumentVerificationResult({
    required this.isVerified,
    required this.isLegible,
    required this.isOfficialDocument,
    this.detectedCategory,
    required this.confidence,
    required this.reason,
  });

  factory DocumentVerificationResult.fromJson(Map<String, dynamic> json) {
    return DocumentVerificationResult(
      isVerified: json['isVerified'] ?? false,
      isLegible: json['isLegible'] ?? false,
      isOfficialDocument: json['isOfficialDocument'] ?? false,
      detectedCategory: json['detectedCategory'] as String?,
      confidence: json['confidence'] as String? ?? 'low',
      reason: json['reason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isVerified': isVerified,
      'isLegible': isLegible,
      'isOfficialDocument': isOfficialDocument,
      'detectedCategory': detectedCategory,
      'confidence': confidence,
      'reason': reason,
    };
  }
}
