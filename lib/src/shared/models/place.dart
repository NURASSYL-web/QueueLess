import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:queue/src/shared/models/place_category.dart';

class Place {
  const Place({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.instagram,
    required this.createdAt,
    this.imageUrl,
  });

  final String id;
  final String ownerId;
  final String name;
  final PlaceCategory category;
  final double latitude;
  final double longitude;
  final String phone;
  final String instagram;
  final DateTime createdAt;
  final String? imageUrl;

  LatLng get latLng => LatLng(latitude, longitude);

  factory Place.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Place(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      category: PlaceCategory.fromValue(data['category'] as String? ?? ''),
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      phone: data['phone'] as String? ?? '',
      instagram: data['instagram'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerId': ownerId,
      'category': category.value,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'instagram': instagram,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrl': imageUrl,
    };
  }

  Place copyWith({
    String? id,
    String? ownerId,
    String? name,
    PlaceCategory? category,
    double? latitude,
    double? longitude,
    String? phone,
    String? instagram,
    DateTime? createdAt,
    String? imageUrl,
  }) {
    return Place(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      instagram: instagram ?? this.instagram,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
