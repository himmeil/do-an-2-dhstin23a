import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../du_lieu/models/place_comment.dart';
import '../du_lieu/repositories/place_comment_repository.dart';

class LocalPlaceCommentService implements PlaceCommentService {
  LocalPlaceCommentService({
    required String apiBaseUrl,
    required this.getIdToken,
    http.Client? client,
  }) : _apiBaseUrl = apiBaseUrl.replaceAll(RegExp(r'/$'), ''),
       _client = client ?? http.Client();

  final String _apiBaseUrl;
  final Future<String?> Function() getIdToken;
  final http.Client _client;

  Uri _commentsUri(String placeId) => Uri.parse(
    '$_apiBaseUrl/api/places/${Uri.encodeComponent(placeId)}/comments',
  );

  @override
  Stream<List<PlaceComment>> watchForPlace(String placeId) async* {
    final response = await _client
        .get(_commentsUri(placeId))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Không tải được bình luận (${response.statusCode}).');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map || decoded['comments'] is! List) {
      throw const FormatException('Danh sách bình luận không hợp lệ.');
    }
    yield [
      for (final value in decoded['comments'] as List)
        if (value is Map)
          PlaceComment(
            id: '${value['id'] ?? ''}',
            accountName: '${value['accountName'] ?? ''}',
            content: '${value['content'] ?? ''}',
            createdAt: DateTime.tryParse('${value['createdAt'] ?? ''}'),
          ),
    ];
  }

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
    final token = await getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Đăng nhập trước khi gửi bình luận.');
    }
    final response = await _client
        .post(
          _commentsUri(placeId),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'content': normalizedContent}),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 201) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final message = decoded is Map && decoded['error'] is String
          ? decoded['error'] as String
          : 'Không gửi được bình luận (${response.statusCode}).';
      throw Exception(message);
    }
  }
}
