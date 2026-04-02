import 'package:queue/src/shared/models/place.dart';
import 'package:queue/src/shared/models/queue_level.dart';
import 'package:queue/src/shared/models/queue_report.dart';

class PlaceQueueSummary {
  const PlaceQueueSummary({
    required this.place,
    required this.queueLevel,
    required this.estimatedMinutes,
    required this.lastUpdated,
    required this.reportCount,
    this.distanceKm,
  });

  final Place place;
  final QueueLevel queueLevel;
  final int estimatedMinutes;
  final DateTime? lastUpdated;
  final int reportCount;
  final double? distanceKm;

  bool get hasRecentReports => reportCount > 0 && lastUpdated != null;
  String get crowdLevel {
    if (reportCount >= 6) return 'High';
    if (reportCount >= 3) return 'Medium';
    return 'Low';
  }

  factory PlaceQueueSummary.fromReports({
    required Place place,
    required List<QueueReport> reports,
  }) {
    if (reports.isEmpty) {
      return PlaceQueueSummary(
        place: place,
        queueLevel: QueueLevel.short,
        estimatedMinutes: 3,
        lastUpdated: null,
        reportCount: 0,
        distanceKm: null,
      );
    }

    final totalMinutes = reports.fold<int>(
      0,
      (sum, report) => sum + report.queueLevel.minutes,
    );
    final averageMinutes = (totalMinutes / reports.length).round();
    final latest = reports
        .map((report) => report.timestamp)
        .reduce((value, element) => value.isAfter(element) ? value : element);

    return PlaceQueueSummary(
      place: place,
      queueLevel: QueueLevel.fromMinutes(averageMinutes),
      estimatedMinutes: averageMinutes,
      lastUpdated: latest,
      reportCount: reports.length,
      distanceKm: null,
    );
  }

  PlaceQueueSummary copyWith({
    Place? place,
    QueueLevel? queueLevel,
    int? estimatedMinutes,
    DateTime? lastUpdated,
    int? reportCount,
    double? distanceKm,
  }) {
    return PlaceQueueSummary(
      place: place ?? this.place,
      queueLevel: queueLevel ?? this.queueLevel,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      reportCount: reportCount ?? this.reportCount,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}
