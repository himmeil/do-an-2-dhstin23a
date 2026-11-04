import 'package:cloud_firestore/cloud_firestore.dart';

import '../du_lieu/models/place_comment.dart';
import '../du_lieu/repositories/place_comment_repository.dart';

class FirestorePlaceCommentService implements PlaceCommentService {
  FirestorePlaceCommentService({this.userId, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final String? userId;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _comments(String placeId) =>
      _firestore.collection('places').doc(placeId).collection('comments');

  @override
  Stream<List<PlaceComment>> watchForPlace(String placeId) => _comments(placeId)
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map(
        (snapshot) => [
          for (final document in snapshot.docs)
            PlaceComment(
              id: document.id,
              accountName: document.data()['accountName'] as String? ?? '',
              content: document.data()['content'] as String? ?? '',
              createdAt: (document.data()['createdAt'] as Timestamp?)?.toDate(),
            ),
        ],
      );

  @override
  Future<void> add({
    required String placeId,
    required String accountName,
    required String content,
  }) async {
    final normalizedContent = content.trim();
    if (normalizedContent.isEmpty || normalizedContent.length > 1000) {
      throw ArgumentError.value(
        content,
        'content',
        'Bình luận phải từ 1-1000 ký tự.',
      );
    }
    if (accountName.trim().isEmpty) {
      throw StateError('Tài khoản chưa có email để ghi tên người bình luận.');
    }
    final authorId = userId;
    if (authorId == null || authorId.isEmpty) {
      throw StateError('Đăng nhập trước khi gửi bình luận.');
    }
    await _comments(placeId).add({
      'userId': authorId,
      'accountName': accountName.trim(),
      'content': normalizedContent,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
