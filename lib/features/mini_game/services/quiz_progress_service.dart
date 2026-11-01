import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class QuizShopItem {
  const QuizShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.asset,
    required this.price,
    required this.slot,
  });

  final String id;
  final String name;
  final String description;
  final String asset;
  final int price;
  final String slot;

  bool get isOutfit => slot == 'outfit';
}

const quizShopItems = <QuizShopItem>[
  QuizShopItem(
    id: 'school_uniform',
    name: 'Đồng phục học đường',
    description: 'Sẵn sàng cho chuyến khám phá mới.',
    asset: 'assets/mini_game/characters/shop_icons/school_uniform.png',
    price: 5,
    slot: 'outfit',
  ),
  QuizShopItem(
    id: 'plaid_shirt',
    name: 'Áo sơ mi caro',
    description: 'Phong cách thoải mái cho ngày dạo phố.',
    asset: 'assets/mini_game/characters/shop_icons/plaid_shirt.png',
    price: 8,
    slot: 'outfit',
  ),
  QuizShopItem(
    id: 'adventure_jacket',
    name: 'Áo khoác thám hiểm',
    description: 'Trang bị cho những hành trình xa hơn.',
    asset: 'assets/mini_game/characters/shop_icons/adventure_jacket.png',
    price: 12,
    slot: 'outfit',
  ),
  QuizShopItem(
    id: 'pink_wings',
    name: 'Đôi cánh mộng mơ',
    description: 'Phụ kiện nổi bật cho nhân vật của bạn.',
    asset: 'assets/mini_game/characters/shop_icons/pink_wings.png',
    price: 6,
    slot: 'accessory',
  ),
  QuizShopItem(
    id: 'explorer_wand',
    name: 'Trượng khám phá',
    description: 'Người bạn đồng hành trên đường đi.',
    asset: 'assets/mini_game/characters/shop_icons/explorer_wand.png',
    price: 4,
    slot: 'accessory',
  ),
];

class QuizShopProgress {
  QuizShopProgress({
    required this.coins,
    required Set<String> ownedItemIds,
    required this.equippedOutfitId,
    required this.equippedAccessoryId,
    required this.soundEnabled,
  }) : ownedItemIds = Set.unmodifiable(ownedItemIds);

  factory QuizShopProgress.initial() => QuizShopProgress(
    coins: 100,
    ownedItemIds: const {},
    equippedOutfitId: null,
    equippedAccessoryId: null,
    soundEnabled: true,
  );

  factory QuizShopProgress.fromJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Dữ liệu tiến trình mini game không hợp lệ.');
    }

    final coins = decoded['coins'];
    final owned = decoded['ownedItemIds'];
    final soundEnabled = decoded['soundEnabled'];
    if (coins is! int ||
        coins < 0 ||
        owned is! List ||
        owned.any((id) => id is! String) ||
        soundEnabled is! bool) {
      throw const FormatException('Dữ liệu tiến trình mini game không hợp lệ.');
    }
    final ownedIds = owned.cast<String>().toSet();
    final knownItems = {for (final item in quizShopItems) item.id: item};
    if (!knownItems.keys.toSet().containsAll(ownedIds)) {
      throw const FormatException('Tiến trình có vật phẩm không tồn tại.');
    }

    final outfitId = _readEquippedId(decoded['equippedOutfitId'], 'outfit');
    final accessoryId = _readEquippedId(
      decoded['equippedAccessoryId'],
      'accessory',
    );
    if ((outfitId != null && !ownedIds.contains(outfitId)) ||
        (accessoryId != null && !ownedIds.contains(accessoryId))) {
      throw const FormatException('Vật phẩm đang trang bị chưa được sở hữu.');
    }

    return QuizShopProgress(
      coins: coins,
      ownedItemIds: ownedIds,
      equippedOutfitId: outfitId,
      equippedAccessoryId: accessoryId,
      soundEnabled: soundEnabled,
    );
  }

  static const storageKey = 'caolanh_quiz_shop_progress_v1';

  final int coins;
  final Set<String> ownedItemIds;
  final String? equippedOutfitId;
  final String? equippedAccessoryId;
  final bool soundEnabled;

  QuizShopProgress copyWith({
    int? coins,
    Set<String>? ownedItemIds,
    String? equippedOutfitId,
    String? equippedAccessoryId,
    bool clearOutfit = false,
    bool clearAccessory = false,
    bool? soundEnabled,
  }) => QuizShopProgress(
    coins: coins ?? this.coins,
    ownedItemIds: ownedItemIds ?? this.ownedItemIds,
    equippedOutfitId: clearOutfit
        ? null
        : equippedOutfitId ?? this.equippedOutfitId,
    equippedAccessoryId: clearAccessory
        ? null
        : equippedAccessoryId ?? this.equippedAccessoryId,
    soundEnabled: soundEnabled ?? this.soundEnabled,
  );

  Map<String, Object?> toJson() => {
    'coins': coins,
    'ownedItemIds': ownedItemIds.toList()..sort(),
    'equippedOutfitId': equippedOutfitId,
    'equippedAccessoryId': equippedAccessoryId,
    'soundEnabled': soundEnabled,
  };

  static String? _readEquippedId(Object? value, String slot) {
    if (value == null) return null;
    if (value is! String ||
        !quizShopItems.any((item) => item.id == value && item.slot == slot)) {
      throw const FormatException('Dữ liệu trang bị mini game không hợp lệ.');
    }
    return value;
  }
}

abstract interface class QuizProgressRepository {
  Future<QuizShopProgress> load();

  Future<void> save(QuizShopProgress progress);
}

class LocalQuizProgressRepository implements QuizProgressRepository {
  SharedPreferences? _preferences;

  Future<SharedPreferences> get _store async =>
      _preferences ??= await SharedPreferences.getInstance();

  @override
  Future<QuizShopProgress> load() async {
    final store = await _store;
    final saved = store.getString(QuizShopProgress.storageKey);
    if (saved != null) return QuizShopProgress.fromJson(saved);

    final initial = QuizShopProgress.initial();
    await save(initial);
    return initial;
  }

  @override
  Future<void> save(QuizShopProgress progress) async {
    final saved = await (await _store).setString(
      QuizShopProgress.storageKey,
      jsonEncode(progress.toJson()),
    );
    if (!saved) {
      throw StateError('Không lưu được tiến trình mini game trên thiết bị.');
    }
  }
}
