import 'package:diadiem_quanh_day/features/dia_diem/chi_tiet/widgets/place_comments_section.dart';
import 'package:diadiem_quanh_day/features/dia_diem/du_lieu/models/place_comment.dart';
import 'package:diadiem_quanh_day/features/dia_diem/du_lieu/repositories/place_comment_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePlaceCommentService implements PlaceCommentService {
  final comments = <PlaceComment>[
    PlaceComment(
      id: 'existing',
      accountName: 'student@example.com',
      content: 'Nơi này phù hợp học nhóm.',
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  @override
  Stream<List<PlaceComment>> watchForPlace(String placeId) =>
      Stream.value(List.unmodifiable(comments));

  @override
  Future<void> add({
    required String placeId,
    required String accountName,
    required String content,
  }) async {
    comments.insert(
      0,
      PlaceComment(
        id: 'new',
        accountName: accountName,
        content: content,
        createdAt: DateTime(2026, 1, 2),
      ),
    );
  }
}

void main() {
  testWidgets('guest reads comments but must sign in before writing', (
    tester,
  ) async {
    var signInRequested = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaceCommentsSection(
            placeId: 'place-1',
            service: _FakePlaceCommentService(),
            isSignedIn: false,
            accountName: '',
            onRequireSignIn: () => signInRequested = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nơi này phù hợp học nhóm.'), findsOneWidget);
    expect(find.text('Viết bình luận'), findsNothing);
    await tester.tap(find.text('Đăng nhập'));
    expect(signInRequested, isTrue);
  });

  testWidgets('signed-in user can post a bounded comment', (tester) async {
    final service = _FakePlaceCommentService();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaceCommentsSection(
            placeId: 'place-1',
            service: service,
            isSignedIn: true,
            accountName: 'writer@example.com',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '  Thử bình luận  ');
    await tester.tap(find.text('Gửi bình luận'));
    await tester.pumpAndSettle();

    expect(service.comments.first.accountName, 'writer@example.com');
    expect(service.comments.first.content, 'Thử bình luận');
    expect(find.text('Thử bình luận'), findsOneWidget);
  });
}
