import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; // Import geolocator
import 'dart:async'; // Import for Completer
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Placefeed',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  Future<void> _goToMyCurrentLocation() async {
    // Check and request location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, do nothing or show a message to the user
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // Get the current position
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // Animate the camera to the current position
    _controller?.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 14.4746,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        myLocationEnabled: true,
        myLocationButtonEnabled: false, // We'll use a custom button
        initialCameraPosition: _kGooglePlex,
        onMapCreated: (GoogleMapController controller) {
          _controller = controller;
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToMyCurrentLocation,
        materialTapTargetSize: MaterialTapTargetSize.padded,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.my_location, size: 36.0),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}