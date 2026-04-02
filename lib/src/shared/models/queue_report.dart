import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:queue/src/shared/models/queue_level.dart';

class QueueReport {
  const QueueReport({
    required this.id,
    required this.placeId,
    required this.userId,
    required this.queueLevel,
    required this.timestamp,
    this.imageUrl,
    this.storagePath,
    this.placeName,
  });

  final String id;
  final String placeId;
  final String userId;
  final QueueLevel queueLevel;
  final DateTime timestamp;
  final String? imageUrl;
  final String? storagePath;
  final String? placeName;

  factory QueueReport.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return QueueReport(
      id: doc.id,
      placeId: data['placeId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      queueLevel: QueueLevel.fromValue(data['queueLevel'] as String? ?? ''),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'] as String?,
      storagePath: data['storagePath'] as String?,
      placeName: data['placeName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'placeId': placeId,
      'userId': userId,
      'queueLevel': queueLevel.value,
      'timestamp': Timestamp.fromDate(timestamp),
      'imageUrl': imageUrl,
      'storagePath': storagePath,
      'placeName': placeName,
    };
  }

  QueueReport copyWith({
    String? id,
    String? placeId,
    String? userId,
    QueueLevel? queueLevel,
    DateTime? timestamp,
    String? imageUrl,
    String? storagePath,
    String? placeName,
  }) {
    return QueueReport(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      userId: userId ?? this.userId,
      queueLevel: queueLevel ?? this.queueLevel,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      storagePath: storagePath ?? this.storagePath,
      placeName: placeName ?? this.placeName,
    );
  }
}
