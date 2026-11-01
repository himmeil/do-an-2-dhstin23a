import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../../core/widgets/async_state_view.dart';
import '../../ban_do/widgets/nearby_map.dart';
import '../../du_lieu/models/place.dart';
import '../../du_lieu/models/place_category.dart';
import '../../du_lieu/services/place_service.dart';
import '../../gps/services/location_service.dart';
import '../../chi_tiet/screens/place_detail_screen.dart';
import '../../nap_du_lieu/screens/import_screen.dart';
import '../services/geocoding_service.dart';
import '../utils/geo.dart';
import '../widgets/location_picker_sheet.dart';
import '../widgets/place_tile.dart';

/// Màn chính: tìm địa điểm quanh vị trí hiện tại, lọc theo loại / bán kính /
/// từ khóa, xem dạng danh sách hoặc bản đồ.
class NearbyScreen extends StatefulWidget {
  const NearbyScreen({
    required this.service,
    required this.locationService,
    required this.geocoder,
    super.key,
  });

  final PlaceService service;
  final LocationService locationService;
  final GeocodingService geocoder;

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  /// Bán kính tìm kiếm (km); null = không giới hạn.
  static const _radii = <double?>[1, 2, 5, 10, null];

  late Stream<List<Place>> _stream = widget.service.watchAll();
  final _searchController = TextEditingController();

  LatLng? _origin;

  /// Tên vị trí do người dùng chọn tay; null khi chưa chọn hoặc dùng GPS.
  String? _manualLabel;
  LocationFailure? _failure;
  bool _locating = false;
  int _locationRequest = 0;

  String _category = 'all';
  double? _radiusKm = 5;
  String _query = '';
  bool _mapMode = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    final request = ++_locationRequest;
    setState(() => _locating = true);
    final result = await widget.locationService.current();
    if (!mounted || request != _locationRequest) return;
    setState(() {
      _locating = false;
      _manualLabel = null;
      _origin = result.position;
      _failure = result.failure;
    });
  }

  Future<void> _pickLocation(List<Place> places) async {
    final choice = await showModalBottomSheet<LocationChoice>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          LocationPickerSheet(geocoder: widget.geocoder, places: places),
    );
    if (choice == null || !mounted) return;
    if (choice.isGps) {
      await _locate();
    } else {
      _locationRequest++;
      setState(() {
        _locating = false;
        _origin = choice.position;
        _manualLabel = choice.label;
        _failure = null;
      });
    }
  }

  void _retryStream() => setState(() => _stream = widget.service.watchAll());

  List<PlaceHit> _filter(List<Place> all) {
    final query = foldVietnamese(_query.trim());
    final hits = <PlaceHit>[];
    for (final place in all) {
      if (_category != 'all' && place.category != _category) continue;
      if (query.isNotEmpty &&
          !foldVietnamese('${place.name} ${place.address}').contains(query)) {
        continue;
      }
      final distance = _origin == null
          ? null
          : distanceMeters(_origin!, place.latLng);
      if (distance != null &&
          _radiusKm != null &&
          distance > _radiusKm! * 1000) {
        continue;
      }
      hits.add(PlaceHit(place, distance));
    }
    hits.sort((a, b) {
      if (a.distance != null && b.distance != null) {
        return a.distance!.compareTo(b.distance!);
      }
      return a.place.name.compareTo(b.place.name);
    });
    return hits;
  }

  void _openDetail(PlaceHit hit) => Navigator.of(
    context,
  ).push<void>(MaterialPageRoute(builder: (_) => PlaceDetailScreen(hit: hit)));

  Future<void> _openImport() async {
    final imported = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => ImportScreen(
          service: widget.service,
          locationService: widget.locationService,
        ),
      ),
    );
    if (imported != null && imported > 0 && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Đã nạp $imported địa điểm.')));
    }
  }

  String _radiusLabel(double? km) =>
      km == null ? 'Tất cả' : '${km.toStringAsFixed(0)} km';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            tooltip: _mapMode ? 'Xem danh sách' : 'Xem bản đồ',
            onPressed: () => setState(() => _mapMode = !_mapMode),
            icon: Icon(_mapMode ? Icons.list : Icons.map_outlined),
          ),
          IconButton(
            tooltip: 'Dùng GPS',
            onPressed: _locating ? null : _locate,
            icon: const Icon(Icons.my_location),
          ),
          IconButton(
            tooltip: 'Nạp dữ liệu',
            onPressed: _openImport,
            icon: const Icon(Icons.upload_file_outlined),
          ),
        ],
      ),
      body: StreamBuilder<List<Place>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorView(
              message: 'Chưa tải được danh sách địa điểm.',
              onRetry: _retryStream,
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final all = snapshot.data ?? const <Place>[];
          if (all.isEmpty && !_mapMode) {
            return _FirstRunView(
              onImport: _openImport,
              onViewMap: () => setState(() => _mapMode = true),
            );
          }
          if (all.isEmpty) {
            return NearbyMap(
              hits: const [],
              origin: null,
              onSelect: _openDetail,
            );
          }

          final hits = _filter(all);
          return Column(
            children: [
              _LocationBar(
                label: _locating
                    ? 'Đang lấy vị trí...'
                    : _manualLabel ??
                          (_origin != null
                              ? 'Vị trí hiện tại (GPS)'
                              : 'Chưa chọn vị trí — chọn địa điểm hoặc dùng GPS'),
                isManual: _manualLabel != null,
                onTap: () => _pickLocation(all),
              ),
              _buildFilters(),
              if (_locating)
                const LinearProgressIndicator()
              else if (_failure != null && _origin == null)
                _LocationBanner(
                  failure: _failure!,
                  onRetry: _locate,
                  onOpenSettings: widget.locationService.openSettings,
                ),
              Expanded(
                child: _mapMode
                    ? NearbyMap(
                        hits: hits,
                        origin: _origin,
                        onSelect: _openDetail,
                        zoom: (_radiusKm ?? 20) >= 5 ? 13.0 : 15.0,
                      )
                    : _buildList(hits),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Tìm theo tên hoặc địa chỉ',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radius),
              ),
              isDense: true,
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              for (final entry in [
                ('all', 'Tất cả'),
                for (final c in placeCategories) (c.code, c.label),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(entry.$2),
                    selected: _category == entry.$1,
                    onSelected: (_) => setState(() => _category = entry.$1),
                  ),
                ),
            ],
          ),
        ),
        if (_origin != null)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Center(child: Text('Bán kính:')),
                ),
                for (final km in _radii)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(_radiusLabel(km)),
                      selected: _radiusKm == km,
                      onSelected: (_) => setState(() => _radiusKm = km),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildList(List<PlaceHit> hits) {
    if (hits.isEmpty) {
      final radius = _origin != null && _radiusKm != null
          ? ' trong bán kính ${_radiusLabel(_radiusKm)}'
          : '';
      return EmptyView(
        message:
            'Không có địa điểm nào$radius.\nThử tăng bán kính hoặc đổi bộ lọc.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: hits.length,
      itemBuilder: (context, index) =>
          PlaceTile(hit: hits[index], onTap: () => _openDetail(hits[index])),
    );
  }
}

/// Thanh hiện vị trí xuất phát; bấm để đổi (GPS hoặc nhập địa chỉ).
class _LocationBar extends StatelessWidget {
  const _LocationBar({
    required this.label,
    required this.isManual,
    required this.onTap,
  });

  final String label;
  final bool isManual;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                isManual ? Icons.pin_drop_outlined : Icons.my_location,
                size: 20,
                color: colors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Đổi',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hiện khi collection còn trống: hướng người dùng tới màn nạp dữ liệu.
class _FirstRunView extends StatelessWidget {
  const _FirstRunView({required this.onImport, required this.onViewMap});

  final VoidCallback onImport;
  final VoidCallback onViewMap;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/splash/launch.jpg',
          fit: BoxFit.cover,
          semanticLabel: 'Ảnh nền của ứng dụng Địa điểm quanh đây',
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                surface.withValues(alpha: 0.70),
                surface.withValues(alpha: 0.88),
              ],
            ),
          ),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/illustrations/nearby_map.png',
                      height: 156,
                      fit: BoxFit.contain,
                      semanticLabel: 'Minh họa bản đồ và địa điểm quanh đây',
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Chưa có địa điểm nào.\nHãy nạp dữ liệu lần đầu để bắt đầu tìm.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: onImport,
                      icon: const Icon(Icons.upload_file_outlined),
                      label: const Text('Nạp dữ liệu'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: onViewMap,
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Xem phường Cao Lãnh trên bản đồ'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationBanner extends StatelessWidget {
  const _LocationBanner({
    required this.failure,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final LocationFailure failure;
  final VoidCallback onRetry;
  final Future<void> Function() onOpenSettings;

  String get _message => switch (failure) {
    LocationFailure.serviceOff => 'Chưa bật định vị (GPS) trên thiết bị.',
    LocationFailure.denied => 'Chưa được cấp quyền vị trí.',
    LocationFailure.deniedForever =>
      'Quyền vị trí đang bị chặn. Hãy bật lại trong cài đặt.',
    LocationFailure.error => 'Không lấy được vị trí hiện tại.',
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$_message Hãy bấm thanh trên để nhập địa chỉ, hoặc thử lại GPS.',
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
            TextButton(
              onPressed: failure == LocationFailure.deniedForever
                  ? onOpenSettings
                  : onRetry,
              child: Text(
                failure == LocationFailure.deniedForever
                    ? 'Mở cài đặt'
                    : 'Thử lại',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
