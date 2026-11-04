import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../du_lieu/models/place.dart';
import '../du_lieu/repositories/place_repository.dart';

class LocalPlaceService implements PlaceService {
  factory LocalPlaceService({
    SharedPreferences? prefs,
    String storageKey = LocalPlaceService.storageKey,
  }) => LocalPlaceService._(prefs, storageKey);

  LocalPlaceService._(this._prefs, this._storageKey);

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
      return const [];
    }
  }

  @override
  Stream<List<Place>> watchAll() async* {
    yield await _load();
    yield* _changes.stream.asyncMap((_) => _load());
  }

  @override
  Future<int> importAll(List<Place> places) async {
    final byId = {for (final place in await _load()) place.id: place};
    for (final place in places) {
      byId[place.id] = place;
    }
    final encoded = jsonEncode([
      for (final place in byId.values) {'id': place.id, ...place.toMap()},
    ]);
    await (await _store).setString(_storageKey, encoded);
    _changes.add(null);
    return places.length;
  }
}
