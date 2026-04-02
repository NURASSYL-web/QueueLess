import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:queue/src/shared/models/place.dart';

class FirestorePlacesRepository {
  FirestorePlacesRepository(this._firestore);

  final FirebaseFirestore _firestore;
  CollectionReference<Map<String, dynamic>> get _places =>
      _firestore.collection('places');

  Stream<List<Place>> watchPlaces() {
    return _places
        .orderBy('name')
        .withConverter<Place>(
          fromFirestore: (snapshot, _) => Place.fromFirestore(snapshot),
          toFirestore: (place, _) => place.toMap(),
        )
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<Place>> watchOwnerPlaces(String ownerId) {
    return _places
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .withConverter<Place>(
          fromFirestore: (snapshot, _) => Place.fromFirestore(snapshot),
          toFirestore: (place, _) => place.toMap(),
        )
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> createPlace(Place place) {
    return _places.doc(place.id).set(place.toMap());
  }

  Future<void> updatePlace(Place place) {
    return _places.doc(place.id).update(place.toMap());
  }
}
