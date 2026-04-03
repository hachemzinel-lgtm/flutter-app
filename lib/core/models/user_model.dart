import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType { client, workProvider, marketplace }

extension UserTypeExtension on UserType {
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

enum VerificationStatus {
  pending,
  approved,
  rejected,
  notRequired;

  static VerificationStatus fromValue(String? value) {
    switch (value) {
      case 'approved':
        return VerificationStatus.approved;
      case 'rejected':
        return VerificationStatus.rejected;
      case 'pending':
        return VerificationStatus.pending;
      default:
        return VerificationStatus.notRequired;
    }
  }
}

extension VerificationStatusExtension on VerificationStatus {
  String get displayName {
    switch (this) {
      case VerificationStatus.pending:
        return 'Pending';
      case VerificationStatus.approved:
        return 'Approved';
      case VerificationStatus.rejected:
        return 'Rejected';
      case VerificationStatus.notRequired:
        return 'Not Required';
    }
  }
}

class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final UserType userType;
  final DateTime? createdAt;
  final String? photoUrl;

  // New base fields
  final GeoPoint? location;
  final String? address;
  final String? language;
  final double rating;
  final int reviewCount;
  final bool isBanned;
  final bool notificationsEnabled;
  final bool profileCompleted;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.userType,
    this.createdAt,
    this.photoUrl,
    this.location,
    this.address,
    this.language,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isBanned = false,
    this.notificationsEnabled = true,
    this.profileCompleted = true,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) throw Exception("Document does not exist");
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(doc.id, data);
  }

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      userType: parseUserType(
        data['accountType'] ?? data['userType'] ?? 'client',
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      photoUrl: data['profilePicture'] ?? data['photoUrl'],
      location: data['location'] as GeoPoint?,
      address: data['address'],
      language: data['language'],
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      isBanned: data['isBanned'] ?? false,
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      profileCompleted:
          data['profileComplete'] ?? data['profileCompleted'] ?? false,
    );
  }

  static UserType parseUserType(String type) {
    switch (type) {
      case 'workProvider':
      case 'provider':
      case 'serviceProvider':
        return UserType.workProvider;
      case 'marketplace':
      case 'merchant':
      case 'business':
        return UserType.marketplace;
      case 'client':
      default:
        return UserType.client;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': id, // Keeping for backward compatibility temporarily
      'accountType': userType.name,
      'email': email,
      'name': name,
      'phone': phone,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'profilePicture': photoUrl,
      'location': location,
      'address': address,
      'language': language,
      'rating': rating,
      'reviewCount': reviewCount,
      'isBanned': isBanned,
      'notificationsEnabled': notificationsEnabled,
      'profileComplete': profileCompleted,
      'profileCompleted': profileCompleted,
    };
  }
}
