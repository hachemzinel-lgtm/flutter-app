import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType {
  client,
  serviceProvider,
  marketplace;

  String get displayName {
    switch (this) {
      case UserType.client:
        return 'Looking for Services';
      case UserType.serviceProvider:
        return 'Service Provider';
      case UserType.marketplace:
        return 'Marketplace/Shop';
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

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.userType,
    this.createdAt,
    this.photoUrl,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: (data['email'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      userType: parseUserType(
          (data['userType'] ?? data['accountType'] ?? 'client').toString()),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      photoUrl: data['photoUrl'] as String?,
    );
  }

  static UserType parseUserType(String type) {
    switch (type) {
      case 'provider':
      case 'serviceProvider':
        return UserType.serviceProvider;
      case 'merchant':
      case 'marketplace':
        return UserType.marketplace;
      case 'client':
      default:
        return UserType.client;
    }
  }

  /// JSON for Firestore writes.
  ///
  /// IMPORTANT: this is intended for the FIRST write of a user document.
  /// When [createdAt] is null we use a server timestamp; when present (i.e.
  /// we round-tripped from Firestore) we preserve the original value.
  ///
  /// For subsequent profile edits, prefer a scoped `.update({...})` rather
  /// than re-calling `.toJson()`, so you don't risk overwriting
  /// immutable metadata.
  Map<String, dynamic> toJson() {
    return {
      'uid': id,
      'email': email,
      'name': name,
      'phone': phone,
      'userType': userType.name,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }
}
