import 'dart:async';
import 'dart:math' show cos, sqrt, asin, pi, sin;

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A utility class for handling location-related operations.
class LocationUtils {
  /// The accuracy of the user's location when in meters.
  static const double _locationAccuracy = 10.0;

  /// The distance (in meters) that the user must move before an update event is generated.
  static const int _distanceFilter = 10;

  /// Checks if location services are enabled.
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Requests permission to access the device's location.
  ///
  /// Returns [LocationPermission] indicating the status of the permission request.
  static Future<LocationPermission> requestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, we don't request permissions.
      return LocationPermission.denied;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationPermission.denied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationPermission.deniedForever;
    }

    return permission;
  }

  /// Gets the current position of the device.
  ///
  /// Returns a [Position] object containing the current location.
  /// Throws a [Exception] if the location could not be determined.
  static Future<Position> getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      throw Exception('Location permission not granted');
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      // Fallback to last known position if getting current position fails
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        return lastPosition;
      }
      rethrow;
    }
  }

  /// Gets the last known position of the device.
  ///
  /// Returns a [Position] object containing the last known location.
  /// Returns `null` if no last known position is available.
  static Future<Position?> getLastKnownPosition() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return null;

    return await Geolocator.getLastKnownPosition();
  }

  /// Listens to the device's position and returns a stream of [Position] updates.
  ///
  /// The [onError] callback is called when an error occurs.
  static Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int? distanceFilter,
    bool forceAndroidLocationManager = false,
    int timeLimit = 30,
  }) {
    final locationSettings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter ?? _distanceFilter,
      timeLimit: Duration(seconds: timeLimit),
    );

    return Geolocator.getPositionStream(
      locationSettings: locationSettings,
    );
  }

  /// Calculates the distance between two points in kilometers.
  ///
  /// [startLatitude] and [startLongitude] represent the starting point.
  /// [endLatitude] and [endLongitude] represent the ending point.
  ///
  /// Returns the distance in kilometers.
  static double calculateDistanceInKm(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    const int earthRadius = 6371; // Earth's radius in kilometers

    // Convert latitude and longitude from degrees to radians
    double lat1 = startLatitude * pi / 180;
    double lon1 = startLongitude * pi / 180;
    double lat2 = endLatitude * pi / 180;
    double lon2 = endLongitude * pi / 180;

    // Haversine formula
    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  /// Formats a distance in meters to a human-readable string.
  ///
  /// If the distance is less than 1 km, returns the distance in meters.
  /// Otherwise, returns the distance in kilometers with one decimal place.
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Converts a [Position] to a [LatLng] object.
  static LatLng positionToLatLng(Position position) {
    return LatLng(position.latitude, position.longitude);
  }

  /// Converts an address string into coordinates.
  static Future<LatLng?> getLocationFromAddress({
    required String address,
    String language = 'en',
  }) async {
    try {
      final locations = await locationFromAddress(
        address,
        localeIdentifier: language,
      );
      if (locations.isEmpty) {
        return null;
      }
      return LatLng(locations.first.latitude, locations.first.longitude);
    } catch (_) {
      return null;
    }
  }

  /// Returns a formatted address string for coordinates.
  static Future<String> getFormattedAddress({
    required double latitude,
    required double longitude,
    String language = 'en',
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
        localeIdentifier: language,
      );
      if (placemarks.isEmpty) {
        return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
      }

      final place = placemarks.first;
      final parts = <String>[
        if ((place.street ?? '').isNotEmpty) place.street!,
        if ((place.subLocality ?? '').isNotEmpty) place.subLocality!,
        if ((place.locality ?? '').isNotEmpty) place.locality!,
        if ((place.administrativeArea ?? '').isNotEmpty)
          place.administrativeArea!,
        if ((place.postalCode ?? '').isNotEmpty) place.postalCode!,
        if ((place.country ?? '').isNotEmpty) place.country!,
      ];

      if (parts.isEmpty) {
        return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
      }
      return parts.join(', ');
    } catch (_) {
      return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
    }
  }

  /// Converts a [LatLng] to a [Position] object.
  static Position latLngToPosition(LatLng latLng, {double? altitude}) {
    return Position(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
      timestamp: DateTime.now(),
      accuracy: _locationAccuracy,
      altitude: altitude ?? 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }

  /// Handles the location permission request.
  ///
  /// Returns `true` if the permission is granted, `false` otherwise.
  static Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }
}
