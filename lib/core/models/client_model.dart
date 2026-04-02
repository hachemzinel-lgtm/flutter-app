import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class ClientModel extends UserModel {
  ClientModel({
    required super.id,
    required super.email,
    required super.name,
    required super.phone,
    super.photoUrl,
    super.createdAt,
    super.location,
    super.address,
    super.language,
    super.rating,
    super.reviewCount,
    super.isBanned,
    super.notificationsEnabled,
    super.profileCompleted,
  }) : super(userType: UserType.client);

  factory ClientModel.fromMap(String id, Map<String, dynamic> data) {
    return ClientModel(
      id: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      photoUrl: data['profilePicture'] ?? data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      location: data['location'] as GeoPoint?,
      address: data['address'],
      language: data['language'],
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      isBanned: data['isBanned'] ?? false,
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      profileCompleted: data['profileCompleted'] ?? true,
    );
  }
}
