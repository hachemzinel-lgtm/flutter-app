import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/models/user_model.dart';

class ServicePrice {
  final String name;
  final double price;

  ServicePrice({required this.name, required this.price});

  factory ServicePrice.fromMap(Map<String, dynamic> data) {
    return ServicePrice(
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'price': price};
  }
}

class WorkProviderModel extends UserModel {
  final String? profession;
  @override final int? yearsExperience;
  @override final String? bio;
  final double? hourlyRate;
  final List<ServicePrice> services;
  final bool isAvailableNow;
  final Map<String, String>?
  documents; // { 'diplomaURL': '...', 'idURL': '...' }
  final String verificationStatus; // 'pending' | 'approved' | 'rejected'
  final String? verificationReason;
  final bool customQuoteEnabled;
  final List<String> portfolio;

  WorkProviderModel({
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
    this.profession,
    this.yearsExperience,
    this.bio,
    this.hourlyRate,
    this.services = const [],
    this.isAvailableNow = false,
    this.documents,
    this.verificationStatus = 'pending',
    this.verificationReason,
    this.customQuoteEnabled = false,
    this.portfolio = const [],
  }) : super(userType: UserType.workProvider);

  factory WorkProviderModel.fromMap(String id, Map<String, dynamic> data) {
    return WorkProviderModel(
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
      profileCompleted:
          data['profileComplete'] ?? data['profileCompleted'] ?? false,
      profession: data['profession'],
      yearsExperience: data['yearsExperience'],
      bio: data['bio'],
      hourlyRate: data['hourlyRate'] != null
          ? (data['hourlyRate'] as num).toDouble()
          : null,
      services:
          (data['services'] as List<dynamic>?)
              ?.map((s) => ServicePrice.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      isAvailableNow: data['isAvailableNow'] ?? false,
      documents: data['documents'] != null
          ? Map<String, String>.from(data['documents'])
          : null,
      verificationStatus: data['verificationStatus'] ?? 'pending',
      verificationReason: data['verificationReason'],
      customQuoteEnabled: data['customQuoteEnabled'] ?? false,
      portfolio:
          (data['portfolio'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final base = super.toJson();
    base.addAll({
      'profession': profession,
      'yearsExperience': yearsExperience,
      'bio': bio,
      'hourlyRate': hourlyRate,
      'services': services.map((s) => s.toJson()).toList(),
      'isAvailableNow': isAvailableNow,
      'documents': documents,
      'verificationStatus': verificationStatus,
      'verificationReason': verificationReason,
      'customQuoteEnabled': customQuoteEnabled,
      'portfolio': portfolio,
      'isVerified': verificationStatus == VerificationStatus.approved.name,
    });
    return base;
  }
}
