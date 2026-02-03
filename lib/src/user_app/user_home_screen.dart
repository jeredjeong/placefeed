import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:myapp/src/services/auth_service.dart';
import 'package:myapp/src/models/article.dart';
import 'package:myapp/src/theme/theme_provider.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  double currentZoom = 5.0; // Default zoom level
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  // Initial camera position centered on a global view (e.g., world)
  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(0, 0), // Center of the world
    zoom: 1.0,
  );

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test Ad Unit ID (Android example)
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('${ad.runtimeType} loaded.');
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('${ad.runtimeType} failed to load: $error');
          ad.dispose();
        },
      ),
    );
    _bannerAd?.load();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PlaceFeed'),
        actions: [
          IconButton(
            icon: Icon(themeProvider.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: themeProvider.toggleTheme,
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (mounted) {
                context.go('/login');
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('articles').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allArticles = snapshot.data!.docs.map((doc) => Article.fromFirestore(doc, null)).toList();
                _updateMarkers(allArticles);

                return GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: _kInitialPosition,
                  onMapCreated: (GoogleMapController controller) {
                    mapController = controller;
                  },
                  onCameraMove: (CameraPosition position) {
                    currentZoom = position.zoom;
                  },
                  onCameraIdle: () {
                    _updateMarkers(allArticles);
                  },
                  markers: markers,
                );
              },
            ),
          ),
          if (_bannerAd != null && _isAdLoaded)
            SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }

  void _updateMarkers(List<Article> allArticles) async {
    if (mapController == null) return;

    final LatLngBounds visibleRegion = await mapController!.getVisibleRegion();
    final newMarkers = <Marker>{};

    for (var article in allArticles) {
      if (visibleRegion.contains(article.location) &&
          currentZoom >= article.minZoom &&
          currentZoom <= article.maxZoom) {
        newMarkers.add(
          Marker(
            markerId: MarkerId(article.id),
            position: article.location,
            infoWindow: InfoWindow(
              title: article.title,
              snippet: article.description.length > 100
                  ? '${article.description.substring(0, 100)}...'
                  : article.description,
              onTap: () => _showArticleDetails(article),
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        markers = newMarkers;
      });
    }
  }

  void _showArticleDetails(Article article) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                article.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                article.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              if (article.imageUrl != null)
                Image.network(
                  article.imageUrl!,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: () async {
                    final Uri uri = Uri.parse(article.url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not launch ${article.url}')),
                        );
                      }
                    }
                  },
                  child: const Text('Read More'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}