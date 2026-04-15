import 'package:cloud_firestore/cloud_firestore.dart';

export 'package:flutter_application_1/models/verification_status.dart';

enum UserType { client, workProvider, marketplace }

extension UserTypeDisplay on UserType {
  String get displayName {
    switch (this) {
      case UserType.client:
        return 'Client';
      case UserType.workProvider:
        return 'Work Provider';
      case UserType.marketplace:
        return 'Marketplace';
    }
  }

  String get stringValue {
    switch (this) {
      case UserType.workProvider:
        return 'workProvider';
      case UserType.marketplace:
        return 'marketplace';
      case UserType.client:
        return 'client';
    }
  }
}

class UserModel {
  // Core identity
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final DateTime? createdAt;
  final bool isEmailVerified;

  // Role & Profile Status
  final UserType userType; // Replaces redundant role strings
  final String role; // System role, e.g. "user" or "admin"
  final bool profileCompleted;

  // User Data
  final String? phone;
  final GeoPoint? location;
  final String? address;
  final String language;
  final double rating;
  final int reviewCount;
  final bool isBanned;
  final bool notificationsEnabled;

  // Work Provider / Marketplace specific fields
  final String?
  verificationStatus; // "unverified", "ai_verified", "admin_verified", "rejected"
  final int verificationAttempts;
  final bool availabilityToggle;
  final bool openStatus;
  final String? businessName;
  final String? category;
  final bool badgeVisible;
  final String? bio;
  final String? description;
  final int? serviceRadius;
  final int? deliveryRadius;
  final int? yearsExperience;
  final String? documentUrl;
  final String? verificationReason;
  final String? verificationConfidence;
  final DateTime? verificationTimestamp;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.createdAt,
    this.isEmailVerified = false,
    required this.userType,
    this.role = 'user',
    this.profileCompleted = false,
    this.phone,
    this.location,
    this.address,
    this.language = 'en',
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isBanned = false,
    this.notificationsEnabled = true,
    this.verificationStatus = 'unverified',
    this.verificationAttempts = 0,
    this.availabilityToggle = false,
    this.openStatus = false,
    this.businessName,
    this.category,
    this.badgeVisible = false,
    this.bio,
    this.description,
    this.serviceRadius,
    this.deliveryRadius,
    this.yearsExperience,
    this.documentUrl,
    this.verificationReason,
    this.verificationConfidence,
    this.verificationTimestamp,
  });

  // ── Compatibility getters for existing codebase ──────────────────────────────
  String get uid => id;
  String get displayName => name;
  double get averageRating => rating;
  bool get profileComplete => profileCompleted;
  String get accountType => userType.stringValue;

  // ── Static helpers ────────────────────────────────────────────────────────
  static UserType parseUserType(String? value) {
    switch (value) {
      case 'work_provider':
      case 'workProvider':
        return UserType.workProvider;
      case 'marketplace':
        return UserType.marketplace;
      case 'client':
      default:
        return UserType.client;
    }
  }

  // ── Serialisation ─────────────────────────────────────────────────────────
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? json['displayName'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : (json['createdAt'] as DateTime?),
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      userType: parseUserType(
        json['userType']?.toString() ??
            json['accountType']?.toString() ??
            'client',
      ),
      role: json['role'] as String? ?? 'user',
      profileCompleted: json['profileComplete'] as bool? ?? false,
      phone: json['phone'] as String?,
      location: json['location'] as GeoPoint?,
      address: json['address'] as String?,
      language: json['language'] as String? ?? 'en',
      rating:
          (json['rating'] as num?)?.toDouble() ??
          (json['averageRating'] as num?)?.toDouble() ??
          0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      isBanned: json['isBanned'] as bool? ?? false,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      verificationStatus: json['verificationStatus'] as String? ?? 'unverified',
      verificationAttempts: json['verificationAttempts'] as int? ?? 0,
      availabilityToggle: json['availabilityToggle'] as bool? ?? false,
      openStatus: json['openStatus'] as bool? ?? false,
      businessName: json['businessName'] as String?,
      category: json['category'] as String?,
      badgeVisible: json['badgeVisible'] as bool? ?? false,
      bio: json['bio'] as String?,
      description: json['description'] as String?,
      serviceRadius: json['serviceRadius'] as int?,
      deliveryRadius: json['deliveryRadius'] as int?,
      yearsExperience: json['yearsExperience'] as int?,
      documentUrl: json['documentUrl'] as String?,
      verificationReason: json['verificationReason'] as String?,
      verificationConfidence: json['verificationConfidence'] as String?,
      verificationTimestamp: json['verificationTimestamp'] is Timestamp
          ? (json['verificationTimestamp'] as Timestamp).toDate()
          : (json['verificationTimestamp'] as DateTime?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': id, // Write both for compatibility
      'email': email,
      'name': name,
      'displayName': name, // Write both for compatibility
      'photoUrl': photoUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'isEmailVerified': isEmailVerified,
      'accountType':
          userType.stringValue, // Standardized string field for the DB
      'userType': userType.stringValue, // Standardized string field for the DB
      'role': role,
      'profileComplete': profileCompleted,
      'phone': phone,
      'location': location,
      'address': address,
      'language': language,
      'rating': rating,
      'averageRating': rating, // Write both for compatibility
      'reviewCount': reviewCount,
      'isBanned': isBanned,
      'notificationsEnabled': notificationsEnabled,
      'verificationStatus': verificationStatus,
      'verificationAttempts': verificationAttempts,
      'availabilityToggle': availabilityToggle,
      'openStatus': openStatus,
      'businessName': businessName,
      'category': category,
      'badgeVisible': badgeVisible,
      'bio': bio,
      'description': description,
      'serviceRadius': serviceRadius,
      'deliveryRadius': deliveryRadius,
      'yearsExperience': yearsExperience,
      'documentUrl': documentUrl,
      'verificationReason': verificationReason,
      'verificationConfidence': verificationConfidence,
      'verificationTimestamp': verificationTimestamp != null
          ? Timestamp.fromDate(verificationTimestamp!)
          : null,
    };
  }

  UserModel copyWith({
    String? id,
    String? uid,
    String? email,
    String? name,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    bool? isEmailVerified,
    UserType? userType,
    String? accountType,
    String? role,
    bool? profileCompleted,
    bool? profileComplete,
    String? phone,
    GeoPoint? location,
    String? address,
    String? language,
    double? rating,
    double? averageRating,
    int? reviewCount,
    bool? isBanned,
    bool? notificationsEnabled,
    String? verificationStatus,
    int? verificationAttempts,
    bool? availabilityToggle,
    bool? openStatus,
    String? businessName,
    String? category,
    bool? badgeVisible,
    String? bio,
    String? description,
    int? serviceRadius,
    int? deliveryRadius,
    int? yearsExperience,
    String? documentUrl,
    String? verificationReason,
    String? verificationConfidence,
    DateTime? verificationTimestamp,
  }) {
    return UserModel(
      id: id ?? uid ?? this.id,
      email: email ?? this.email,
      name: name ?? displayName ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      userType:
          userType ??
          (accountType != null
              ? UserModel.parseUserType(accountType)
              : this.userType),
      role: role ?? this.role,
      profileCompleted:
          profileCompleted ?? profileComplete ?? this.profileCompleted,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      address: address ?? this.address,
      language: language ?? this.language,
      rating: rating ?? averageRating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isBanned: isBanned ?? this.isBanned,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationAttempts: verificationAttempts ?? this.verificationAttempts,
      availabilityToggle: availabilityToggle ?? this.availabilityToggle,
      openStatus: openStatus ?? this.openStatus,
      businessName: businessName ?? this.businessName,
      category: category ?? this.category,
      badgeVisible: badgeVisible ?? this.badgeVisible,
      bio: bio ?? this.bio,
      description: description ?? this.description,
      serviceRadius: serviceRadius ?? this.serviceRadius,
      deliveryRadius: deliveryRadius ?? this.deliveryRadius,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      documentUrl: documentUrl ?? this.documentUrl,
      verificationReason: verificationReason ?? this.verificationReason,
      verificationConfidence:
          verificationConfidence ?? this.verificationConfidence,
      verificationTimestamp:
          verificationTimestamp ?? this.verificationTimestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          name == other.name &&
          photoUrl == other.photoUrl &&
          userType == other.userType &&
          profileCompleted == other.profileCompleted &&
          rating == other.rating &&
          reviewCount == other.reviewCount &&
          isBanned == other.isBanned &&
          verificationStatus == other.verificationStatus &&
          availabilityToggle == other.availabilityToggle &&
          openStatus == other.openStatus &&
          badgeVisible == other.badgeVisible;

  @override
  int get hashCode => Object.hash(
    id,
    email,
    name,
    photoUrl,
    userType,
    profileCompleted,
    rating,
    reviewCount,
    isBanned,
    verificationStatus,
    availabilityToggle,
    openStatus,
    badgeVisible,
  );
}
