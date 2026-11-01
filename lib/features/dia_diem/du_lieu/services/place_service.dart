import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/place.dart';

/// Đọc và nạp dữ liệu địa điểm. Giao diện chỉ đi qua lớp này.
abstract interface class PlaceService {
  /// Toàn bộ địa điểm, tự cập nhật khi dữ liệu đổi.
  Stream<List<Place>> watchAll();

  /// Lưu các địa điểm (cùng tên + tọa độ thì ghi đè, không nhân đôi).
  /// Trả về số địa điểm đã lưu.
  Future<int> importAll(List<Place> places);
}

/// Lưu ngay trên máy (localStorage khi chạy web, SharedPreferences trên
/// Android/iOS). Không có máy chủ, không dùng tài khoản, không gửi dữ liệu đi đâu.
class LocalPlaceService implements PlaceService {
  LocalPlaceService({SharedPreferences? prefs}) : _prefs = prefs;

  static const storageKey = 'places_v1';

  SharedPreferences? _prefs;
  final _changes = StreamController<void>.broadcast();

  Future<SharedPreferences> get _store async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<List<Place>> _load() async {
    final raw = (await _store).getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map<String, dynamic>)
            Place.fromMap('${item['id']}', item),
      ];
    } catch (_) {
      return const []; // dữ liệu hỏng thì coi như trống, không làm app sập
    }
  }

  @override
  Stream<List<Place>> watchAll() async* {
    yield await _load();
    yield* _changes.stream.asyncMap((_) => _load());
  }

  @override
  Future<int> importAll(List<Place> places) async {
    final byId = {for (final p in await _load()) p.id: p};
    for (final p in places) {
      byId[p.id] = p;
    }
    final encoded = jsonEncode([
      for (final p in byId.values) {'id': p.id, ...p.toMap()},
    ]);
    await (await _store).setString(storageKey, encoded);
    _changes.add(null);
    return places.length;
  }
}
