import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String reviewerId;
  final String reviewerName;
  final String reviewerPhoto;
  final double rating;
  final String text;
  final DateTime createdAt;
  final String? response;

  ReviewModel({
    required this.id,
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewerPhoto,
    required this.rating,
    required this.text,
    required this.createdAt,
    this.response,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      reviewerId: data['reviewerId'] ?? data['fromId'] ?? '',
      reviewerName: data['reviewerName'] ?? data['fromName'] ?? 'Anonymous',
      reviewerPhoto: data['reviewerPhoto'] ?? data['fromPhotoUrl'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      text: data['text'] ?? data['comment'] ?? data['reviewText'] ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
          (data['timestamp'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      response: data['response'],
    );
  }

  Map<String, dynamic> toJson() => {
    'reviewerId': reviewerId,
    'reviewerName': reviewerName,
    'reviewerPhoto': reviewerPhoto,
    'rating': rating,
    'text': text,
    'createdAt': Timestamp.fromDate(createdAt),
    'response': response,
  };
}
