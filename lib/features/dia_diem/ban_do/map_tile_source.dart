enum MapStyle { street, satellite }

extension MapStyleSource on MapStyle {
  String get tileUrl => switch (this) {
    MapStyle.street => 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
    MapStyle.satellite => 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
  };

  String get switchTooltip => switch (this) {
    MapStyle.street => 'Chuyển sang ảnh vệ tinh',
    MapStyle.satellite => 'Chuyển sang bản đồ đường phố',
  };
}
