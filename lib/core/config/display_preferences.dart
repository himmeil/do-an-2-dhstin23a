enum MapGraphicsQuality {
  high,
  medium,
  low;

  String get label => switch (this) {
    MapGraphicsQuality.high => 'Cao',
    MapGraphicsQuality.medium => 'Trung bình',
    MapGraphicsQuality.low => 'Thấp',
  };

  String get description => switch (this) {
    MapGraphicsQuality.high => 'Tải trước thêm ô bản đồ khi di chuyển.',
    MapGraphicsQuality.medium => 'Cân bằng giữa độ mượt và mức sử dụng bộ nhớ.',
    MapGraphicsQuality.low =>
      'Giảm tải trước ô bản đồ để ưu tiên thiết bị yếu.',
  };

  int get tilePanBuffer => switch (this) {
    MapGraphicsQuality.high => 1,
    MapGraphicsQuality.medium || MapGraphicsQuality.low => 0,
  };

  int get tileKeepBuffer => switch (this) {
    MapGraphicsQuality.high => 2,
    MapGraphicsQuality.medium => 1,
    MapGraphicsQuality.low => 0,
  };

  Duration get tileFadeDuration => switch (this) {
    MapGraphicsQuality.high => const Duration(milliseconds: 150),
    MapGraphicsQuality.medium => const Duration(milliseconds: 100),
    MapGraphicsQuality.low => const Duration(milliseconds: 50),
  };

  static MapGraphicsQuality fromStorage(String? value) => switch (value) {
    'high' => MapGraphicsQuality.high,
    'low' => MapGraphicsQuality.low,
    _ => MapGraphicsQuality.medium,
  };
}
