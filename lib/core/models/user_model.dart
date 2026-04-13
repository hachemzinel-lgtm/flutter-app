import 'package:cloud_firestore/cloud_firestore.dart';

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
}

enum VerificationStatus { pending, approved, rejected }

class UserModel {
  // Core identity
  final String id;
  final String email;
  final String name;
  final String phone;
  final String? photoUrl;
  final DateTime? createdAt;
  final GeoPoint? location;
  final String? address;
  final String? language;
  final double rating;
  final int reviewCount;
  final bool isBanned;
  final bool notificationsEnabled;
  final bool profileCompleted;
  final UserType userType;

  // Optional extended fields
  final String? verificationStatus;
  final int? verificationAttempts;
  final bool? availabilityToggle;
  final bool? openStatus;
  final String? businessName;
  final String? category;
  final bool? badgeVisible;
  final String? bio;
  final String? description;
  final int? serviceRadius;
  final int? deliveryRadius;
  final int? yearsExperience;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    this.photoUrl,
    this.createdAt,
    this.location,
    this.address,
    this.language,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isBanned = false,
    this.notificationsEnabled = true,
    this.profileCompleted = false,
    required this.userType,
    this.verificationStatus,
    this.verificationAttempts,
    this.availabilityToggle,
    this.openStatus,
    this.businessName,
    this.category,
    this.badgeVisible,
    this.bio,
    this.description,
    this.serviceRadius,
    this.deliveryRadius,
    this.yearsExperience,
  });

  // ── Compatibility getters for new-style code ──────────────────────────────
  String get uid => id;
  String get displayName => name;
  double get averageRating => rating;
  bool get profileComplete => profileCompleted;
  String get accountType {
    switch (userType) {
      case UserType.workProvider:
        return 'work_provider';
      case UserType.marketplace:
        return 'marketplace';
      case UserType.client:
        return 'client';
    }
  }

  // ── Static helpers ────────────────────────────────────────────────────────
  static UserType parseUserType(String value) {
    switch (value) {
      case 'workProvider':
      case 'work_provider':
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
      phone: json['phone'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      location: json['location'] as GeoPoint?,
      address: json['address'] as String?,
      language: json['language'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ??
          (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      isBanned: json['isBanned'] as bool? ?? false,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      profileCompleted: json['profileCompleted'] as bool? ??
          json['profileComplete'] as bool? ?? false,
      userType: parseUserType(
        json['userType']?.toString() ??
            json['accountType']?.toString() ??
            'client',
      ),
      verificationStatus: json['verificationStatus'] as String?,
      verificationAttempts: json['verificationAttempts'] as int?,
      availabilityToggle: json['availabilityToggle'] as bool?,
      openStatus: json['openStatus'] as bool?,
      businessName: json['businessName'] as String?,
      category: json['category'] as String?,
      badgeVisible: json['badgeVisible'] as bool?,
      bio: json['bio'] as String?,
      description: json['description'] as String?,
      serviceRadius: json['serviceRadius'] as int?,
      deliveryRadius: json['deliveryRadius'] as int?,
      yearsExperience: json['yearsExperience'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'photoUrl': photoUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'location': location,
      'address': address,
      'language': language,
      'rating': rating,
      'reviewCount': reviewCount,
      'isBanned': isBanned,
      'notificationsEnabled': notificationsEnabled,
      'profileCompleted': profileCompleted,
      'userType': userType.name,
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
    };
  }
}
