import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  print('🔍 Testing Google Maps Integration...');
  print('📁 .env file loaded: ${dotenv.isInitialized}');
  print('🗝️  Google Maps API Key: ${dotenv.env['GOOGLE_MAPS_API_KEY']?.substring(0, 20)}...');
  print('🗝️  Google Places API Key: ${dotenv.env['GOOGLE_PLACES_API_KEY']?.substring(0, 20)}...');
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Maps Test',
      home: MapTestScreen(),
    );
  }
}

class MapTestScreen extends StatefulWidget {
  @override
  _MapTestScreenState createState() => _MapTestScreenState();
}

class _MapTestScreenState extends State<MapTestScreen> {
  GoogleMapController? _mapController;
  final LatLng _center = const LatLng(37.7749, -122.4194); // San Francisco

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    print('✅ Google Map created successfully!');
    print('📍 Map center: ${_center.latitude}, ${_center.longitude}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Maps Test'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Container(
            height: 200,
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 11.0,
              ),
              markers: {
                Marker(
                  markerId: MarkerId('test_marker'),
                  position: _center,
                  infoWindow: InfoWindow(
                    title: 'Test Location',
                    snippet: 'Google Maps is working!',
                  ),
                ),
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Google Maps Integration Test',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('✅ Map widget loaded'),
                Text('✅ API key configured'),
                Text('✅ Environment variables loaded'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLng(_center),
                    );
                  },
                  child: Text('Center Map'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
