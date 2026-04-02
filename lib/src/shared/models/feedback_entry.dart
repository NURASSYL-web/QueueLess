import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackEntry {
  const FeedbackEntry({
    required this.id,
    required this.userId,
    required this.email,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String email;
  final int rating;
  final String comment;
  final DateTime createdAt;

  factory FeedbackEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return FeedbackEntry(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      email: data['email'] as String? ?? '',
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      comment: data['comment'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
