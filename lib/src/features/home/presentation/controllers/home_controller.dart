import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:queue/src/core/constants/app_constants.dart';
import 'package:queue/src/core/location/location_service.dart';
import 'package:queue/src/shared/models/place_category.dart';
import 'package:queue/src/shared/models/place_queue_summary.dart';
import 'package:queue/src/shared/models/queue_level.dart';

enum DistanceFilter {
  any('Any'),
  underOneKm('<1km'),
  oneToFiveKm('1-5km'),
  fivePlusKm('5km+');

  const DistanceFilter(this.label);
  final String label;
}

class HomeController extends ChangeNotifier {
  HomeController(this._locationService);

  final LocationService _locationService;

  PlaceCategory? _selectedCategory;
  bool _recentlyUpdatedOnly = false;
  QueueLevel? _queueFilter;
  DistanceFilter _distanceFilter = DistanceFilter.any;
  bool _showListView = false;
  Position? _userPosition;

  PlaceCategory? get selectedCategory => _selectedCategory;
  bool get recentlyUpdatedOnly => _recentlyUpdatedOnly;
  QueueLevel? get queueFilter => _queueFilter;
  DistanceFilter get distanceFilter => _distanceFilter;
  bool get showListView => _showListView;
  Position? get userPosition => _userPosition;

  Future<void> loadUserLocation() async {
    _userPosition ??= await _locationService.getCurrentPosition();
    notifyListeners();
  }

  void selectCategory(PlaceCategory? value) {
    _selectedCategory = value;
    notifyListeners();
  }

  void selectQueueFilter(QueueLevel? value) {
    _queueFilter = value;
    notifyListeners();
  }

  void toggleRecentlyUpdated(bool value) {
    _recentlyUpdatedOnly = value;
    notifyListeners();
  }

  Future<void> selectDistanceFilter(DistanceFilter value) async {
    _distanceFilter = value;
    if (value != DistanceFilter.any && _userPosition == null) {
      try {
        _userPosition = await _locationService.getCurrentPosition();
      } catch (_) {
        // Keep the selected distance filter, but don't hide all places
        // when location isn't available yet.
      }
    }
    notifyListeners();
  }

  void setViewMode(bool listView) {
    _showListView = listView;
    notifyListeners();
  }

  List<PlaceQueueSummary> enrichAndFilter(List<PlaceQueueSummary> summaries) {
    final now = DateTime.now();

    final enriched = summaries.map((summary) {
      if (_userPosition == null) {
        return summary;
      }

      final distanceKm = _locationService.distanceKm(
        fromLatitude: _userPosition!.latitude,
        fromLongitude: _userPosition!.longitude,
        toLatitude: summary.place.latitude,
        toLongitude: summary.place.longitude,
      );
      final travelMinutes = _locationService.estimateTravelMinutes(
        distanceKm: distanceKm,
      );

      return summary.copyWith(
        distanceKm: distanceKm,
        travelMinutes: travelMinutes,
      );
    }).toList();

    return enriched.where((summary) {
      final categoryMatches =
          _selectedCategory == null ||
          summary.place.category == _selectedCategory;

      final queueMatches =
          _queueFilter == null || summary.queueLevel == _queueFilter;

      final recentMatches =
          !_recentlyUpdatedOnly ||
          (summary.lastUpdated != null &&
              now.difference(summary.lastUpdated!) <=
                  AppConstants.reportWindow);

      final distance = summary.distanceKm;
      final distanceMatches = switch (_distanceFilter) {
        DistanceFilter.any => true,
        _ when _userPosition == null => true,
        DistanceFilter.underOneKm => distance != null && distance < 1,
        DistanceFilter.oneToFiveKm =>
          distance != null && distance >= 1 && distance <= 5,
        DistanceFilter.fivePlusKm => distance != null && distance > 5,
      };

      return categoryMatches &&
          queueMatches &&
          recentMatches &&
          distanceMatches;
    }).toList();
  }
}
