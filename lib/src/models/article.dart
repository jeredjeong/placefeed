import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // For LatLng

class Article {
  final String id;
  final String title;
  final String description;
  final String url;
  final String? imageUrl;
  final LatLng location; // Storing as LatLng for map integration
  final int importance; // 1-100
  final int minZoom; // Min zoom level to display
  final int maxZoom; // Max zoom level to display
  final DateTime publishedAt;
  final String source; // e.g., 'News API' or 'Manual'

  Article({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    this.imageUrl,
    required this.location,
    required this.importance,
    required this.minZoom,
    required this.maxZoom,
    required this.publishedAt,
    required this.source,
  });

  factory Article.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    GeoPoint geoPoint = data?['location'] ?? const GeoPoint(0, 0); // Default to (0,0) if null
    return Article(
      id: snapshot.id,
      title: data?['title'] ?? '',
      description: data?['description'] ?? '',
      url: data?['url'] ?? '',
      imageUrl: data?['imageUrl'],
      location: LatLng(geoPoint.latitude, geoPoint.longitude),
      importance: data?['importance'] ?? 50,
      minZoom: data?['minZoom'] ?? 3,
      maxZoom: data?['maxZoom'] ?? 15,
      publishedAt: (data?['publishedAt'] as Timestamp).toDate(),
      source: data?['source'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "title": title,
      "description": description,
      "url": url,
      "imageUrl": imageUrl,
      "location": GeoPoint(location.latitude, location.longitude),
      "importance": importance,
      "minZoom": minZoom,
      "maxZoom": maxZoom,
      "publishedAt": Timestamp.fromDate(publishedAt),
      "source": source,
    };
  }
}
