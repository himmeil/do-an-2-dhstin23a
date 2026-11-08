import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/config/display_preferences.dart';
import '../../../core/utils/text_utils.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../dia_diem/ban_do/cao_lanh_ward_boundary.dart';
import '../../dia_diem/ban_do/widgets/nearby_map.dart';
import '../../dia_diem/chi_tiet/screens/place_detail_screen.dart';
import '../../dia_diem/du_lieu/models/place.dart';
import '../../dia_diem/du_lieu/models/place_category_registry.dart';
import '../../dia_diem/du_lieu/repositories/place_comment_repository.dart';
import '../../dia_diem/du_lieu/repositories/place_repository.dart';
import '../../gps/services/location_service.dart';
import '../../mini_game/screens/cao_lanh_quiz_screen.dart';
import '../bo_loc/services/place_category_filter.dart';
import '../bo_loc/widgets/nearby_filter_chips.dart';
import '../services/admin_error_log_service.dart';
import '../services/geocoding_service.dart';
import '../services/nearby_places_service.dart';
import '../utils/geo.dart';
import '../widgets/display_settings_sheet.dart';
import '../widgets/location_picker_sheet.dart';
import '../widgets/place_tile.dart';

enum _NearbyAction { signIn, signOut, displaySettings }

/// Màn chính: tìm địa điểm quanh vị trí hiện tại, lọc theo loại / bán kính /
/// từ khóa, xem dạng danh sách hoặc bản đồ.
class NearbyScreen extends StatefulWidget {
  const NearbyScreen({
    required this.service,
    required this.locationService,
    required this.geocoder,
    this.nearbyPlacesService,
    this.adminErrorLogService,
    this.commentService,
    this.favoriteService,
    this.userEmail = '',
    this.isAdmin = false,
    this.isGuest = false,
    this.onRequireSignIn,
    this.onSignOut,
    this.onOpenAdminManagement,
    super.key,
  });

  final PlaceService service;
  final FavoriteService? favoriteService;
  final LocationService locationService;
  final GeocodingService geocoder;
  final NearbyPlacesService? nearbyPlacesService;
  final AdminErrorLogService? adminErrorLogService;
  final PlaceCommentService? commentService;
  final String userEmail;
  final bool isAdmin;
  final bool isGuest;
  final ValueChanged<String>? onRequireSignIn;
  final Future<void> Function()? onSignOut;
  final VoidCallback? onOpenAdminManagement;

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  static const _graphicsQualityPreferenceKey = 'map_graphics_quality_v1';
  static const _animationsPreferenceKey = 'display_animations_enabled_v1';

  late Future<void> _displayPreferencesLoad;
  late Stream<List<Place>> _stream = widget.service.watchAll();
  final _searchController = TextEditingController();
  final Set<String> _favoriteIds = {};
  StreamSubscription<Set<String>>? _favoriteSubscription;
  Timer? _nearbySearchDebounce;
  String? _favoriteError;
  String? _nearbySearchError;
  final Set<AdminErrorCode> _reportedAdminErrorCodes = {};
  bool _adminErrorLogWriteFailed = false;
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
  bool _showDonation = false;
  MapGraphicsQuality _graphicsQuality = MapGraphicsQuality.medium;
  bool _animationsEnabled = true;
  List<Place>? _cachedFilterAll;
  List<Place>? _cachedFilterNearbyPlaces;
  List<Place>? _filterIndexAllSource;
  List<Place>? _filterIndexNearbySource;
  LatLng? _filterIndexOrigin;
  bool _filterIndexReady = false;
  List<Place> _filterPlacesWithoutCategoryPreservation = const [];
  List<Place> _filterPlacesPreservingCategories = const [];
  List<_IndexedPlace> _filterEntriesWithoutCategoryPreservation = const [];
  List<_IndexedPlace> _filterEntriesPreservingCategories = const [];
  Set<String> _cachedFilterCategories = const {};
  Set<String> _cachedFilterFavoriteIds = const {};
  LatLng? _cachedFilterOrigin;
  double? _cachedFilterRadiusKm;
  String _cachedFilterQuery = '';
  String? _cachedFilterSelectedPlaceId;
  bool _cachedFilterFavoritesOnly = false;
  List<PlaceHit>? _cachedFilteredHits;

  static const _minMapZoom = 11.0;
  static const _maxMapZoom = 18.0;
  static const _farZoomVisibilityFraction = 0.5;
  static const _donationZoomThreshold =
      _minMapZoom + (_maxMapZoom - _minMapZoom) * _farZoomVisibilityFraction;

  @override
  void initState() {
    super.initState();
    _displayPreferencesLoad = _loadDisplayPreferences();
    _favoriteSubscription = widget.favoriteService?.watchIds().listen(
      (ids) {
        if (!mounted) return;
        setState(() {
          _favoriteIds
            ..clear()
            ..addAll(ids);
          _favoriteError = null;
        });
        _reportedAdminErrorCodes.remove(AdminErrorCode.favoritesStreamFailed);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!mounted) return;
        _recordAdminError(AdminErrorCode.favoritesStreamFailed);
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
    if (result.failure == null) {
      _reportedAdminErrorCodes.remove(AdminErrorCode.locationLookupFailed);
    } else {
      _recordAdminError(AdminErrorCode.locationLookupFailed);
    }
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
        _reportedAdminErrorCodes.remove(AdminErrorCode.nearbySearchFailed);
      } catch (error) {
        if (!mounted || request != _nearbySearchRequest) return;
        _recordAdminError(
          error is NearbyPlacesFailure
              ? error.code
              : AdminErrorCode.nearbySearchFailed,
        );
        setState(() {
          _searchingNearby = false;
          _nearbySearchError = error.toString();
        });
      }
    });
  }

  String _nearbySearchErrorMessage(String error) {
    if (error.contains(AdminErrorCode.nearbySnapshotReadFailed.value)) {
      return 'Không đọc được dữ liệu bản đồ OpenStreetMap đã đóng gói. '
          'Hãy báo quản trị viên kiểm tra bản cập nhật.';
    }
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

  void _recordAdminError(AdminErrorCode code) {
    final service = widget.adminErrorLogService;
    if (!widget.isAdmin ||
        service == null ||
        !_reportedAdminErrorCodes.add(code)) {
      return;
    }
    unawaited(_saveAdminError(service, code));
  }

  Future<void> _saveAdminError(
    AdminErrorLogService service,
    AdminErrorCode code,
  ) async {
    try {
      await service.record(code);
      if (mounted && _adminErrorLogWriteFailed) {
        setState(() => _adminErrorLogWriteFailed = false);
      }
    } catch (error) {
      _reportedAdminErrorCodes.remove(code);
      if (!mounted) return;
      debugPrint(
        'Could not save admin error code ${code.value} '
        '(${error.runtimeType}).',
      );
      setState(() => _adminErrorLogWriteFailed = true);
    }
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
    if (_cachedFilteredHits != null &&
        identical(all, _cachedFilterAll) &&
        identical(_nearbyPlaces, _cachedFilterNearbyPlaces) &&
        _sameValues(_selectedCategories, _cachedFilterCategories) &&
        _sameValues(_favoriteIds, _cachedFilterFavoriteIds) &&
        _sameLocation(_origin, _cachedFilterOrigin) &&
        _radiusKm == _cachedFilterRadiusKm &&
        _query == _cachedFilterQuery &&
        _selectedPlaceId == _cachedFilterSelectedPlaceId &&
        _favoritesOnly == _cachedFilterFavoritesOnly) {
      return _cachedFilteredHits!;
    }

    final hits = _selectedPlaceId == null
        ? _filterIndexed(all)
        : _filterSelectedPlace(all);
    _cachedFilterAll = all;
    _cachedFilterNearbyPlaces = _nearbyPlaces;
    _cachedFilterCategories = Set.of(_selectedCategories);
    _cachedFilterFavoriteIds = Set.of(_favoriteIds);
    _cachedFilterOrigin = _origin;
    _cachedFilterRadiusKm = _radiusKm;
    _cachedFilterQuery = _query;
    _cachedFilterSelectedPlaceId = _selectedPlaceId;
    _cachedFilterFavoritesOnly = _favoritesOnly;
    return _cachedFilteredHits = List.unmodifiable(hits);
  }

  List<PlaceHit> _filterIndexed(List<Place> all) {
    _ensureFilterIndex(all);
    final entries = _selectedCategories.isEmpty
        ? _filterEntriesWithoutCategoryPreservation
        : _filterEntriesPreservingCategories;
    final selectedCategories = _selectedCategories
        .map(parseCategoryCode)
        .toSet();
    final query = _selectedPlaceId == null ? foldVietnamese(_query.trim()) : '';
    final hits = <PlaceHit>[];
    for (final entry in entries) {
      if (selectedCategories.isNotEmpty &&
          !selectedCategories.contains(entry.category)) {
        continue;
      }
      if (query.isNotEmpty && !entry.searchText.contains(query)) {
        continue;
      }
      final distance = entry.distance;
      if (distance != null &&
          _radiusKm != null &&
          distance > _radiusKm! * 1000) {
        continue;
      }
      if (_favoritesOnly && !_favoriteIds.contains(entry.place.id)) {
        continue;
      }
      hits.add(PlaceHit(entry.place, distance));
    }
    return hits;
  }

  List<PlaceHit> _filterSelectedPlace(List<Place> all) {
    final query = _selectedPlaceId == null ? foldVietnamese(_query.trim()) : '';
    final placesById = {for (final place in all) place.id: place};
    for (final place in _nearbyPlaces) {
      placesById.putIfAbsent(place.id, () => place);
    }
    final matchingCategories = placesById.values.where(
      (place) =>
          place.id == _selectedPlaceId ||
          PlaceCategoryFilter.matches(
            selectedCategories: _selectedCategories,
            placeCategory: place.category,
          ),
    );
    final hits = <PlaceHit>[];
    for (final place in deduplicatePlaces(
      matchingCategories,
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
      if (place.id != _selectedPlaceId &&
          _favoritesOnly &&
          !_favoriteIds.contains(place.id)) {
        continue;
      }
      hits.add(PlaceHit(place, distance));
    }
    hits.sort(_compareHits);
    return hits;
  }

  void _ensureFilterIndex(List<Place> all) {
    if (!identical(all, _filterIndexAllSource) ||
        !identical(_nearbyPlaces, _filterIndexNearbySource)) {
      final placesById = {for (final place in all) place.id: place};
      for (final place in _nearbyPlaces) {
        placesById.putIfAbsent(place.id, () => place);
      }
      final places = placesById.values.toList(growable: false);
      _filterPlacesWithoutCategoryPreservation = deduplicatePlaces(places);
      _filterPlacesPreservingCategories = deduplicatePlaces(
        places,
        preserveDifferentCategories: true,
      );
      _filterIndexAllSource = all;
      _filterIndexNearbySource = _nearbyPlaces;
      _filterIndexReady = false;
    }

    if (!_filterIndexReady || !_sameLocation(_origin, _filterIndexOrigin)) {
      final entriesById = <String, _IndexedPlace>{
        for (final place in _filterPlacesPreservingCategories)
          place.id: _IndexedPlace(
            place: place,
            category: parseCategoryCode(place.category),
            searchText: foldVietnamese('${place.name} ${place.address}'),
            distance: _origin == null
                ? null
                : distanceMeters(_origin!, place.latLng),
          ),
      };
      _filterEntriesWithoutCategoryPreservation = _createFilterEntries(
        _filterPlacesWithoutCategoryPreservation,
        entriesById,
      );
      _filterEntriesPreservingCategories = _createFilterEntries(
        _filterPlacesPreservingCategories,
        entriesById,
      );
      _filterIndexOrigin = _origin;
      _filterIndexReady = true;
    }
  }

  List<_IndexedPlace> _createFilterEntries(
    List<Place> places,
    Map<String, _IndexedPlace> entriesById,
  ) {
    final entries = places.map((place) => entriesById[place.id]!).toList();
    entries.sort((a, b) {
      if (a.distance != null && b.distance != null) {
        return a.distance!.compareTo(b.distance!);
      }
      return a.place.name.compareTo(b.place.name);
    });
    return List.unmodifiable(entries);
  }

  int _compareHits(PlaceHit first, PlaceHit second) {
    if (first.distance != null && second.distance != null) {
      return first.distance!.compareTo(second.distance!);
    }
    return first.place.name.compareTo(second.place.name);
  }

  bool _sameValues(Set<String> first, Set<String> second) =>
      first.length == second.length && first.containsAll(second);

  bool _sameLocation(LatLng? first, LatLng? second) =>
      identical(first, second) ||
      (first != null &&
          second != null &&
          first.latitude == second.latitude &&
          first.longitude == second.longitude);

  void _openDetail(PlaceHit hit) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => PlaceDetailScreen(
        hit: hit,
        commentService: widget.commentService,
        onAdminError: _recordAdminError,
        isSignedIn: !widget.isGuest,
        accountName: widget.userEmail,
        isOpenStreetMapPlace: _nearbyPlaces.any(
          (place) => place.id == hit.place.id,
        ),
        canUseSatellite: !widget.isGuest,
        onRequireSignIn: () => unawaited(_promptSignIn('Xem ảnh vệ tinh')),
        onRequireCommentSignIn: () => unawaited(_promptSignIn('Bình luận')),
      ),
    ),
  );

  Future<void> _promptSignIn(String feature) async {
    if (!widget.isGuest || widget.onRequireSignIn == null) return;
    final shouldSignIn = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng nhập để tiếp tục'),
        content: Text('$feature chỉ dành cho tài khoản đã đăng nhập.'),
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
      if (const {'Bình luận', 'Xem ảnh vệ tinh'}.contains(feature) &&
          Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      widget.onRequireSignIn!(feature);
    }
  }

  Future<void> _toggleFavorite(Place place) async {
    final favorites = widget.favoriteService;
    if (favorites == null) return;
    final wasFavorite = _favoriteIds.contains(place.id);
    try {
      await favorites.setFavorite(place.id, favorite: !wasFavorite);
    } catch (error) {
      _recordAdminError(AdminErrorCode.favoriteWriteFailed);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không lưu được địa điểm yêu thích: $error')),
      );
    }
  }

  void _handleAction(_NearbyAction action) {
    final operation = switch (action) {
      _NearbyAction.signIn => _openSignIn(),
      _NearbyAction.signOut => _signOut(),
      _NearbyAction.displaySettings => _openDisplaySettings(),
    };
    unawaited(operation);
  }

  Future<void> _loadDisplayPreferences() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _graphicsQuality = MapGraphicsQuality.fromStorage(
          preferences.getString(_graphicsQualityPreferenceKey),
        );
        _animationsEnabled =
            preferences.getBool(_animationsPreferenceKey) ?? true;
      });
    } catch (error) {
      _recordAdminError(AdminErrorCode.displayPreferencesReadFailed);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được cài đặt hiển thị: $error')),
      );
    }
  }

  Future<void> _openDisplaySettings() async {
    await _displayPreferencesLoad;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DisplaySettingsSheet(
        graphicsQuality: _graphicsQuality,
        animationsEnabled: _animationsEnabled,
        onGraphicsQualityChanged: _saveGraphicsQuality,
        onAnimationsChanged: _saveAnimationPreference,
      ),
    );
  }

  Future<bool> _saveGraphicsQuality(MapGraphicsQuality quality) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setString(
        _graphicsQualityPreferenceKey,
        quality.name,
      );
      if (!saved) throw StateError('Không lưu được chất lượng đồ họa.');
      if (mounted) setState(() => _graphicsQuality = quality);
      return true;
    } catch (error) {
      _recordAdminError(AdminErrorCode.displayPreferencesWriteFailed);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không lưu được cài đặt đồ họa: $error')),
        );
      }
      return false;
    }
  }

  Future<bool> _saveAnimationPreference(bool enabled) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setBool(
        _animationsPreferenceKey,
        enabled,
      );
      if (!saved) throw StateError('Không lưu được cài đặt hiệu ứng.');
      if (mounted) setState(() => _animationsEnabled = enabled);
      return true;
    } catch (error) {
      _recordAdminError(AdminErrorCode.displayPreferencesWriteFailed);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không lưu được cài đặt hiệu ứng: $error')),
        );
      }
      return false;
    }
  }

  Future<void> _openSignIn() async {
    widget.onRequireSignIn?.call('Đăng nhập để lưu địa điểm yêu thích');
  }

  Future<void> _signOut() async {
    try {
      await widget.onSignOut?.call();
    } catch (error) {
      _recordAdminError(AdminErrorCode.signOutFailed);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không đăng xuất được: $error')));
    }
  }

  void _openCaoLanhQuiz() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CaoLanhQuizScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final animationsEnabled =
        _animationsEnabled && !MediaQuery.disableAnimationsOf(context);
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
          if (!widget.isGuest && widget.favoriteService != null)
            IconButton(
              tooltip: _favoritesOnly
                  ? 'Hiện tất cả địa điểm'
                  : 'Chỉ xem địa điểm yêu thích',
              onPressed: () => setState(() => _favoritesOnly = !_favoritesOnly),
              icon: Icon(
                _favoritesOnly ? Icons.favorite : Icons.favorite_border,
              ),
            ),
          if (!widget.isGuest)
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
          if (!widget.isGuest)
            IconButton(
              tooltip: 'Dùng GPS',
              onPressed: _locating ? null : _locate,
              icon: const Icon(Icons.my_location),
            ),
          if (widget.isAdmin && widget.onOpenAdminManagement != null)
            IconButton(
              tooltip: 'Trang quản lý',
              onPressed: widget.onOpenAdminManagement,
              icon: const Icon(Icons.admin_panel_settings_outlined),
            ),
          if (widget.onSignOut != null || widget.isGuest)
            PopupMenuButton<_NearbyAction>(
              tooltip: widget.isGuest ? 'Đăng nhập' : 'Tài khoản',
              onSelected: _handleAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _NearbyAction.displaySettings,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.tune),
                    title: Text('Cài đặt hiển thị'),
                  ),
                ),
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
            _recordAdminError(AdminErrorCode.placesStreamFailed);
            return ErrorView(
              message: 'Chưa tải được danh sách địa điểm.',
              onRetry: _retryStream,
            );
          }
          _reportedAdminErrorCodes.remove(AdminErrorCode.placesStreamFailed);
          if (snapshot.connectionState == ConnectionState.waiting &&
              !_mapMode) {
            return const ColoredBox(
              color: Color(0xFFE7F5FC),
              child: LoadingView(),
            );
          }
          final all = snapshot.data ?? const <Place>[];
          final hits = _filter(all);
          final loadingPlaces =
              snapshot.connectionState == ConnectionState.waiting;
          final showSearchControls = !_mapMode || _searchControlsExpanded;
          final content = Column(
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
              if (_adminErrorLogWriteFailed && widget.isAdmin)
                const ListTile(
                  leading: Icon(Icons.cloud_off_outlined),
                  title: Text(
                    'Không lưu được mã lỗi vào Firestore. '
                    'Kiểm tra kết nối và Firestore Rules.',
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
              if (loadingPlaces) const LinearProgressIndicator(),
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
                child: AnimatedSwitcher(
                  duration: animationsEnabled
                      ? const Duration(milliseconds: 220)
                      : Duration.zero,
                  child: _mapMode
                      ? Stack(
                          key: const ValueKey('nearby-map-view'),
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
                              graphicsQuality: _graphicsQuality,
                              animationsEnabled: animationsEnabled,
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
                                      icon: const Icon(
                                        Icons.volunteer_activism,
                                      ),
                                      label: const Text(
                                        'Donate cho dự án để nâng cấp bản đồ',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        )
                      : KeyedSubtree(
                          key: const ValueKey('nearby-list-view'),
                          child: _buildList(hits),
                        ),
                ),
              ),
            ],
          );
          return _mapMode
              ? content
              : ColoredBox(
                  key: const ValueKey('nearby-list-background'),
                  color: const Color(0xFFE7F5FC),
                  child: content,
                );
        },
      ),
    );
  }

  Widget _buildFilters(List<Place> all) {
    final suggestionsByName = <String, Place>{};
    if (_searchInput.trim().isNotEmpty) {
      final placesById = <String, Place>{
        for (final place in all) place.id: place,
        for (final place in _nearbyPlaces) place.id: place,
      };
      final query = foldVietnamese(_searchInput.trim());
      final matchingPlaces =
          deduplicatePlaces(placesById.values)
              .where(
                (place) =>
                    foldVietnamese('${place.name} ${place.address}')
                        .contains(query),
              )
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
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
                  onChanged: (value) => setState(() {
                    _searchInput = value;
                    _selectedPlaceId = null;
                  }),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên hoặc địa chỉ',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchInput.isNotEmpty)
                          IconButton(
                            tooltip: 'Xóa tìm kiếm',
                            icon: const Icon(Icons.clear),
                            onPressed: () {
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
                          onPressed: () => setState(() {
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
              setState(() {
                if (category == 'all') {
                  _selectedCategories.clear();
                } else if (!_selectedCategories.add(category)) {
                  _selectedCategories.remove(category);
                }
              });
            },
            onRadiusSelected: (radiusKm) {
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
      itemBuilder: (context, index) {
        final hit = hits[index];
        return PlaceTile(
          hit: hit,
          onTap: () => _openDetail(hit),
          isFavorite: _favoriteIds.contains(hit.place.id),
          onFavoriteTap: widget.favoriteService == null
              ? null
              : () => _toggleFavorite(hit.place),
          floralStyle: true,
          floralIndex: index,
        );
      },
    );
  }
}

class _IndexedPlace {
  const _IndexedPlace({
    required this.place,
    required this.category,
    required this.searchText,
    required this.distance,
  });

  final Place place;
  final String category;
  final String searchText;
  final double? distance;
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
