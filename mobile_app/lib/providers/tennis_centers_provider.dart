import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;
import '../models/tennis_center_model.dart';
import '../models/court_model.dart';
import '../models/tennis_center.dart';
import '../services/data_service.dart';

class TennisCentersProvider with ChangeNotifier {
  final DataService _dataService = DataService();

  List<TennisCenterModel> _tennisCenters = [];
  List<TennisCenter> _tennisCentersForMap = [];
  TennisCenterModel? _selectedTennisCenter;
  List<CourtModel> _courts = [];
  bool _isLoading = false;
  bool _isLoadingCourts = false;
  bool _isLoadingMap = false;
  String? _error;

  // Map related properties
  Set<Marker> _markers = {};
  LatLng? _currentUserLocation;

  // Getters
  List<TennisCenterModel> get tennisCenters => _tennisCenters;
  List<TennisCenter> get tennisCentersForMap => _tennisCentersForMap;
  TennisCenterModel? get selectedTennisCenter => _selectedTennisCenter;
  List<CourtModel> get courts => _courts;
  bool get isLoading => _isLoading;
  bool get isLoadingCourts => _isLoadingCourts;
  bool get isLoadingMap => _isLoadingMap;
  String? get error => _error;
  Set<Marker> get markers => _markers;
  LatLng? get currentUserLocation => _currentUserLocation;

  // Get tennis centers by IDs (for tennis center managers)
  Future<List<Map<String, dynamic>>> getTennisCentersByIds(
      List<String> centerIds) async {
    try {
      final List<Map<String, dynamic>> centers = [];

      for (final id in centerIds) {
        final centerData = await _dataService.getTennisCenterById(id);
        if (centerData != null) {
          // Get courts count for this center
          final courts = await _dataService.getCourtsForTennisCenter(id);
          centerData['courtsCount'] = courts.length;
          centers.add(centerData);
        }
      }

      return centers;
    } catch (e) {
      debugPrint('Error getting tennis centers by IDs: $e');
      _error = 'Failed to load tennis centers';
      return [];
    }
  }

  // Get courts for a tennis center
  Future<List<Map<String, dynamic>>> getCourtsForTennisCenter(
      String tennisCenterId) async {
    try {
      _isLoadingCourts = true;
      notifyListeners();

      final courts =
          await _dataService.getCourtsForTennisCenter(tennisCenterId);

      _isLoadingCourts = false;
      notifyListeners();

      return courts;
    } catch (e) {
      debugPrint('Error getting courts for tennis center: $e');
      _error = 'Failed to load courts';
      _isLoadingCourts = false;
      notifyListeners();
      return [];
    }
  }

  // Load all tennis centers
  Future<void> loadTennisCenters() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('TennisCentersProvider: Starting to load tennis centers');
      _tennisCenters = await _dataService.getTennisCenters();
      debugPrint(
          'TennisCentersProvider: Loaded ${_tennisCenters.length} tennis centers');

      // If we got an empty list, try to understand why
      if (_tennisCenters.isEmpty) {
        debugPrint(
            'TennisCentersProvider: No tennis centers found. Check tennis center data sync.');
      }

      // Also load tennis centers for map
      await loadTennisCentersForMap();
    } catch (e, stackTrace) {
      _error = 'Failed to load tennis centers';
      debugPrint('Error loading tennis centers: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load tennis centers for map
  Future<List<TennisCenter>> loadTennisCentersForMap() async {
    _isLoadingMap = true;
    notifyListeners();

    try {
      _tennisCentersForMap = await _dataService.getTennisCentersForMap();

      // Create markers for each tennis center
      _createMarkers();

      _isLoadingMap = false;
      notifyListeners();
      return _tennisCentersForMap;
    } catch (e) {
      _error = 'Failed to load tennis centers for map';
      debugPrint('Error loading tennis centers for map: $e');
      _isLoadingMap = false;
      notifyListeners();
      return [];
    }
  }

  // Create markers for tennis centers
  void _createMarkers() {
    _markers = {};

    for (final center in _tennisCentersForMap) {
      final marker = Marker(
        markerId: MarkerId(center.id),
        position: LatLng(center.latitude, center.longitude),
        infoWindow: InfoWindow(
          title: center.name,
          snippet: center.address,
        ),
      );

      _markers.add(marker);
    }

    notifyListeners();
  }

  // Set current user location
  void setCurrentUserLocation(LatLng location) {
    _currentUserLocation = location;
    notifyListeners();
  }

  // Find nearby tennis centers
  List<TennisCenter> findNearbyCenters(double radiusInKm) {
    if (_currentUserLocation == null) return [];

    const double earthRadius = 6371; // Earth's radius in kilometers
    final List<TennisCenter> nearbyCenters = [];

    for (final center in _tennisCentersForMap) {
      // Calculate distance using Haversine formula
      final double lat1 = _currentUserLocation!.latitude * (3.14159 / 180);
      final double lon1 = _currentUserLocation!.longitude * (3.14159 / 180);
      final double lat2 = center.latitude * (3.14159 / 180);
      final double lon2 = center.longitude * (3.14159 / 180);

      final double dLat = lat2 - lat1;
      final double dLon = lon2 - lon1;

      final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
          math.cos(lat1) *
              math.cos(lat2) *
              math.sin(dLon / 2) *
              math.sin(dLon / 2);
      final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
      final double distance = earthRadius * c;

      if (distance <= radiusInKm) {
        nearbyCenters.add(center);
      }
    }

    // Sort by distance
    nearbyCenters.sort((a, b) {
      final double distA = _calculateDistance(a.latitude, a.longitude);
      final double distB = _calculateDistance(b.latitude, b.longitude);
      return distA.compareTo(distB);
    });

    return nearbyCenters;
  }

  // Calculate distance between two points
  double _calculateDistance(double lat2, double lon2) {
    if (_currentUserLocation == null) return double.infinity;

    const double earthRadius = 6371; // Earth's radius in kilometers
    final double lat1 = _currentUserLocation!.latitude * (3.14159 / 180);
    final double lon1 = _currentUserLocation!.longitude * (3.14159 / 180);
    lat2 = lat2 * (3.14159 / 180);
    lon2 = lon2 * (3.14159 / 180);

    final double dLat = lat2 - lat1;
    final double dLon = lon2 - lon1;

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  // Get tennis center by ID for map
  TennisCenter? getTennisCenterById(String id) {
    try {
      return _tennisCentersForMap.firstWhere((center) => center.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get all tennis centers for map
  Future<List<TennisCenter>> getTennisCentersForMap() async {
    if (_tennisCentersForMap.isNotEmpty) {
      return _tennisCentersForMap;
    }

    return await loadTennisCentersForMap();
  }

  // Load tennis center details
  Future<void> loadTennisCenterDetails(String tennisCenterId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedTennisCenter =
          await _dataService.getTennisCenter(tennisCenterId);
    } catch (e) {
      _error = 'Failed to load tennis center details';
      debugPrint('Error loading tennis center details: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load courts for a tennis center
  Future<void> loadCourts(String tennisCenterId) async {
    _isLoadingCourts = true;
    _error = null;
    notifyListeners();

    try {
      _courts = await _dataService.getCourts(tennisCenterId);
    } catch (e) {
      _error = 'Failed to load courts';
      debugPrint('Error loading courts: $e');
    } finally {
      _isLoadingCourts = false;
      notifyListeners();
    }
  }

  // Search tennis centers by name
  Future<List<TennisCenterModel>> searchTennisCenters(String query) async {
    if (query.isEmpty) return _tennisCenters;

    final lowerQuery = query.toLowerCase();
    return _tennisCenters
        .where((center) =>
            center.name.toLowerCase().contains(lowerQuery) ||
            center.address.formattedAddress.toLowerCase().contains(lowerQuery))
        .toList();
  }

  // Filter tennis centers by features
  List<TennisCenterModel> filterTennisCenters({
    List<String>? amenities,
    bool? hasIndoorCourts,
    double? minRating,
    double? maxPrice,
  }) {
    return _tennisCenters.where((center) {
      // Filter by amenities
      if (amenities != null && amenities.isNotEmpty) {
        final hasAllAmenities =
            amenities.every((amenity) => center.amenities.contains(amenity));
        if (!hasAllAmenities) return false;
      }

      // Filter by rating
      if (minRating != null &&
          (center.rating == null || center.rating! < minRating)) {
        return false;
      }

      // Additional filters can be implemented based on requirements

      return true;
    }).toList();
  }

  // Get court by ID
  CourtModel? getCourtById(String courtId) {
    try {
      return _courts.firstWhere((court) => court.id == courtId);
    } catch (e) {
      return null;
    }
  }

  // Create or update a tennis center
  Future<String?> createOrUpdateTennisCenter(
      TennisCenterModel tennisCenter) async {
    try {
      _isLoading = true;
      notifyListeners();

      final ownerUserId = tennisCenter.managerIds.isNotEmpty
          ? tennisCenter.managerIds.first
          : tennisCenter.id;
      final savedCenterId = await _dataService.createOrUpdateTennisCenter(
        tennisCenter,
        ownerUserId: ownerUserId,
      );

      final savedCenter =
          await _dataService.getTennisCenter(savedCenterId);
      if (savedCenter == null) {
        throw Exception('Failed to reload saved tennis center');
      }

      // Update local state
      final index = _tennisCenters.indexWhere((tc) => tc.id == savedCenterId);
      if (index != -1) {
        _tennisCenters[index] = savedCenter;
      } else {
        _tennisCenters.add(savedCenter);
      }

      return savedCenterId;
    } catch (e) {
      debugPrint('Error saving tennis center: $e');
      _error = 'Failed to save tennis center';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a court to a tennis center
  Future<bool> addCourtToTennisCenter(
      String tennisCenterId, CourtModel court) async {
    try {
      _isLoading = true;
      notifyListeners();

      final savedCourtId = await _dataService.addCourt(
        tennisCenterId,
        court.toMap(),
      );
      final savedCourt =
          await _dataService.getCourt(tennisCenterId, savedCourtId);

      // Update local state if this is the selected tennis center
      if (_selectedTennisCenter?.id == tennisCenterId && savedCourt != null) {
        _courts.add(savedCourt);
      }

      return true;
    } catch (e) {
      debugPrint('Error adding court: $e');
      _error = 'Failed to add court';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
