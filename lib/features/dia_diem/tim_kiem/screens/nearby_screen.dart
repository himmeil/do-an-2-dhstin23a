import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../../core/widgets/async_state_view.dart';
import '../../../mini_game/screens/cao_lanh_quiz_screen.dart';
import '../../ban_do/cao_lanh_ward_boundary.dart';
import '../../ban_do/widgets/nearby_map.dart';
import '../../du_lieu/models/place.dart';
import '../../du_lieu/services/place_service.dart';
import '../../gps/services/location_service.dart';
import '../../chi_tiet/screens/place_detail_screen.dart';
import '../../nap_du_lieu/screens/import_screen.dart';
import '../bo_loc/services/place_category_filter.dart';
import '../bo_loc/widgets/nearby_filter_chips.dart';
import '../services/geocoding_service.dart';
import '../services/nearby_places_service.dart';
import '../utils/geo.dart';
import '../widgets/location_picker_sheet.dart';
import '../widgets/place_tile.dart';

enum _NearbyAction {
  createDraft,
  publishDrafts,
  updateMapFromOverpass,
  selectMapDataSource,
  signIn,
  signOut,
  downloadOfflinePlaces,
}

/// Màn chính: tìm địa điểm quanh vị trí hiện tại, lọc theo loại / bán kính /
/// từ khóa, xem dạng danh sách hoặc bản đồ.
class NearbyScreen extends StatefulWidget {
  const NearbyScreen({
    required this.service,
    required this.locationService,
    required this.geocoder,
    this.nearbyPlacesService,
    this.draftService,
    this.favoriteService,
    this.userEmail = '',
    this.isAdmin = false,
    this.isGuest = false,
    this.onRequireSignIn,
    this.onSignOut,
    super.key,
  });

  final PlaceService service;
  final PlaceService? draftService;
  final FirestoreFavoriteService? favoriteService;
  final LocationService locationService;
  final GeocodingService geocoder;
  final NearbyPlacesService? nearbyPlacesService;
  final String userEmail;
  final bool isAdmin;
  final bool isGuest;
  final ValueChanged<String>? onRequireSignIn;
  final Future<void> Function()? onSignOut;

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  late Stream<List<Place>> _stream = widget.service.watchAll();
  final _searchController = TextEditingController();
  final Set<String> _favoriteIds = {};
  StreamSubscription<Set<String>>? _favoriteSubscription;
  Timer? _nearbySearchDebounce;
  String? _favoriteError;
  String? _nearbySearchError;
  List<Place> _nearbyPlaces = const [];
  bool _searchingNearby = false;
  int _nearbySearchRequest = 0;

  LatLng? _origin = caoLanhWardCenter;

  /// Tên vị trí do người dùng chọn tay; null khi chưa chọn hoặc dùng GPS.
  String? _manualLabel = 'Phường Cao Lãnh, Đồng Tháp';
  LocationFailure? _failure;
  bool _locating = false;
  int _locationRequest = 0;

  final Set<String> _selectedCategories = {};
  double? _radiusKm = 5;
  String _query = '';
  String _searchInput = '';
  String? _selectedPlaceId;
  bool _mapMode = true;
  bool _searchControlsExpanded = false;
  bool _filtersExpanded = false;
  bool _favoritesOnly = false;
  bool _publishing = false;
  bool _selectingMapData = false;
  bool _showDonation = false;

  static const _minMapZoom = 11.0;
  static const _maxMapZoom = 18.0;
  static const _farZoomVisibilityFraction = 0.5;
  static const _donationZoomThreshold =
      _minMapZoom + (_maxMapZoom - _minMapZoom) * _farZoomVisibilityFraction;

  @override
  void initState() {
    super.initState();
    _favoriteSubscription = widget.favoriteService?.watchIds().listen(
      (ids) {
        if (!mounted) return;
        setState(() {
          _favoriteIds
            ..clear()
            ..addAll(ids);
          _favoriteError = null;
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!mounted) return;
        setState(() => _favoriteError = error.toString());
      },
    );
    _scheduleNearbySearch();
  }

  @override
  void didUpdateWidget(covariant NearbyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    unawaited(_favoriteSubscription?.cancel());
    _nearbySearchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    final request = ++_locationRequest;
    setState(() => _locating = true);
    final result = await widget.locationService.current();
    if (!mounted || request != _locationRequest) return;
    if (result.position != null &&
        !caoLanhMapBounds.contains(result.position!)) {
      setState(() => _locating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ hỗ trợ vị trí trong khu vực Cao Lãnh.'),
        ),
      );
      return;
    }
    setState(() {
      _locating = false;
      _manualLabel = null;
      _origin = result.position;
      _failure = result.failure;
    });
    _scheduleNearbySearch();
  }

  Future<void> _pickLocation(List<Place> places) async {
    final choice = await showModalBottomSheet<LocationChoice>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          LocationPickerSheet(geocoder: widget.geocoder, places: places),
    );
    if (choice == null || !mounted) return;
    if (!choice.isGps && !caoLanhMapBounds.contains(choice.position!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ hỗ trợ tìm kiếm trong khu vực Cao Lãnh.'),
        ),
      );
      return;
    }
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
      _scheduleNearbySearch();
    }
  }

  void _scheduleNearbySearch() {
    _nearbySearchDebounce?.cancel();
    final request = ++_nearbySearchRequest;
    final service = widget.nearbyPlacesService;
    final center = _origin;
    if (service == null || center == null) {
      setState(() {
        _nearbyPlaces = const [];
        _nearbySearchError = null;
        _searchingNearby = false;
      });
      return;
    }

    setState(() {
      _searchingNearby = true;
      _nearbySearchError = null;
    });
    _nearbySearchDebounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final places = await service.search(
          center: center,
          radiusMeters: ((_radiusKm ?? 10) * 1000).round(),
        );
        if (!mounted || request != _nearbySearchRequest) return;
        setState(() {
          _nearbyPlaces = places;
          _searchingNearby = false;
          _nearbySearchError = null;
        });
      } catch (error) {
        if (!mounted || request != _nearbySearchRequest) return;
        setState(() {
          _searchingNearby = false;
          _nearbySearchError = error.toString();
        });
      }
    });
  }

  String _nearbySearchErrorMessage(String error) {
    if (error.contains('localhost:8787')) {
      return 'Backend địa điểm chưa chạy. Hãy chạy run_web.bat hoặc '
          'bat_app.bat rồi tải lại trang.';
    }
    if (error.contains('429')) {
      return 'Nguồn dữ liệu OpenStreetMap đang quá tải. Bản đồ vẫn hoạt động; hãy thử lại sau.';
    }
    if (error.toLowerCase().contains('timeout')) {
      return 'Tra cứu OpenStreetMap mất quá nhiều thời gian. Bản đồ vẫn hoạt động; hãy thử lại sau.';
    }
    return 'Không kết nối được dữ liệu địa điểm OpenStreetMap (có thể do CORS hoặc máy chủ). Bản đồ vẫn hoạt động; hãy thử lại.';
  }

  void _chooseMapOrigin(LatLng point) {
    if (!caoLanhMapBounds.contains(point)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ hỗ trợ tìm kiếm trong khu vực Cao Lãnh.'),
        ),
      );
      return;
    }
    _nearbySearchRequest++;
    setState(() {
      _origin = point;
      _manualLabel = 'Vị trí đã chọn trên bản đồ';
      _failure = null;
    });
    _scheduleNearbySearch();
  }

  void _updateMapZoom(double zoom) {
    final shouldShowDonation = zoom <= _donationZoomThreshold;
    if (shouldShowDonation == _showDonation || !mounted) return;
    setState(() => _showDonation = shouldShowDonation);
  }

  void _retryStream() => setState(() => _stream = widget.service.watchAll());

  List<PlaceHit> _filter(List<Place> all) {
    final query = _selectedPlaceId == null ? foldVietnamese(_query.trim()) : '';
    final hits = <PlaceHit>[];
    final placesById = {for (final place in all) place.id: place};
    for (final place in _nearbyPlaces) {
      placesById.putIfAbsent(place.id, () => place);
    }
    final placesMatchingCategories = placesById.values.where(
      (place) =>
          _selectedPlaceId == place.id ||
          PlaceCategoryFilter.matches(
            selectedCategories: _selectedCategories,
            placeCategory: place.category,
          ),
    );
    for (final place in deduplicatePlaces(
      placesMatchingCategories,
      preserveDifferentCategories: _selectedCategories.isNotEmpty,
    )) {
      if (query.isNotEmpty &&
          !foldVietnamese('${place.name} ${place.address}').contains(query)) {
        continue;
      }
      final distance = _origin == null
          ? null
          : distanceMeters(_origin!, place.latLng);
      if (distance != null &&
          _radiusKm != null &&
          place.id != _selectedPlaceId &&
          distance > _radiusKm! * 1000) {
        continue;
      }
      if (_selectedPlaceId != place.id &&
          _favoritesOnly &&
          !_favoriteIds.contains(place.id)) {
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

  void _openDetail(PlaceHit hit) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => PlaceDetailScreen(
        hit: hit,
        isOpenStreetMapPlace: _nearbyPlaces.any(
          (place) => place.id == hit.place.id,
        ),
        canUseSatellite: !widget.isGuest,
        onRequireSignIn: _promptSignInFromDetail,
      ),
    ),
  );

  void _promptSignInFromDetail() {
    Navigator.of(context).pop();
    unawaited(_promptSignIn('Xem ảnh vệ tinh'));
  }

  Future<void> _promptSignIn(String feature) async {
    if (!widget.isGuest || widget.onRequireSignIn == null) return;
    final shouldSignIn = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng nhập để tiếp tục'),
        content: Text(
          '$feature chỉ dành cho tài khoản đã đăng nhập. '
          'Đăng nhập để lưu địa điểm yêu thích và tiếp tục sử dụng tính năng này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
    if (shouldSignIn == true && mounted) {
      widget.onRequireSignIn!(feature);
    }
  }

  Future<void> _openImport() async {
    final drafts = widget.draftService;
    if (!widget.isAdmin || drafts == null) return;
    final imported = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => ImportScreen(
          service: drafts,
          locationService: widget.locationService,
          isDraft: true,
        ),
      ),
    );
    if (imported != null && imported > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã lưu $imported địa điểm vào bản nháp.')),
      );
    }
  }

  Future<void> _publishDrafts() async {
    final drafts = widget.draftService;
    if (!widget.isAdmin || drafts == null || _publishing) return;
    late final List<Place> pending;
    try {
      pending = await drafts.watchAll().first;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không đọc được bản nháp: $error')),
      );
      return;
    }
    if (!mounted) return;
    if (pending.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có bản nháp để đăng.')),
      );
      return;
    }
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng địa điểm lên cloud?'),
        content: SizedBox(
          width: 480,
          height: 420,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kiểm tra ${pending.length} bản nháp trước khi đăng. '
                'Địa điểm cùng mã trên Firestore sẽ được cập nhật; '
                'bản nháp trên thiết bị vẫn được giữ lại.',
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: pending.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final place = pending[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(place.name),
                      subtitle: Text('${place.category} • ${place.address}'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Xem lại sau'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng lên'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() => _publishing = true);
    try {
      final count = await widget.service.importAll(pending);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã đăng $count địa điểm lên Firestore.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chưa đăng được bản nháp: $error')),
      );
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _toggleFavorite(Place place) async {
    final favorites = widget.favoriteService;
    if (favorites == null) return;
    final wasFavorite = _favoriteIds.contains(place.id);
    try {
      await favorites.setFavorite(place.id, favorite: !wasFavorite);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không lưu được địa điểm yêu thích: $error')),
      );
    }
  }

  void _handleAction(_NearbyAction action) {
    final operation = switch (action) {
      _NearbyAction.createDraft => _openImport(),
      _NearbyAction.publishDrafts => _publishDrafts(),
      _NearbyAction.updateMapFromOverpass => _updateMapFromOverpass(),
      _NearbyAction.selectMapDataSource => _selectMapDataSource(),
      _NearbyAction.signIn => _openSignIn(),
      _NearbyAction.signOut => _signOut(),
      _NearbyAction.downloadOfflinePlaces => _downloadOfflinePlaces(),
    };
    unawaited(operation);
  }

  Future<void> _openSignIn() async {
    widget.onRequireSignIn?.call('Đăng nhập để lưu địa điểm yêu thích');
  }

  Future<void> _signOut() async {
    try {
      await widget.onSignOut?.call();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không đăng xuất được: $error')));
    }
  }

  Future<void> _downloadOfflinePlaces() async {
    if (widget.isGuest ||
        widget.nearbyPlacesService is! OverpassNearbyPlacesService) {
      _openSignIn();
      return;
    }

    try {
      final count =
          await (widget.nearbyPlacesService! as OverpassNearbyPlacesService)
              .downloadOfflinePlaces();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã tải $count địa điểm để dùng offline.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được dữ liệu offline: $error')),
      );
    }
  }

  Future<void> _updateMapFromOverpass() async {
    if (!widget.isAdmin ||
        widget.nearbyPlacesService is! OverpassNearbyPlacesService) {
      _openSignIn();
      return;
    }
    try {
      final count =
          await (widget.nearbyPlacesService! as OverpassNearbyPlacesService)
              .updateMapFromOverpass();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật $count địa điểm từ Overpass.')),
      );
      _scheduleNearbySearch();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật bản đồ thất bại: $error')),
      );
    }
  }

  Future<void> _selectMapDataSource() async {
    if (!widget.isAdmin ||
        widget.nearbyPlacesService is! OverpassNearbyPlacesService ||
        _selectingMapData) {
      _openSignIn();
      return;
    }

    final service = widget.nearbyPlacesService! as OverpassNearbyPlacesService;
    try {
      final sources = await service.listMapDataSources();
      if (!mounted) return;
      if (sources.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backend chưa có snapshot bản đồ nào.')),
        );
        return;
      }

      final selected = await showDialog<MapDataSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Chọn dữ liệu bản đồ Cao Lãnh'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final source in sources)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      source.active ? Icons.radio_button_checked : Icons.map,
                    ),
                    title: Text(source.label),
                    subtitle: Text(
                      '${source.file} • ${source.count} địa điểm'
                      '${source.updatedAt == null ? '' : '\nCập nhật: ${_formatMapDate(source.updatedAt!)}'}'
                      '${source.active ? '\nĐang sử dụng' : ''}',
                    ),
                    isThreeLine: source.updatedAt != null || source.active,
                    onTap: () => Navigator.of(context).pop(source),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      if (selected == null || selected.active || !mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Dùng ${selected.label.toLowerCase()}?'),
          content: Text(
            'Backend sẽ thay dữ liệu bản đồ đang dùng bằng '
            '${selected.file} (${selected.count} địa điểm). '
            'Các file snapshot mới và cũ sẽ được giữ nguyên.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Áp dụng'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      setState(() => _selectingMapData = true);
      final count = await service.selectMapDataSource(selected.source);
      if (!mounted) return;
      _scheduleNearbySearch();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã dùng ${selected.file}: $count địa điểm.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không chọn được dữ liệu bản đồ: $error')),
      );
    } finally {
      if (mounted) setState(() => _selectingMapData = false);
    }
  }

  String _formatMapDate(DateTime date) {
    final local = date.toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  void _openCaoLanhQuiz() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CaoLanhQuizScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          MediaQuery.sizeOf(context).width < 520
              ? 'Địa điểm'
              : AppStrings.appName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (widget.favoriteService != null)
            IconButton(
              tooltip: _favoritesOnly
                  ? 'Hiện tất cả địa điểm'
                  : 'Chỉ xem địa điểm yêu thích',
              onPressed: () => setState(() => _favoritesOnly = !_favoritesOnly),
              icon: Icon(
                _favoritesOnly ? Icons.favorite : Icons.favorite_border,
              ),
            ),
          IconButton(
            tooltip: _mapMode ? 'Xem danh sách' : 'Xem bản đồ',
            onPressed: () => setState(() => _mapMode = !_mapMode),
            icon: Icon(_mapMode ? Icons.list : Icons.map_outlined),
          ),
          if (_mapMode)
            IconButton(
              tooltip: _searchControlsExpanded
                  ? 'Ẩn bộ tìm kiếm'
                  : 'Hiện bộ tìm kiếm',
              onPressed: () => setState(
                () => _searchControlsExpanded = !_searchControlsExpanded,
              ),
              icon: Icon(
                _searchControlsExpanded ? Icons.expand_less : Icons.search,
              ),
            ),
          IconButton(
            tooltip: 'Dùng GPS',
            onPressed: _locating ? null : _locate,
            icon: const Icon(Icons.my_location),
          ),
          if (widget.isAdmin)
            PopupMenuButton<_NearbyAction>(
              tooltip: 'Công cụ quản trị',
              onSelected: _handleAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _NearbyAction.createDraft,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_location_alt_outlined),
                    title: Text('Tạo bản nháp'),
                  ),
                ),
                PopupMenuItem(
                  value: _NearbyAction.publishDrafts,
                  enabled: !_publishing,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: _publishing
                        ? const SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    title: const Text('Duyệt và đăng bản nháp'),
                  ),
                ),
                const PopupMenuItem(
                  value: _NearbyAction.updateMapFromOverpass,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.sync),
                    title: Text('Cập nhật bản đồ từ Overpass'),
                  ),
                ),
                PopupMenuItem(
                  value: _NearbyAction.selectMapDataSource,
                  enabled: !_selectingMapData,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.layers_outlined),
                    title: Text(
                      _selectingMapData
                          ? 'Đang chọn dữ liệu bản đồ...'
                          : 'Chọn dữ liệu bản đồ Cao Lãnh',
                    ),
                  ),
                ),
              ],
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.admin_panel_settings_outlined),
              ),
            ),
          if (widget.onSignOut != null || widget.isGuest)
            PopupMenuButton<_NearbyAction>(
              tooltip: widget.isGuest ? 'Đăng nhập' : 'Tài khoản',
              onSelected: _handleAction,
              itemBuilder: (context) => [
                if (widget.isGuest)
                  const PopupMenuItem(
                    value: _NearbyAction.signIn,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.login),
                      title: Text('Đăng nhập'),
                    ),
                  ),
                if (widget.userEmail.isNotEmpty)
                  PopupMenuItem<_NearbyAction>(
                    enabled: false,
                    child: Text(widget.userEmail),
                  ),
                if (widget.onSignOut != null)
                  const PopupMenuItem(
                    value: _NearbyAction.downloadOfflinePlaces,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.download_for_offline_outlined),
                      title: Text('Tải dữ liệu Cao Lãnh để dùng offline'),
                    ),
                  ),
                if (widget.onSignOut != null)
                  const PopupMenuItem(
                    value: _NearbyAction.signOut,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.logout),
                      title: Text('Đăng xuất'),
                    ),
                  ),
              ],
              child: Builder(
                builder: (context) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    widget.isGuest
                        ? Icons.login
                        : Icons.account_circle_outlined,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
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
          final hits = _filter(all);
          final showSearchControls = !_mapMode || _searchControlsExpanded;
          return Column(
            children: [
              if (!_mapMode) _DiscoveryBanner(onPlay: _openCaoLanhQuiz),
              if (_favoriteError != null)
                ListTile(
                  leading: Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Không đọc được danh sách yêu thích: $_favoriteError',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (showSearchControls) ...[
                _LocationBar(
                  label: _locating
                      ? 'Đang lấy vị trí...'
                      : _manualLabel ??
                            (_origin != null
                                ? 'Vị trí hiện tại (GPS)'
                                : 'Chưa chọn vị trí — chọn địa điểm hoặc dùng GPS'),
                  isManual: _manualLabel != null,
                  onTap: widget.isGuest
                      ? () => unawaited(_promptSignIn('Tra cứu và chọn vị trí'))
                      : () => _pickLocation(all),
                ),
                if (_mapMode)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(12, 4, 12, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Giữ bản đồ để chọn tâm tìm kiếm, không cần bật GPS.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                _buildFilters(all),
              ],
              if (_searchingNearby) const LinearProgressIndicator(),
              if (_nearbySearchError != null)
                _NearbySearchStatus(
                  message: _nearbySearchErrorMessage(_nearbySearchError!),
                  onRetry: _scheduleNearbySearch,
                )
              else if (_mapMode && hits.isEmpty && !_searchingNearby)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Chưa có địa điểm phù hợp. Hãy đổi vị trí hoặc bộ lọc.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              if (!_mapMode && _nearbyPlaces.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Dữ liệu địa điểm © OpenStreetMap contributors',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ),
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
                    ? Stack(
                        children: [
                          NearbyMap(
                            hits: hits,
                            origin: _origin,
                            selectedPlaceId: _selectedPlaceId,
                            onSelect: _openDetail,
                            onChooseOrigin: _chooseMapOrigin,
                            onZoomChanged: _updateMapZoom,
                            canUseSatellite: !widget.isGuest,
                            onRequireSignIn: () =>
                                unawaited(_promptSignIn('Xem ảnh vệ tinh')),
                            radiusKm: _radiusKm,
                            showTerritorialInfo: _showDonation,
                            zoom: switch (_radiusKm) {
                              null => 11.5,
                              <= 1 => 14.5,
                              <= 5 => 12.5,
                              _ => 11.5,
                            },
                          ),
                          if (_showDonation)
                            Positioned(
                              left: 12,
                              bottom: 12,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surface
                                          .withValues(alpha: 0.94),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        'Đã khóa vùng bản đồ Cao Lãnh',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  FilledButton.icon(
                                    onPressed: _showDonationInfo,
                                    icon: const Icon(Icons.volunteer_activism),
                                    label: const Text(
                                      'Donate cho dự án để nâng cấp bản đồ',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      )
                    : _buildList(hits),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters(List<Place> all) {
    final placesById = <String, Place>{
      for (final place in all) place.id: place,
      for (final place in _nearbyPlaces) place.id: place,
    };
    final matchingPlaces =
        deduplicatePlaces(placesById.values)
            .where(
              (place) =>
                  foldVietnamese('${place.name} ${place.address}')
                      .contains(foldVietnamese(_searchInput.trim())),
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    final suggestionsByName = <String, Place>{};
    if (_searchInput.trim().isNotEmpty) {
      for (final place in matchingPlaces) {
        final name = foldVietnamese(place.name)
            .trim()
            .replaceAll(RegExp(r'\s+'), ' ');
        if (name.isEmpty) continue;

        final current = suggestionsByName[name];
        if (current == null ||
            (_origin != null &&
                distanceMeters(_origin!, place.latLng) <
                    distanceMeters(_origin!, current.latLng))) {
          suggestionsByName[name] = place;
        }
      }
    }
    final suggestions = suggestionsByName.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              OutlinedButton.icon(
                key: const ValueKey('toggle-nearby-filters'),
                onPressed: () =>
                    setState(() => _filtersExpanded = !_filtersExpanded),
                icon: Icon(
                  _filtersExpanded ? Icons.filter_list_off : Icons.filter_list,
                  size: 18,
                ),
                label: const Text('Lọc'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  readOnly: widget.isGuest,
                  onTap: widget.isGuest
                      ? () => unawaited(_promptSignIn('Tìm kiếm địa điểm'))
                      : null,
                  onChanged: widget.isGuest
                      ? null
                      : (value) => setState(() {
                          _searchInput = value;
                          _selectedPlaceId = null;
                        }),
                  decoration: InputDecoration(
                    hintText: widget.isGuest
                        ? 'Đăng nhập để tìm kiếm địa điểm'
                        : 'Tìm theo tên hoặc địa chỉ',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchInput.isNotEmpty)
                          IconButton(
                            tooltip: 'Xóa tìm kiếm',
                            icon: const Icon(Icons.clear),
                            onPressed: widget.isGuest
                                ? () => unawaited(
                                    _promptSignIn('Tìm kiếm địa điểm'),
                                  )
                                : () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchInput = '';
                                      _query = '';
                                      _selectedPlaceId = null;
                                    });
                                  },
                          ),
                        IconButton(
                          tooltip: 'Tìm địa điểm',
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: widget.isGuest
                              ? () => unawaited(
                                  _promptSignIn('Tìm kiếm địa điểm'),
                                )
                              : () => setState(() {
                                  _query = _searchInput;
                                  _selectedPlaceId = null;
                                }),
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radius),
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (suggestions.isNotEmpty)
          Card(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Column(
              children: [
                for (final place in suggestions)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.place_outlined),
                    title: Text(place.name),
                    subtitle: place.address.isEmpty
                        ? null
                        : Text(
                            place.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                    onTap: () {
                      setState(() {
                        _searchInput = place.name;
                        _query = '';
                        _selectedPlaceId = place.id;
                        _searchController.text = place.name;
                        _mapMode = true;
                        _searchControlsExpanded = false;
                      });
                    },
                  ),
              ],
            ),
          ),
        if (_filtersExpanded) ...[
          NearbyFilterChips(
            selectedCategories: _selectedCategories,
            selectedRadiusKm: _radiusKm,
            showRadius: _origin != null,
            onCategorySelected: (category) {
              if (widget.isGuest) {
                unawaited(_promptSignIn('Lọc địa điểm'));
                return;
              }
              setState(() {
                if (category == 'all') {
                  _selectedCategories.clear();
                } else if (!_selectedCategories.add(category)) {
                  _selectedCategories.remove(category);
                }
              });
            },
            onRadiusSelected: (radiusKm) {
              if (widget.isGuest) {
                unawaited(_promptSignIn('Lọc địa điểm'));
                return;
              }
              setState(() => _radiusKm = radiusKm);
              _scheduleNearbySearch();
            },
          ),
        ],
      ],
    );
  }

  void _showDonationInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đóng góp cho dự án'),
        content: const Text(
          'Cảm ơn bạn đã quan tâm. Thông tin đóng góp sẽ được cập nhật '
          'khi dự án hoàn thiện kênh tiếp nhận.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<PlaceHit> hits) {
    if (hits.isEmpty) {
      if (_favoritesOnly) {
        return const EmptyView(message: 'Bạn chưa lưu địa điểm yêu thích nào.');
      }
      final radius = _origin != null && _radiusKm != null
          ? ' trong bán kính ${NearbyFilterChips.radiusLabel(_radiusKm)}'
          : '';
      return EmptyView(
        message:
            'Không có địa điểm nào$radius.\nThử tăng bán kính hoặc đổi bộ lọc.',
      );
    }
    return ListView.builder(
      key: const ValueKey('nearby-places-list'),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: hits.length,
      itemBuilder: (context, index) => PlaceTile(
        hit: hits[index],
        onTap: () => _openDetail(hits[index]),
        isFavorite: _favoriteIds.contains(hits[index].place.id),
        onFavoriteTap: widget.favoriteService == null
            ? null
            : () => _toggleFavorite(hits[index].place),
      ),
    );
  }
}

class _NearbySearchStatus extends StatelessWidget {
  const _NearbySearchStatus({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: Material(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
          child: Row(
            children: [
              Icon(Icons.cloud_off_outlined, color: colors.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onErrorContainer,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Thử tìm lại',
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
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

class _DiscoveryBanner extends StatelessWidget {
  const _DiscoveryBanner({required this.onPlay});

  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 600;
    return Padding(
      padding: EdgeInsets.fromLTRB(isWide ? 16 : 12, 12, isWide ? 16 : 12, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: isWide ? 190 : 176,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/splash/launch.jpg',
                fit: BoxFit.cover,
                alignment: const Alignment(0, 0.32),
                semanticLabel: 'Cảnh quan một điểm đến địa phương',
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xD9102B22), Color(0x40102B22)],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isWide ? 28 : 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KHÁM PHÁ ĐỊA ĐIỂM',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.86),
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tìm điểm đến quanh bạn',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                shadows: const [
                                  Shadow(color: Colors.black45, blurRadius: 8),
                                ],
                              ),
                        ),
                        if (isWide) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Quán ăn, cà phê và điểm vui chơi ở một nơi.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.white),
                          ),
                        ],
                        const SizedBox(height: 8),
                        FilledButton.tonalIcon(
                          onPressed: onPlay,
                          icon: const Icon(Icons.style_outlined, size: 18),
                          label: const Text('Chơi mini game Cao Lãnh'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
