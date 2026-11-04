import '../models/place.dart';

abstract interface class PlaceService {
  Stream<List<Place>> watchAll();

  Future<int> importAll(List<Place> places);
}

abstract interface class FavoriteService {
  Stream<Set<String>> watchIds();

  Future<void> setFavorite(String placeId, {required bool favorite});
}
