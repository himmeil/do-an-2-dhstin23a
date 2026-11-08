import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/config/app_environment.dart';
import 'core/config/app_links.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/splash/startup_splash.dart';
import 'features/admin/screens/admin_management_screen.dart';
import 'features/tai_khoan/screens/sign_in_screen.dart';
import 'features/tai_khoan/services/auth_service.dart';
import 'features/dia_diem/services/firestore_place_service.dart';
import 'features/dia_diem/services/firestore_place_comment_service.dart';
import 'features/dia_diem/services/local_place_comment_service.dart';
import 'features/dia_diem/services/local_place_service.dart';
import 'features/dia_diem/du_lieu/repositories/place_comment_repository.dart';
import 'features/gps/services/location_service.dart';
import 'features/tim_kiem/screens/nearby_screen.dart';
import 'features/tim_kiem/services/admin_error_log_service.dart';
import 'features/tim_kiem/services/geocoding_service.dart';
import 'features/tim_kiem/services/nearby_places_service.dart';
import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    NearbyApp(
      initializeFirebase: () => Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
    ),
  );
}

class NearbyApp extends StatelessWidget {
  const NearbyApp({
    required this.initializeFirebase,
    this.isLocalMode,
    super.key,
  });

  final Future<FirebaseApp> Function() initializeFirebase;
  final bool? isLocalMode;

  @override
  Widget build(BuildContext context) {
    final useLocalMode = isLocalMode ?? AppEnvironment.isLocalMode;
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: useLocalMode
          ? const _LocalModeHome()
          : _FirebaseBootstrap(
              initializeFirebase: initializeFirebase,
              childBuilder: (_) => _AuthGate(authService: AuthService()),
            ),
    );
  }
}

class _LocalModeHome extends StatelessWidget {
  const _LocalModeHome();

  @override
  Widget build(BuildContext context) => StartupSplash(
    child: NearbyScreen(
      service: LocalPlaceService(),
      locationService: const GeolocatorLocationService(),
      geocoder: NominatimGeocodingService(),
      nearbyPlacesService: OverpassNearbyPlacesService(),
    ),
  );
}

class _FirebaseBootstrap extends StatefulWidget {
  const _FirebaseBootstrap({
    required this.initializeFirebase,
    required this.childBuilder,
  });

  final Future<FirebaseApp> Function() initializeFirebase;
  final WidgetBuilder childBuilder;

  @override
  State<_FirebaseBootstrap> createState() => _FirebaseBootstrapState();
}

class _FirebaseBootstrapState extends State<_FirebaseBootstrap> {
  late Future<FirebaseApp> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = Future<FirebaseApp>.sync(widget.initializeFirebase);
  }

  void _retry() {
    setState(() {
      _initialization = Future<FirebaseApp>.sync(widget.initializeFirebase);
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<FirebaseApp>(
    future: _initialization,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _FirebaseBootstrapLoading();
      }
      if (snapshot.hasError) {
        return _FirebaseBootstrapError(onRetry: _retry);
      }
      if (!snapshot.hasData) return const _FirebaseBootstrapLoading();
      return widget.childBuilder(context);
    },
  );
}

class _FirebaseBootstrapLoading extends StatelessWidget {
  const _FirebaseBootstrapLoading();

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Color(0xFFE7F5FC),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_florist, size: 48, color: Color(0xFF3B8EBA)),
          SizedBox(height: 16),
          CircularProgressIndicator(color: Color(0xFF3B8EBA)),
          SizedBox(height: 12),
          Text('Đang khởi tạo ứng dụng...'),
        ],
      ),
    ),
  );
}

class _FirebaseBootstrapError extends StatelessWidget {
  const _FirebaseBootstrapError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFE7F5FC),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 40,
              color: Color(0xFF2879A8),
            ),
            const SizedBox(height: 12),
            const Text(
              'Chưa thể kết nối Firebase để khởi động ứng dụng.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text('Mã lỗi: FIREBASE_INIT_FAILED'),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    ),
  );
}

class _AuthGate extends StatefulWidget {
  const _AuthGate({required this.authService});

  final AuthService authService;

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  final _nearbyPlacesService = OverpassNearbyPlacesService(
    getIdToken: () async =>
        await FirebaseAuth.instance.currentUser?.getIdToken(),
  );
  late final _localPlaceCommentService = LocalPlaceCommentService(
    apiBaseUrl: AppLinks.nearbyApiBaseUrl,
    getIdToken: () async =>
        await FirebaseAuth.instance.currentUser?.getIdToken(),
  );
  bool _guestMode = false;
  String? _signInPrompt;

  PlaceCommentService _commentService({User? user}) {
    if (AppEnvironment.isLocalWeb) {
      return _localPlaceCommentService;
    }
    return FirestorePlaceCommentService(userId: user?.uid);
  }

  void _continueAsGuest() {
    setState(() {
      _guestMode = true;
      _signInPrompt = null;
    });
  }

  void _requireSignIn(String reason) {
    setState(() {
      _guestMode = false;
      _signInPrompt =
          '$reason cần đăng nhập. Đăng nhập để lưu địa điểm yêu thích.';
    });
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: widget.authService.authStateChanges(),
    builder: (context, authSnapshot) {
      if (authSnapshot.hasError) {
        return _AuthError(message: 'Không kiểm tra được trạng thái đăng nhập.');
      }
      if (authSnapshot.connectionState == ConnectionState.waiting) {
        return const _AuthLoading();
      }
      final user = authSnapshot.data;
      if (user == null) {
        if (_guestMode) {
          return StartupSplash(
            child: NearbyScreen(
              service: FirestorePlaceService(),
              locationService: const GeolocatorLocationService(),
              geocoder: NominatimGeocodingService(),
              nearbyPlacesService: _nearbyPlacesService,
              commentService: _commentService(),
              isGuest: true,
              onRequireSignIn: _requireSignIn,
            ),
          );
        }
        return SignInScreen(
          promptMessage: _signInPrompt,
          onContinueAsGuest: _continueAsGuest,
          onSubmit: ({required email, required password, required register}) =>
              register
              ? widget.authService.register(email: email, password: password)
              : widget.authService.signIn(email: email, password: password),
        );
      }
      return StreamBuilder<bool>(
        stream: widget.authService.watchIsAdmin(user.uid),
        builder: (context, roleSnapshot) {
          if (roleSnapshot.hasError) {
            return _AuthError(
              message:
                  'Không xác định được quyền tài khoản. '
                  'Kiểm tra kết nối và Firestore Rules.',
            );
          }
          if (!roleSnapshot.hasData) return const _AuthLoading();
          final isAdmin = roleSnapshot.data!;
          final draftService = LocalPlaceService(
            storageKey: LocalPlaceService.adminDraftStorageKey,
          );
          final adminErrorLogService = isAdmin
              ? FirestoreAdminErrorLogService()
              : null;
          return StartupSplash(
            child: NearbyScreen(
              service: FirestorePlaceService(),
              locationService: const GeolocatorLocationService(),
              geocoder: NominatimGeocodingService(),
              nearbyPlacesService: _nearbyPlacesService,
              adminErrorLogService: adminErrorLogService,
              commentService: _commentService(user: user),
              favoriteService: FirestoreFavoriteService(userId: user.uid),
              userEmail: user.email ?? '',
              isAdmin: isAdmin,
              onSignOut: widget.authService.signOut,
              onOpenAdminManagement: isAdmin
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AdminManagementScreen(
                            isAdmin: isAdmin,
                            placeService: FirestorePlaceService(),
                            draftService: draftService,
                            locationService: const GeolocatorLocationService(),
                            nearbyPlacesService: _nearbyPlacesService,
                            adminErrorLogService: adminErrorLogService!,
                          ),
                        ),
                      );
                    }
                  : null,
            ),
          );
        },
      );
    },
  );
}

class _AuthLoading extends StatelessWidget {
  const _AuthLoading();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _AuthError extends StatelessWidget {
  const _AuthError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    ),
  );
}
