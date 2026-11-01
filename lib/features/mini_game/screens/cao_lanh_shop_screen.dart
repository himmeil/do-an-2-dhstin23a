import 'package:flutter/material.dart';

import '../services/quiz_audio_service.dart';
import '../services/quiz_progress_service.dart';
import '../widgets/lotus_mascot.dart';

class CaoLanhShopScreen extends StatefulWidget {
  const CaoLanhShopScreen({
    required this.repository,
    required this.progress,
    required this.audioService,
    required this.onProgressUpdated,
    super.key,
  });

  final QuizProgressRepository repository;
  final QuizShopProgress progress;
  final QuizAudioService audioService;
  final ValueChanged<QuizShopProgress> onProgressUpdated;

  @override
  State<CaoLanhShopScreen> createState() => _CaoLanhShopScreenState();
}

class _CaoLanhShopScreenState extends State<CaoLanhShopScreen> {
  static const _sky = Color(0xFF2879A8);
  static const _paleSky = Color(0xFFE8F4FB);

  late QuizShopProgress _progress = widget.progress;
  String _category = 'all';
  String? _busyItemId;
  String? _progressError;

  List<QuizShopItem> get _visibleItems => quizShopItems
      .where((item) => _category == 'all' || item.slot == _category)
      .toList();

  Future<void> _buyOrEquip(QuizShopItem item) async {
    if (_busyItemId != null) return;
    final isOwned = _progress.ownedItemIds.contains(item.id);
    if (!isOwned && _progress.coins < item.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa đủ xu. Hãy chơi tiếp để nhận xu nhé!'),
        ),
      );
      return;
    }

    final updated = _progress.copyWith(
      coins: isOwned ? null : _progress.coins - item.price,
      ownedItemIds: {..._progress.ownedItemIds, item.id},
      equippedOutfitId: item.isOutfit ? item.id : null,
      equippedAccessoryId: item.isOutfit ? null : item.id,
    );
    setState(() {
      _busyItemId = item.id;
      _progressError = null;
    });

    try {
      await widget.repository.save(updated);
      if (!mounted) return;
      setState(() {
        _progress = updated;
        _busyItemId = null;
      });
      widget.onProgressUpdated(updated);
      if (!isOwned) await _playPurchaseSound();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busyItemId = null;
        _progressError = 'Không lưu được thay đổi: $error';
      });
    }
  }

  Future<void> _playPurchaseSound() async {
    if (!_progress.soundEnabled) return;
    try {
      await widget.audioService.play(QuizSound.purchase);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không phát được âm thanh: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paleSky,
      appBar: AppBar(
        title: const Text('Cửa hàng nhân vật'),
        foregroundColor: Colors.white,
        backgroundColor: _sky,
        surfaceTintColor: Colors.transparent,
        actions: [
          _CoinBalance(coins: _progress.coins),
          const SizedBox(width: 12),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE8F4FB),
                  Color(0xFFFFF0F5),
                  Color(0xFFD9EDF8),
                ],
              ),
            ),
          ),
          Positioned(
            top: 24,
            right: 24,
            child: Icon(
              Icons.local_florist_outlined,
              size: 96,
              color: const Color(0xFFE58BAA).withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 18,
            child: Icon(
              Icons.spa_outlined,
              size: 124,
              color: _sky.withValues(alpha: 0.09),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _CharacterShowcase(progress: _progress),
                  const SizedBox(height: 12),
                  Text(
                    'Xu là điểm thử nghiệm, chỉ lưu trên trình duyệt này.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: _sky.withValues(alpha: 0.82)),
                  ),
                  if (_progressError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _progressError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF9D3258)),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'all', label: Text('Tất cả')),
                      ButtonSegment(value: 'outfit', label: Text('Quần áo')),
                      ButtonSegment(
                        value: 'accessory',
                        label: Text('Trang bị'),
                      ),
                    ],
                    selected: {_category},
                    onSelectionChanged: (selection) =>
                        setState(() => _category = selection.first),
                    style: SegmentedButton.styleFrom(
                      foregroundColor: _sky,
                      selectedForegroundColor: Colors.white,
                      selectedBackgroundColor: _sky,
                      side: const BorderSide(color: Color(0xFFA8D0E8)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 720
                          ? 3
                          : constraints.maxWidth >= 470
                          ? 2
                          : 1;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _visibleItems.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 244,
                        ),
                        itemBuilder: (context, index) => _ShopItemCard(
                          item: _visibleItems[index],
                          progress: _progress,
                          busy: _busyItemId == _visibleItems[index].id,
                          onTap: () => _buyOrEquip(_visibleItems[index]),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinBalance extends StatelessWidget {
  const _CoinBalance({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Số dư $coins xu',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/mini_game/cards/coin.png',
            width: 28,
            height: 28,
            semanticLabel: 'Xu',
          ),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CharacterShowcase extends StatelessWidget {
  const _CharacterShowcase({required this.progress});

  final QuizShopProgress progress;

  QuizShopItem? _itemFor(String? id) {
    if (id == null) return null;
    for (final item in quizShopItems) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final outfit = _itemFor(progress.equippedOutfitId);
    final accessory = _itemFor(progress.equippedAccessoryId);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFFF0F5), Color(0xFFEAF5FB)],
        ),
        border: Border.all(color: const Color(0xFFD0E6F2)),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2879A8).withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 430;
          final character = SizedBox(
            width: compact ? 170 : 190,
            height: compact ? 252 : 282,
            child: _VirtualCharacter(outfit: outfit, accessory: accessory),
          );
          final loadout = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NHÂN VẬT CỦA BẠN',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF2879A8),
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Nhà thám hiểm nhí',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF24445A),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              _EquippedSlot(label: 'Áo', item: outfit),
              const SizedBox(height: 8),
              _EquippedSlot(label: 'Phụ kiện', item: accessory),
            ],
          );
          return compact
              ? Column(
                  children: [
                    character,
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerLeft, child: loadout),
                  ],
                )
              : Row(
                  children: [
                    character,
                    const SizedBox(width: 16),
                    Expanded(child: loadout),
                  ],
                );
        },
      ),
    );
  }
}

class _VirtualCharacter extends StatelessWidget {
  const _VirtualCharacter({required this.outfit, required this.accessory});

  final QuizShopItem? outfit;
  final QuizShopItem? accessory;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: width * 0.12,
              right: width * 0.12,
              top: height * 0.08,
              bottom: height * 0.10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Colors.white,
                      Color(0xFFFFEAF1),
                      Color(0xFFD9EDF8),
                    ],
                  ),
                  border: Border.all(color: const Color(0xFFC9E1EF)),
                ),
              ),
            ),
            Positioned(
              left: width * 0.18,
              right: width * 0.18,
              bottom: height * 0.12,
              child: Container(
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF76B8D7).withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Positioned.fill(
              child: LotusMascot(
                outfitId: outfit?.id,
                semanticLabel: 'Nhân vật hoa sen mặc đồ đang chuyển động',
              ),
            ),
            if (accessory != null)
              Positioned(
                right: 4,
                top: height * 0.18,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE6A5BA)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F24493E),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      accessory!.asset,
                      width: 38,
                      height: 38,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 8,
              bottom: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF2879A8),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Text(
                    'NHÀ THÁM HIỂM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EquippedSlot extends StatelessWidget {
  const _EquippedSlot({required this.label, required this.item});

  final String label;
  final QuizShopItem? item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: const Color(0xFF2879A8)),
          ),
        ),
        if (item == null)
          const Text(
            'Chưa trang bị',
            style: TextStyle(color: Color(0xFF7A817B)),
          )
        else ...[
          Image.asset(item!.asset, width: 44, height: 44, fit: BoxFit.contain),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              item!.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF24445A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({
    required this.item,
    required this.progress,
    required this.busy,
    required this.onTap,
  });

  final QuizShopItem item;
  final QuizShopProgress progress;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isOwned = progress.ownedItemIds.contains(item.id);
    final equippedId = item.isOutfit
        ? progress.equippedOutfitId
        : progress.equippedAccessoryId;
    final isEquipped = equippedId == item.id;
    return Card(
      key: ValueKey('shop-item-${item.id}'),
      clipBehavior: Clip.antiAlias,
      color: const Color(0xFFFFFCFD),
      elevation: 3,
      shadowColor: const Color(0xFF2879A8).withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFD0E6F2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 82,
              height: 112,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(item.asset, fit: BoxFit.contain),
                  if (isEquipped)
                    Align(
                      alignment: Alignment.topRight,
                      child: Icon(
                        Icons.check_circle,
                        color: const Color(0xFFE58BAA),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: busy || isEquipped ? null : onTap,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        foregroundColor: const Color(0xFF24445A),
                        backgroundColor: const Color(0xFFDDEFF8),
                      ),
                      child: busy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : isEquipped
                          ? const Text('Đang mặc')
                          : isOwned
                          ? const Text('Trang bị')
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Mua'),
                                  const SizedBox(width: 6),
                                  Image.asset(
                                    'assets/mini_game/cards/coin.png',
                                    width: 18,
                                    height: 18,
                                  ),
                                  const SizedBox(width: 3),
                                  Text('${item.price}'),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
