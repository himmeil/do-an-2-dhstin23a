import 'package:diadiem_quanh_day/features/mini_game/screens/cao_lanh_quiz_screen.dart';
import 'package:diadiem_quanh_day/features/mini_game/screens/cao_lanh_shop_screen.dart';
import 'package:diadiem_quanh_day/features/mini_game/services/quiz_audio_service.dart';
import 'package:diadiem_quanh_day/features/mini_game/services/quiz_progress_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryProgressRepository implements QuizProgressRepository {
  _MemoryProgressRepository(this.progress);

  QuizShopProgress progress;

  @override
  Future<QuizShopProgress> load() async => progress;

  @override
  Future<void> save(QuizShopProgress progress) async {
    this.progress = progress;
  }
}

class _RecordingAudioService implements QuizAudioService {
  final sounds = <QuizSound>[];

  @override
  Future<void> play(QuizSound sound) async => sounds.add(sound);

  @override
  void dispose() {}
}

Future<void> _pumpQuizAnimations(
  WidgetTester tester, {
  Duration duration = const Duration(milliseconds: 100),
}) async {
  await tester.pump();
  await tester.pump(duration);
}

void main() {
  test('lưu xu, đồ sở hữu và cài đặt âm thanh ở local', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = LocalQuizProgressRepository();
    final initial = await repository.load();
    expect(initial.coins, 100);

    await repository.save(
      initial.copyWith(
        coins: 40,
        ownedItemIds: {'school_uniform'},
        equippedOutfitId: 'school_uniform',
        soundEnabled: false,
      ),
    );
    final restored = await repository.load();

    expect(restored.coins, 40);
    expect(restored.ownedItemIds, contains('school_uniform'));
    expect(restored.equippedOutfitId, 'school_uniform');
    expect(restored.soundEnabled, isFalse);
  });

  testWidgets('hoàn thành thử thách và có thể chơi lại', (tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _MemoryProgressRepository(
      QuizShopProgress.initial().copyWith(
        ownedItemIds: {'school_uniform'},
        equippedOutfitId: 'school_uniform',
      ),
    );
    final audio = _RecordingAudioService();
    await tester.pumpWidget(
      MaterialApp(
        home: CaoLanhQuizScreen(
          progressRepository: repository,
          audioService: audio,
        ),
      ),
    );
    await _pumpQuizAnimations(tester);

    expect(find.text('Thử thách Cao Lãnh'), findsOneWidget);
    expect(find.text('THẦY GIÁO'), findsOneWidget);
    expect(find.byKey(const ValueKey('teacher-idle-frame-0')), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName.startsWith(
              'assets/mini_game/characters/lotus/idle/school_uniform/',
            ),
      ),
      findsOneWidget,
    );

    const correctAnswers = [
      'Đồng Tháp',
      'Hoa sen',
      'Đồng bằng sông Cửu Long',
      'Cao Lãnh',
      'Xoài',
    ];
    const correctIndexes = [1, 0, 2, 0, 1];

    for (
      var questionIndex = 0;
      questionIndex < correctAnswers.length;
      questionIndex++
    ) {
      final answer = correctAnswers[questionIndex];
      final answerFinder = find.text(answer);
      await tester.ensureVisible(answerFinder);
      await tester.tap(answerFinder);
      await _pumpQuizAnimations(tester);
      expect(find.textContaining('Chính xác!'), findsOneWidget);
      expect(
        find.byKey(
          ValueKey(
            'teacher-answer-action-$questionIndex-'
            '${correctIndexes[questionIndex]}',
          ),
        ),
        findsOneWidget,
      );

      final nextFinder = find.text(
        answer == correctAnswers.last ? 'Xem kết quả' : 'Câu tiếp theo',
      );
      await tester.ensureVisible(nextFinder);
      await tester.tap(nextFinder);
      await _pumpQuizAnimations(tester);
    }

    expect(find.text('Hoàn thành thử thách!'), findsOneWidget);
    expect(find.text('5/5 điểm'), findsOneWidget);
    expect(find.text('Chơi lại'), findsOneWidget);
    expect(find.text('Thầy dẫn bạn đến rương kho báu!'), findsOneWidget);
    expect(repository.progress.coins, 170);
    expect(audio.sounds.where((sound) => sound == QuizSound.correct).length, 5);

    await tester.tap(find.byKey(const ValueKey('treasure-chest-button')));
    await tester.pump();
    expect(find.text('Đã mở!'), findsOneWidget);
    expect(find.byKey(const ValueKey('treasure-chest-open')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(find.text('Chơi lại'));
    await _pumpQuizAnimations(tester);
    expect(find.text('1/5'), findsOneWidget);
    expect(find.text('Cao Lãnh gắn liền với tỉnh nào?'), findsOneWidget);
  });

  testWidgets('có thể mua và trang bị quần áo bằng xu ảo', (tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _MemoryProgressRepository(
      QuizShopProgress.initial().copyWith(coins: 200),
    );
    final audio = _RecordingAudioService();
    await tester.pumpWidget(
      MaterialApp(
        home: CaoLanhShopScreen(
          repository: repository,
          progress: await repository.load(),
          audioService: audio,
          onProgressUpdated: (progress) => repository.progress = progress,
        ),
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('lotus-mascot-frame-0-lotus')),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/mini_game/characters/lotus/idle/lotus/frame_00.png',
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 220));
    expect(
      find.byKey(const ValueKey('lotus-mascot-frame-1-lotus')),
      findsOneWidget,
    );

    final uniformCard = find.byKey(const ValueKey('shop-item-school_uniform'));
    expect(
      find.descendant(
        of: uniformCard,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/mini_game/characters/shop_icons/school_uniform.png',
        ),
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(of: uniformCard, matching: find.text('Mua')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(repository.progress.coins, 195);
    expect(repository.progress.ownedItemIds, contains('school_uniform'));
    expect(repository.progress.equippedOutfitId, 'school_uniform');
    expect(audio.sounds, contains(QuizSound.purchase));

    final wandCard = find.byKey(const ValueKey('shop-item-explorer_wand'));
    await tester.tap(find.descendant(of: wandCard, matching: find.text('Mua')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(repository.progress.coins, 191);
    expect(repository.progress.equippedOutfitId, 'school_uniform');
    expect(repository.progress.equippedAccessoryId, 'explorer_wand');
    expect(find.text('NHÂN VẬT CỦA BẠN'), findsOneWidget);
  });

  testWidgets('có thể tắt hiệu ứng âm thanh và mở shop trong mini game', (
    tester,
  ) async {
    final repository = _MemoryProgressRepository(QuizShopProgress.initial());
    final audio = _RecordingAudioService();
    await tester.pumpWidget(
      MaterialApp(
        home: CaoLanhQuizScreen(
          progressRepository: repository,
          audioService: audio,
        ),
      ),
    );
    await _pumpQuizAnimations(tester);

    await tester.tap(find.byTooltip('Tắt âm thanh'));
    await _pumpQuizAnimations(tester);
    expect(repository.progress.soundEnabled, isFalse);

    await tester.tap(find.text('An Giang'));
    await _pumpQuizAnimations(tester);
    expect(audio.sounds, isEmpty);
    expect(find.textContaining('Chưa đúng'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('teacher-answer-action-0-0')),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Cửa hàng nhân vật'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Cửa hàng nhân vật'), findsOneWidget);
    expect(find.text('NHÂN VẬT CỦA BẠN'), findsOneWidget);
  });
}
