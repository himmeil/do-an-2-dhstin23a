import 'package:cloud_firestore/cloud_firestore.dart';

import '../du_lieu/models/place.dart';
import '../du_lieu/repositories/place_repository.dart';

class FirestorePlaceService implements PlaceService {
  FirestorePlaceService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _places =>
      _firestore.collection('places');

  @override
  Stream<List<Place>> watchAll() => _places
      .orderBy('name')
      .snapshots()
      .map((snapshot) => snapshot.docs.map(_fromDocument).toList());

  Place _fromDocument(QueryDocumentSnapshot<Map<String, dynamic>> document) =>
      Place.fromMap(document.id, document.data());

  @override
  Future<int> importAll(List<Place> places) async {
    for (var start = 0; start < places.length; start += 450) {
      final batch = _firestore.batch();
      final end = (start + 450 < places.length) ? start + 450 : places.length;
      for (final place in places.sublist(start, end)) {
        batch.set(_places.doc(place.id), place.toMap());
      }
      await batch.commit();
    }
    return places.length;
  }
}

class FirestoreFavoriteService implements FavoriteService {
  FirestoreFavoriteService({required this.userId, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final String userId;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _favorites =>
      _firestore.collection('users').doc(userId).collection('favorites');

  @override
  Stream<Set<String>> watchIds() => _favorites.snapshots().map(
    (snapshot) => snapshot.docs.map((document) => document.id).toSet(),
  );

  @override
  Future<void> setFavorite(String placeId, {required bool favorite}) async {
    final reference = _favorites.doc(placeId);
    if (favorite) {
      await reference.set({
        'placeId': placeId,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await reference.delete();
    }
  }
}
