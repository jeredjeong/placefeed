import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:myapp/firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:myapp/src/theme/theme_provider.dart';
import 'package:myapp/src/routing/app_router.dart';
import 'package:myapp/src/services/auth_service.dart'; // Import AuthService
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Import Google Mobile Ads
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:google_maps_flutter_web/google_maps_flutter_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleMapsFlutterPlatform.instance = GoogleMapsFlutterWeb(); // Register the web implementation
  await MobileAds.instance.initialize(); // Initialize Google Mobile Ads SDK
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider( // Use MultiProvider to provide multiple ChangeNotifier
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => AuthService()), // Provide AuthService
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context); // Access AuthService
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          title: 'PlaceFeed',
          theme: ThemeProvider.lightTheme(),
          darkTheme: ThemeProvider.darkTheme(),
          themeMode: themeProvider.themeMode,
          routerConfig: buildRouter(authService), // Initialize GoRouter here
        );
      },
    );
  }
}
