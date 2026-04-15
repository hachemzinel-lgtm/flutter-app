import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/models/user_model.dart';

class MarketplaceModel extends UserModel {
  final String? businessName;
  final String? category;
  @override
  final String? description;
  final Map<String, dynamic>? openingHours;
  final List<String> photos;

  MarketplaceModel({
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
    this.businessName,
    this.category,
    this.description,
    this.openingHours,
    this.photos = const [],
  }) : super(userType: UserType.marketplace);

  factory MarketplaceModel.fromMap(String id, Map<String, dynamic> data) {
    return MarketplaceModel(
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
      profileCompleted: data['profileComplete'] ?? false,
      businessName: data['businessName'],
      category: data['category'],
      description: data['description'] ?? data['bio'], // Fallback if old code
      openingHours: data['openingHours'],
      photos:
          (data['photos'] as List<dynamic>?)
              ?.map((p) => p.toString())
              .toList() ??
          [],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final base = super.toJson();
    base.addAll({
      'businessName': businessName,
      'category': category,
      'description': description,
      'openingHours': openingHours,
      'photos': photos,
    });
    return base;
  }
}
