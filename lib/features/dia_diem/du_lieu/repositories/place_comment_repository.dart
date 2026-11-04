import '../models/place_comment.dart';

abstract interface class PlaceCommentService {
  Stream<List<PlaceComment>> watchForPlace(String placeId);

  Future<void> add({
    required String placeId,
    required String accountName,
    required String content,
  });
}
