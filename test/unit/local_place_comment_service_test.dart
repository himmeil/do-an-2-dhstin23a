import 'dart:convert';

import 'package:diadiem_quanh_day/features/dia_diem/services/local_place_comment_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'local comment request authenticates and trims submitted content',
    () async {
      final service = LocalPlaceCommentService(
        apiBaseUrl: 'http://localhost:8787/',
        getIdToken: () async => 'signed-in-token',
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/places/place%2F1/comments');
          expect(request.headers['Authorization'], 'Bearer signed-in-token');
          expect(jsonDecode(request.body), {'content': 'A good place.'});
          return http.Response('{"id":1}', 201);
        }),
      );

      await service.add(
        placeId: 'place/1',
        accountName: 'user@example.com',
        content: '  A good place.  ',
      );
    },
  );

  test(
    'local comment request rejects blank content before network access',
    () async {
      var requested = false;
      final service = LocalPlaceCommentService(
        apiBaseUrl: 'http://localhost:8787',
        getIdToken: () async => 'signed-in-token',
        client: MockClient((_) async {
          requested = true;
          return http.Response('{}', 201);
        }),
      );

      await expectLater(
        service.add(
          placeId: 'place-1',
          accountName: 'user@example.com',
          content: '  ',
        ),
        throwsArgumentError,
      );
      expect(requested, isFalse);
    },
  );
}
