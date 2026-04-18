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
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      userType: parseUserType(data['userType'] ?? data['accountType'] ?? 'client'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      photoUrl: data['photoUrl'],
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

  Map<String, dynamic> toJson() {
    return {
      'uid': id,
      'email': email,
      'name': name,
      'phone': phone,
      'userType': userType.name,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'photoUrl': photoUrl,
    };
  }
}
