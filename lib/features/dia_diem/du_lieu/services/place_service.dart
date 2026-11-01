import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/place.dart';

/// Đọc và nạp dữ liệu địa điểm. Giao diện chỉ đi qua lớp này.
abstract interface class PlaceService {
  /// Toàn bộ địa điểm, tự cập nhật khi dữ liệu đổi.
  Stream<List<Place>> watchAll();

  /// Lưu các địa điểm (cùng tên + tọa độ thì ghi đè, không nhân đôi).
  /// Trả về số địa điểm đã lưu.
  Future<int> importAll(List<Place> places);
}

/// Lưu ngay trên máy (localStorage khi chạy web, SharedPreferences trên
/// Android/iOS). Không có máy chủ, không dùng tài khoản, không gửi dữ liệu đi đâu.
class LocalPlaceService implements PlaceService {
  LocalPlaceService({
    this._prefs,
    this._storageKey = LocalPlaceService.storageKey,
  });

  static const storageKey = 'places_v1';
  static const adminDraftStorageKey = 'admin_place_drafts_v1';

  SharedPreferences? _prefs;
  final String _storageKey;
  final _changes = StreamController<void>.broadcast();

  Future<SharedPreferences> get _store async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<List<Place>> _load() async {
    final raw = (await _store).getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map<String, dynamic>)
            Place.fromMap('${item['id']}', item),
      ];
    } catch (_) {
      return const []; // dữ liệu hỏng thì coi như trống, không làm app sập
    }
  }

  @override
  Stream<List<Place>> watchAll() async* {
    yield await _load();
    yield* _changes.stream.asyncMap((_) => _load());
  }

  @override
  Future<int> importAll(List<Place> places) async {
    final byId = {for (final p in await _load()) p.id: p};
    for (final p in places) {
      byId[p.id] = p;
    }
    final encoded = jsonEncode([
      for (final p in byId.values) {'id': p.id, ...p.toMap()},
    ]);
    await (await _store).setString(_storageKey, encoded);
    _changes.add(null);
    return places.length;
  }
}

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

class FirestoreFavoriteService {
  FirestoreFavoriteService({required this.userId, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final String userId;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _favorites =>
      _firestore.collection('users').doc(userId).collection('favorites');

  Stream<Set<String>> watchIds() => _favorites.snapshots().map(
    (snapshot) => snapshot.docs.map((document) => document.id).toSet(),
  );

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
