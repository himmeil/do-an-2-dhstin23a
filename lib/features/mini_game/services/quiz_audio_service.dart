import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

enum QuizSound { correct, incorrect, purchase }

abstract interface class QuizAudioService {
  Future<void> play(QuizSound sound);

  void dispose();
}

class AssetQuizAudioService implements QuizAudioService {
  AssetQuizAudioService() : _player = AudioPlayer();

  final AudioPlayer _player;

  static const _assets = {
    QuizSound.correct: 'mini_game/audio/fx/classroom_rightanswer.mp3',
    QuizSound.incorrect: 'mini_game/audio/fx/classroom_failanswer.mp3',
    QuizSound.purchase: 'mini_game/audio/fx/buy.mp3',
  };

  @override
  Future<void> play(QuizSound sound) =>
      _player.play(AssetSource(_assets[sound]!));

  @override
  void dispose() {
    unawaited(_player.dispose());
  }
}
