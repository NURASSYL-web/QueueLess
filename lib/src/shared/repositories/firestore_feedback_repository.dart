import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:queue/src/shared/models/feedback_entry.dart';

class FirestoreFeedbackRepository {
  FirestoreFeedbackRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<FeedbackEntry>> watchLatestFeedback({int limit = 10}) {
    return _firestore
        .collection('feedback_entries')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .withConverter<FeedbackEntry>(
          fromFirestore: (snapshot, _) => FeedbackEntry.fromFirestore(snapshot),
          toFirestore: (entry, _) => entry.toMap(),
        )
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> submitFeedback(FeedbackEntry entry) async {
    await _firestore.collection('feedback_entries').add(entry.toMap());
  }
}
