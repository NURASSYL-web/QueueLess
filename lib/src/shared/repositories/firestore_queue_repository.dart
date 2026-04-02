import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:queue/src/core/constants/app_constants.dart';
import 'package:queue/src/shared/models/place.dart';
import 'package:queue/src/shared/models/place_queue_summary.dart';
import 'package:queue/src/shared/models/queue_level.dart';
import 'package:queue/src/shared/models/queue_report.dart';

class FirestoreQueueRepository {
  FirestoreQueueRepository(this._firestore);

  final FirebaseFirestore _firestore;
  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('queue_reports');

  Stream<List<PlaceQueueSummary>> watchDashboard(List<Place> places) {
    final controller = StreamController<List<PlaceQueueSummary>>();
    List<QueueReport> cachedReports = const [];

    void emit() {
      final now = DateTime.now();
      final windowStart = now.subtract(AppConstants.reportWindow);

      final recentReports = cachedReports
          .where((report) => !report.timestamp.isBefore(windowStart))
          .toList();

      final summaries = places.map((place) {
        final placeReports = recentReports
            .where((report) => report.placeId == place.id)
            .toList();
        return PlaceQueueSummary.fromReports(
          place: place,
          reports: placeReports,
        );
      }).toList();

      controller.add(summaries);
    }

    final reportSubscription = _reports
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(
            DateTime.now().subtract(AppConstants.reportQueryWindow),
          ),
        )
        .orderBy('timestamp', descending: true)
        .withConverter<QueueReport>(
          fromFirestore: (snapshot, _) => QueueReport.fromFirestore(snapshot),
          toFirestore: (report, _) => report.toMap(),
        )
        .snapshots()
        .listen((snapshot) {
          cachedReports = snapshot.docs.map((doc) => doc.data()).toList();
          emit();
        });

    final timer = Timer.periodic(AppConstants.dashboardRefreshInterval, (_) {
      emit();
    });

    controller.onCancel = () async {
      timer.cancel();
      await reportSubscription.cancel();
    };

    emit();
    return controller.stream;
  }

  Future<void> submitQueueReport({
    required String placeId,
    required String userId,
    required QueueLevel level,
    required String placeName,
    String? imageUrl,
    String? storagePath,
  }) async {
    await _reports.add(
      QueueReport(
        id: '',
        placeId: placeId,
        userId: userId,
        queueLevel: level,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
        storagePath: storagePath,
        placeName: placeName,
      ).toMap(),
    );
  }

  Future<String> createQueueReportDraft({
    required String placeId,
    required String userId,
    required QueueLevel level,
    required String placeName,
  }) async {
    final doc = await _reports.add(
      QueueReport(
        id: '',
        placeId: placeId,
        userId: userId,
        queueLevel: level,
        timestamp: DateTime.now(),
        placeName: placeName,
      ).toMap(),
    );
    return doc.id;
  }

  Future<void> attachImageToReport({
    required String reportId,
    required String imageUrl,
    required String storagePath,
  }) {
    return _reports.doc(reportId).update({
      'imageUrl': imageUrl,
      'storagePath': storagePath,
    });
  }

  Stream<List<QueueReport>> watchUserReports(String userId) {
    return _reports
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .withConverter<QueueReport>(
          fromFirestore: (snapshot, _) => QueueReport.fromFirestore(snapshot),
          toFirestore: (report, _) => report.toMap(),
        )
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<QueueReport>> watchPlaceReports(String placeId, {int limit = 20}) {
    return _reports
        .where('placeId', isEqualTo: placeId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .withConverter<QueueReport>(
          fromFirestore: (snapshot, _) => QueueReport.fromFirestore(snapshot),
          toFirestore: (report, _) => report.toMap(),
        )
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> updateQueueReportLevel({
    required String reportId,
    required QueueLevel level,
  }) {
    return _reports.doc(reportId).update({
      'queueLevel': level.value,
      'timestamp': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteQueueReport(String reportId) {
    return _reports.doc(reportId).delete();
  }
}
