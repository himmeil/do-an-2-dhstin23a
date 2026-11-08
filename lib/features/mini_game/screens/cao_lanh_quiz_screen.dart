import 'dart:async';

import 'package:flutter/material.dart';

import '../services/quiz_audio_service.dart';
import '../services/quiz_progress_service.dart';
import '../widgets/lotus_mascot.dart';
import '../widgets/npc_atlas_animation.dart';
import 'cao_lanh_shop_screen.dart';

class _QuizQuestion {
  const _QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
}

const _questions = <_QuizQuestion>[
  _QuizQuestion(
    question: 'Cao Lãnh gắn liền với tỉnh nào?',
    options: ['An Giang', 'Đồng Tháp', 'Vĩnh Long', 'Cần Thơ'],
    correctIndex: 1,
    explanation: 'Cao Lãnh là một trung tâm đô thị tiêu biểu của Đồng Tháp.',
  ),
  _QuizQuestion(
    question: 'Câu thơ nhắc đến Tháp Mười thường ca ngợi loài hoa nào?',
    options: ['Hoa sen', 'Hoa mai', 'Hoa phượng', 'Hoa súng'],
    correctIndex: 0,
    explanation:
        '“Tháp Mười đẹp nhất bông sen” là câu thơ quen thuộc về Đồng Tháp.',
  ),
  _QuizQuestion(
    question: 'Cao Lãnh thuộc vùng địa lý nào của Việt Nam?',
    options: [
      'Tây Nguyên',
      'Đông Bắc Bộ',
      'Đồng bằng sông Cửu Long',
      'Duyên hải Nam Trung Bộ',
    ],
    correctIndex: 2,
    explanation: 'Cao Lãnh nằm trong vùng Đồng bằng sông Cửu Long.',
  ),
  _QuizQuestion(
    question: 'Khu di tích Nguyễn Sinh Sắc là điểm tham quan lịch sử ở đâu?',
    options: ['Cao Lãnh', 'Sa Pa', 'Hội An', 'Đà Lạt'],
    correctIndex: 0,
    explanation: 'Khu di tích Nguyễn Sinh Sắc là một địa điểm lịch sử nổi bật tại Cao Lãnh.',
  ),
  _QuizQuestion(
    question: 'Loại trái cây nào thường được nhắc như đặc sản Cao Lãnh?',
    options: ['Vải thiều', 'Xoài', 'Thanh long', 'Mận hậu'],
    correctIndex: 1,
    explanation: 'Xoài Cao Lãnh là đặc sản quen thuộc của địa phương.',
  ),
];

class CaoLanhQuizScreen extends StatefulWidget {
  const CaoLanhQuizScreen({
    this.progressRepository,
    this.audioService,
    super.key,
  });

  final QuizProgressRepository? progressRepository;
  final QuizAudioService? audioService;

  @override
  State<CaoLanhQuizScreen> createState() => _CaoLanhQuizScreenState();
}

class _CaoLanhQuizScreenState extends State<CaoLanhQuizScreen> {
  late final QuizProgressRepository _progressRepository =
      widget.progressRepository ?? LocalQuizProgressRepository();
  late final QuizAudioService _audioService =
      widget.audioService ?? AssetQuizAudioService();
  final _scrollController = ScrollController();
  int _questionIndex = 0;
  int _score = 0;
  int? _selectedIndex;
  QuizShopProgress? _progress;
  bool _progressLoading = true;
  bool _savingProgress = false;
  String? _progressError;
  bool _completionRewarded = false;

  bool get _isComplete => _questionIndex >= _questions.length;

  @override
  void initState() {
    super.initState();
    unawaited(_loadProgress());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    try {
      final progress = await _progressRepository.load();
      if (!mounted) return;
      setState(() {
        _progress = progress;
        _progressLoading = false;
        _progressError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _progressLoading = false;
        _progressError = 'Không tải được tiến trình mini game: $error';
      });
    }
  }

  void _selectAnswer(int index) {
    if (_selectedIndex != null || _savingProgress) return;
    final isCorrect = index == _questions[_questionIndex].correctIndex;
    setState(() {
      _selectedIndex = index;
      if (isCorrect) _score++;
    });
    _playSound(isCorrect ? QuizSound.correct : QuizSound.incorrect);
    if (isCorrect) unawaited(_addCoins(10));
  }

  Future<void> _nextQuestion() async {
    if (_savingProgress) return;
    if (_questionIndex == _questions.length - 1 && !_completionRewarded) {
      await _addCoins(20);
      if (_progressError != null || !mounted) return;
      _completionRewarded = true;
    }
    setState(() {
      _questionIndex++;
      _selectedIndex = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    });
  }

  void _restart() {
    setState(() {
      _questionIndex = 0;
      _score = 0;
      _selectedIndex = null;
      _completionRewarded = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    });
  }

  Future<void> _addCoins(int amount) async {
    final current = _progress;
    if (current == null || _savingProgress) return;
    await _saveProgress(current.copyWith(coins: current.coins + amount));
    if (!mounted || _progressError != null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Bạn nhận được $amount xu!')));
  }

  Future<void> _saveProgress(QuizShopProgress updated) async {
    final previous = _progress;
    setState(() {
      _progress = updated;
      _savingProgress = true;
      _progressError = null;
    });
    try {
      await _progressRepository.save(updated);
      if (!mounted) return;
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _progress = previous;
        _progressError = 'Không lưu được tiến trình: $error';
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_progressError!)));
    } finally {
      if (mounted) setState(() => _savingProgress = false);
    }
  }

  void _playSound(QuizSound sound) {
    if (_progress?.soundEnabled != true) return;
    unawaited(_playSoundSafely(sound));
  }

  Future<void> _playSoundSafely(QuizSound sound) async {
    try {
      await _audioService.play(sound);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không phát được âm thanh: $error')),
      );
    }
  }

  Future<void> _toggleSound() async {
    final progress = _progress;
    if (progress == null || _savingProgress) return;
    await _saveProgress(
      progress.copyWith(soundEnabled: !progress.soundEnabled),
    );
  }

  Future<void> _openShop() async {
    final progress = _progress;
    if (progress == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CaoLanhShopScreen(
          repository: _progressRepository,
          progress: progress,
          audioService: _audioService,
          onProgressUpdated: (updated) {
            if (mounted) setState(() => _progress = updated);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8FC),
      appBar: AppBar(
        title: const Text('Thử thách Cao Lãnh'),
        backgroundColor: const Color(0xFFF1F8FC),
        actions: [
          if (_progress case final progress?)
            Center(
              child: Row(
                children: [
                  Image.asset(
                    'assets/mini_game/cards/coin.png',
                    width: 24,
                    height: 24,
                    semanticLabel: 'Xu',
                  ),
                  const SizedBox(width: 4),
                  Text('${progress.coins}'),
                ],
              ),
            ),
          IconButton(
            tooltip: _progress?.soundEnabled == true
                ? 'Tắt âm thanh'
                : 'Bật âm thanh',
            onPressed: _progress == null || _savingProgress
                ? null
                : _toggleSound,
            icon: Icon(
              _progress?.soundEnabled == true
                  ? Icons.volume_up
                  : Icons.volume_off,
            ),
          ),
          IconButton(
            tooltip: 'Cửa hàng nhân vật',
            onPressed: _progress == null || _savingProgress ? null : _openShop,
            icon: const Icon(Icons.storefront_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _progressLoading
          ? const Center(child: CircularProgressIndicator())
          : _progress == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _progressError ?? 'Không tải được tiến trình mini game.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _progressLoading = true;
                          _progressError = null;
                        });
                        unawaited(_loadProgress());
                      },
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
          : SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: _isComplete
                      ? _buildResult(colors)
                      : _buildQuestion(colors),
                ),
              ),
            ),
    );
  }

  Widget _buildQuestion(ColorScheme colors) {
    final question = _questions[_questionIndex];
    final selected = _selectedIndex;
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
      children: [
        _TeacherGuide(
          questionIndex: _questionIndex,
          answerIndex: selected,
          answerCorrect: selected == null
              ? null
              : selected == question.correctIndex,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (_questionIndex + 1) / _questions.length,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFDCEBF4),
                  color: const Color(0xFF55A5D1),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${_questionIndex + 1}/${_questions.length}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final mascotWidth = constraints.maxWidth < 360
                ? 72.0
                : constraints.maxWidth < 500
                ? 92.0
                : 118.0;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: mascotWidth,
                  child: Column(
                    children: [
                      Container(
                        height: 150,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEAF6FC), Color(0xFFFFEAF1)],
                          ),
                          border: Border.all(color: const Color(0xFFB8DCEC)),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: LotusMascot(
                          outfitId: _progress?.equippedOutfitId,
                          semanticLabel:
                              'Nhân vật hoa sen đang mặc trang phục đã chọn',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'BẠN ĐỒNG HÀNH',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF397A9D),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Mở shop thay trang phục',
                        visualDensity: VisualDensity.compact,
                        onPressed: _savingProgress ? null : _openShop,
                        color: const Color(0xFF397A9D),
                        icon: const Icon(Icons.checkroom_outlined),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Color(0xFFEAF5FB)],
                      ),
                      border: Border.all(color: const Color(0xFFC9E1EF)),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x142C79A8),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.style_rounded,
                              color: Color(0xFFD96F96),
                              size: 19,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'KHO THẺ CAO LÃNH',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: const Color(0xFF2879A8),
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.35,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFDBEAF3)),
                          ),
                          child: Text(
                            question.question,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: const Color(0xFF24445A),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        LayoutBuilder(
                          builder: (context, cardConstraints) {
                            final cardWidth =
                                (cardConstraints.maxWidth - 8) / 2;
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (
                                  var index = 0;
                                  index < question.options.length;
                                  index++
                                )
                                  SizedBox(
                                    width: cardWidth,
                                    child: _AnswerCard(
                                      index: index,
                                      label: question.options[index],
                                      selected: selected == index,
                                      isCorrect:
                                          selected != null &&
                                          index == question.correctIndex,
                                      enabled: selected == null,
                                      onTap: () => _selectAnswer(index),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        if (selected != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: selected == question.correctIndex
                                  ? const Color(0xFFE5F2FB)
                                  : const Color(0xFFFFEDF3),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  selected == question.correctIndex
                                      ? Icons.check_circle
                                      : Icons.lightbulb,
                                  color: selected == question.correctIndex
                                      ? const Color(0xFF2879A8)
                                      : const Color(0xFFB65371),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${selected == question.correctIndex ? 'Chính xác!' : 'Cùng ghi nhớ nhé!'} ${question.explanation}',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          FilledButton.icon(
                            onPressed: _savingProgress ? null : _nextQuestion,
                            icon: Icon(
                              _questionIndex == _questions.length - 1
                                  ? Icons.emoji_events_outlined
                                  : Icons.arrow_forward,
                            ),
                            label: Text(
                              _questionIndex == _questions.length - 1
                                  ? 'Xem kết quả'
                                  : 'Câu tiếp theo',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildResult(ColorScheme colors) {
    final message = switch (_score) {
      5 => 'Xuất sắc! Bạn là chuyên gia Cao Lãnh rồi.',
      >= 3 => 'Làm tốt lắm! Bạn đã biết thêm nhiều điều thú vị.',
      _ => 'Một hành trình khởi đầu! Chơi lại để khám phá thêm nhé.',
    };
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Icon(Icons.emoji_events, size: 72, color: colors.primary),
        const SizedBox(height: 12),
        Text(
          'Hoàn thành thử thách!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          '$_score/${_questions.length} điểm',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall
              ?.copyWith(color: colors.primary, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const _VictoryTreasureScene(),
        const SizedBox(height: 8),
        if (_progress != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/mini_game/cards/coin.png',
                width: 24,
                height: 24,
                semanticLabel: 'Xu',
              ),
              const SizedBox(width: 6),
              Text(
                'Ví của bạn: ${_progress!.coins} xu',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: const [
            _CollectedCharacterCard(
              asset: 'assets/mini_game/cards/card_2_0.png',
              label: 'Nhà khám phá',
            ),
            _CollectedCharacterCard(
              asset: 'assets/mini_game/cards/card_3_0.png',
              label: 'Đồng đội vui vẻ',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Đúng một câu nhận 10 xu, hoàn thành lượt nhận thêm 20 xu.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _openShop,
          icon: const Icon(Icons.storefront_outlined),
          label: const Text('Mở cửa hàng nhân vật'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _restart,
          icon: const Icon(Icons.replay),
          label: const Text('Chơi lại'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Quay lại tìm địa điểm'),
        ),
      ],
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.index,
    required this.label,
    required this.selected,
    required this.isCorrect,
    required this.enabled,
    required this.onTap,
  });

  static const _answerAssets = [
    'assets/mini_game/cards/answers/A_1.png',
    'assets/mini_game/cards/answers/A_2.png',
    'assets/mini_game/cards/answers/A_3.png',
    'assets/mini_game/cards/answers/A_4.png',
  ];

  final int index;
  final String label;
  final bool selected;
  final bool isCorrect;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = selected || (isCorrect && !enabled)
        ? (isCorrect ? const Color(0x333C93C2) : const Color(0x33D96F96))
        : Colors.transparent;
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Đáp án ${String.fromCharCode(65 + index)}: $label',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 72,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(_answerAssets[index], fit: BoxFit.fill),
                if (tint != Colors.transparent)
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: tint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(56, 8, 8, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF24445A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TeacherGuide extends StatefulWidget {
  const _TeacherGuide({
    required this.questionIndex,
    required this.answerIndex,
    required this.answerCorrect,
  });

  final int questionIndex;
  final int? answerIndex;
  final bool? answerCorrect;

  @override
  State<_TeacherGuide> createState() => _TeacherGuideState();
}

class _TeacherGuideState extends State<_TeacherGuide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE6F4FB), Color(0xFFFFEDF3)],
        ),
        border: Border.all(color: const Color(0xFFC9E1EF)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 102,
            child: widget.answerIndex == null
                ? AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final frame = (_controller.value * 2).floor() % 2;
                      return Image.asset(
                        'assets/mini_game/characters/teacher/frame_0$frame.png',
                        key: ValueKey('teacher-idle-frame-$frame'),
                        fit: BoxFit.contain,
                        semanticLabel: 'Nhân vật thầy giáo hoạt hình',
                      );
                    },
                  )
                : NpcAtlasAnimation(
                    key: ValueKey(
                      'teacher-answer-action-${widget.questionIndex}-'
                      '${widget.answerIndex}',
                    ),
                    assetPath: 'assets/npc_1.png',
                    frames: teacherAnswerFrames,
                    duration: const Duration(milliseconds: 900),
                    semanticLabel: 'Thầy giáo đang phản hồi câu trả lời',
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THẦY GIÁO',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF2879A8),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.answerIndex == null
                      ? 'Cùng thầy khám phá Cao Lãnh nhé! Chọn đúng thẻ để ghi điểm.'
                      : widget.answerCorrect == true
                      ? 'Giỏi lắm! Câu trả lời chính xác!'
                      : 'Chưa đúng, cùng đọc gợi ý rồi thử câu tiếp theo nhé.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF24445A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VictoryTreasureScene extends StatefulWidget {
  const _VictoryTreasureScene();

  @override
  State<_VictoryTreasureScene> createState() => _VictoryTreasureSceneState();
}

class _VictoryTreasureSceneState extends State<_VictoryTreasureScene> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        border: Border.all(color: const Color(0xFFEBD69A)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Thầy dẫn bạn đến rương kho báu!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF78551A),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<Offset>(
                tween: Tween(begin: const Offset(-0.45, 0), end: Offset.zero),
                duration: const Duration(milliseconds: 800),
                builder: (context, offset, child) =>
                    FractionalTranslation(translation: offset, child: child),
                child: SizedBox(
                  key: const ValueKey('teacher-victory-action'),
                  width: 76,
                  height: 100,
                  child: NpcAtlasAnimation(
                    assetPath: 'assets/npc_1.png',
                    frames: teacherVictoryFrames,
                    duration: const Duration(milliseconds: 1100),
                    semanticLabel: 'Thầy giáo dẫn đường đến rương kho báu',
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFFB88A28),
                  size: 28,
                ),
              ),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  key: const ValueKey('treasure-chest-button'),
                  onTap: _isOpen ? null : () => setState(() => _isOpen = true),
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 120,
                    height: 112,
                    child: Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: NpcAtlasAnimation(
                              key: ValueKey(
                                _isOpen
                                    ? 'treasure-chest-open'
                                    : 'treasure-chest-closed',
                              ),
                              assetPath: 'assets/npc_3.png',
                              frames: _isOpen
                                  ? chestOpeningFrames
                                  : const [chestClosedFrame],
                              duration: const Duration(milliseconds: 700),
                              semanticLabel: _isOpen
                                  ? 'Rương kho báu đang mở'
                                  : 'Rương kho báu đang đóng',
                            ),
                          ),
                        ),
                        Text(
                          _isOpen ? 'Đã mở!' : 'Nhấn để mở',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: const Color(0xFF78551A),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollectedCharacterCard extends StatelessWidget {
  const _CollectedCharacterCard({required this.asset, required this.label});

  final String asset;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              asset,
              width: 112,
              height: 148,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
