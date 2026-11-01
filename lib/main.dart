import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/splash/startup_splash.dart';
import 'features/tai_khoan/screens/sign_in_screen.dart';
import 'features/tai_khoan/services/auth_service.dart';
import 'features/dia_diem/gps/services/location_service.dart';
import 'features/dia_diem/tim_kiem/screens/nearby_screen.dart';
import 'features/dia_diem/tim_kiem/services/geocoding_service.dart';
import 'features/dia_diem/tim_kiem/services/nearby_places_service.dart';
import 'features/dia_diem/du_lieu/services/place_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(NearbyApp());
}

class NearbyApp extends StatelessWidget {
  NearbyApp({super.key});

  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: _AuthGate(authService: _authService),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate({required this.authService});

  final AuthService authService;

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _guestMode = false;
  String? _signInPrompt;

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
          return NearbyScreen(
            service: FirestorePlaceService(),
            locationService: const GeolocatorLocationService(),
            geocoder: NominatimGeocodingService(),
            nearbyPlacesService: OverpassNearbyPlacesService(),
            isGuest: true,
            onRequireSignIn: _requireSignIn,
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
          return StartupSplash(
            child: NearbyScreen(
              service: FirestorePlaceService(),
              draftService: LocalPlaceService(
                storageKey: LocalPlaceService.adminDraftStorageKey,
              ),
              locationService: const GeolocatorLocationService(),
              geocoder: NominatimGeocodingService(),
              nearbyPlacesService: OverpassNearbyPlacesService(),
              favoriteService: FirestoreFavoriteService(userId: user.uid),
              userEmail: user.email ?? '',
              isAdmin: roleSnapshot.data!,
              onSignOut: widget.authService.signOut,
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
