import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/splash/startup_splash.dart';
import 'features/dia_diem/gps/services/location_service.dart';
import 'features/dia_diem/tim_kiem/screens/nearby_screen.dart';
import 'features/dia_diem/tim_kiem/services/geocoding_service.dart';
import 'features/dia_diem/du_lieu/services/place_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NearbyApp());
}

class NearbyApp extends StatelessWidget {
  const NearbyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final nearbyScreen = NearbyScreen(
      service: LocalPlaceService(),
      locationService: const GeolocatorLocationService(),
      geocoder: NominatimGeocodingService(),
    );
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: StartupSplash(child: nearbyScreen),
    );
  }
}
