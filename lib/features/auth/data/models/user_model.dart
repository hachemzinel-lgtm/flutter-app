import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType { client, work_provider, marketplace }

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String accountType; // "client" | "work_provider" | "marketplace"
  final String role; // "user" | "admin"
  final Timestamp createdAt;
  final bool isEmailVerified;
  final bool profileComplete;
  final String language;
  final GeoPoint? location;
  final double averageRating;
  final int reviewCount;

  // Work Provider specific fields
  final String? category;
  final String? bio;
  final int? yearsExperience;
  final String? phone;
  final int? serviceRadius;
  final bool availabilityToggle;
  final String verificationStatus; // "unverified"|"ai_verified"|"admin_verified"|"rejected"
  final bool badgeVisible;
  final String? documentUrl;
  final String? verificationReason;
  final String? verificationConfidence;
  final Timestamp? verificationTimestamp;
  final int verificationAttempts;

  // Marketplace specific fields
  final String? businessName;
  final String? description;
  final int? deliveryRadius;
  final bool openStatus;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.accountType,
    this.role = 'user',
    required this.createdAt,
    this.isEmailVerified = false,
    this.profileComplete = false,
    this.language = 'en',
    this.location,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.category,
    this.bio,
    this.yearsExperience,
    this.phone,
    this.serviceRadius,
    this.availabilityToggle = false,
    this.verificationStatus = 'unverified',
    this.badgeVisible = false,
    this.documentUrl,
    this.verificationReason,
    this.verificationConfidence,
    this.verificationTimestamp,
    this.verificationAttempts = 0,
    this.businessName,
    this.description,
    this.deliveryRadius,
    this.openStatus = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      photoUrl: json['photoUrl'],
      accountType: json['accountType'] ?? 'client',
      role: json['role'] ?? 'user',
      createdAt: json['createdAt'] ?? Timestamp.now(),
      isEmailVerified: json['isEmailVerified'] ?? false,
      profileComplete: json['profileComplete'] ?? false,
      language: json['language'] ?? 'en',
      location: json['location'] as GeoPoint?,
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      category: json['category'],
      bio: json['bio'],
      yearsExperience: json['yearsExperience'],
      phone: json['phone'],
      serviceRadius: json['serviceRadius'],
      availabilityToggle: json['availabilityToggle'] ?? false,
      verificationStatus: json['verificationStatus'] ?? 'unverified',
      badgeVisible: json['badgeVisible'] ?? false,
      documentUrl: json['documentUrl'],
      verificationReason: json['verificationReason'],
      verificationConfidence: json['verificationConfidence'],
      verificationTimestamp: json['verificationTimestamp'] as Timestamp?,
      verificationAttempts: json['verificationAttempts'] ?? 0,
      businessName: json['businessName'],
      description: json['description'],
      deliveryRadius: json['deliveryRadius'],
      openStatus: json['openStatus'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'accountType': accountType,
      'role': role,
      'createdAt': createdAt,
      'isEmailVerified': isEmailVerified,
      'profileComplete': profileComplete,
      'language': language,
      'location': location,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'category': category,
      'bio': bio,
      'yearsExperience': yearsExperience,
      'phone': phone,
      'serviceRadius': serviceRadius,
      'availabilityToggle': availabilityToggle,
      'verificationStatus': verificationStatus,
      'badgeVisible': badgeVisible,
      'documentUrl': documentUrl,
      'verificationReason': verificationReason,
      'verificationConfidence': verificationConfidence,
      'verificationTimestamp': verificationTimestamp,
      'verificationAttempts': verificationAttempts,
      'businessName': businessName,
      'description': description,
      'deliveryRadius': deliveryRadius,
      'openStatus': openStatus,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? accountType,
    String? role,
    Timestamp? createdAt,
    bool? isEmailVerified,
    bool? profileComplete,
    String? language,
    GeoPoint? location,
    double? averageRating,
    int? reviewCount,
    String? category,
    String? bio,
    int? yearsExperience,
    String? phone,
    int? serviceRadius,
    bool? availabilityToggle,
    String? verificationStatus,
    bool? badgeVisible,
    String? documentUrl,
    String? verificationReason,
    String? verificationConfidence,
    Timestamp? verificationTimestamp,
    int? verificationAttempts,
    String? businessName,
    String? description,
    int? deliveryRadius,
    bool? openStatus,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      accountType: accountType ?? this.accountType,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      profileComplete: profileComplete ?? this.profileComplete,
      language: language ?? this.language,
      location: location ?? this.location,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      category: category ?? this.category,
      bio: bio ?? this.bio,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      phone: phone ?? this.phone,
      serviceRadius: serviceRadius ?? this.serviceRadius,
      availabilityToggle: availabilityToggle ?? this.availabilityToggle,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      badgeVisible: badgeVisible ?? this.badgeVisible,
      documentUrl: documentUrl ?? this.documentUrl,
      verificationReason: verificationReason ?? this.verificationReason,
      verificationConfidence:
          verificationConfidence ?? this.verificationConfidence,
      verificationTimestamp: verificationTimestamp ?? this.verificationTimestamp,
      verificationAttempts: verificationAttempts ?? this.verificationAttempts,
      businessName: businessName ?? this.businessName,
      description: description ?? this.description,
      deliveryRadius: deliveryRadius ?? this.deliveryRadius,
      openStatus: openStatus ?? this.openStatus,
    );
  }
}
