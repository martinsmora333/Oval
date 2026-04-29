import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'location_utils.dart';

/// Lightweight formatting model for location suggestion text.
class StructuredFormatting {
  StructuredFormatting({
    this.mainText,
    this.secondaryText,
  });

  final String? mainText;
  final String? secondaryText;
}

/// Lightweight prediction model used by [LocationSearchBar].
class Prediction {
  Prediction({
    this.description,
    this.placeId,
    this.structuredFormatting,
    this.types,
    this.latitude,
    this.longitude,
  });

  String? description;
  String? placeId;
  StructuredFormatting? structuredFormatting;
  List<String>? types;
  double? latitude;
  double? longitude;
}

class PlaceLocation {
  PlaceLocation({required this.lat, required this.lng});

  final double lat;
  final double lng;
}

class PlaceGeometry {
  PlaceGeometry({required this.location});

  final PlaceLocation location;
}

class PlaceDetails {
  PlaceDetails({
    this.geometry,
    this.formattedAddress,
  });

  final PlaceGeometry? geometry;
  final String? formattedAddress;
}

/// A utility class for handling location search functionality.
class LocationSearchUtils {
  /// Returns geocoding-backed location suggestions.
  static Future<List<Prediction>> searchPlaces({
    required String query,
    required String apiKey,
    String language = 'en',
    Map<String, String>? components,
    String? sessionToken,
    LatLng? location,
    int? radius,
    bool strictBounds = false,
    List<String>? types,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final results = await locationFromAddress(
        query,
        localeIdentifier: language,
      );

      return results.take(6).map((result) {
        final placeId = 'geocoding_${result.latitude}_${result.longitude}';
        return Prediction(
          description: query,
          placeId: placeId,
          structuredFormatting: StructuredFormatting(
            mainText: query,
            secondaryText:
                '${result.latitude.toStringAsFixed(6)}, ${result.longitude.toStringAsFixed(6)}',
          ),
          types: const ['geocode'],
          latitude: result.latitude,
          longitude: result.longitude,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Converts a [Prediction.placeId] or query string into coordinates/details.
  static Future<PlaceDetails?> getPlaceDetails({
    required String placeId,
    required String apiKey,
    List<String>? fields,
    String? sessionToken,
    String language = 'en',
  }) async {
    final fromId = _locationFromPlaceId(placeId);
    if (fromId != null) {
      final formatted = await getFormattedAddress(
        latitude: fromId.latitude,
        longitude: fromId.longitude,
        language: language,
      );
      return PlaceDetails(
        geometry: PlaceGeometry(
          location: PlaceLocation(lat: fromId.latitude, lng: fromId.longitude),
        ),
        formattedAddress: formatted,
      );
    }

    final fallback = await getLocationFromAddress(
      address: placeId,
      language: language,
    );
    if (fallback == null) {
      return null;
    }

    final formatted = await getFormattedAddress(
      latitude: fallback.latitude,
      longitude: fallback.longitude,
      language: language,
    );

    return PlaceDetails(
      geometry: PlaceGeometry(
        location:
            PlaceLocation(lat: fallback.latitude, lng: fallback.longitude),
      ),
      formattedAddress: formatted,
    );
  }

  /// Gets the location coordinates from an address.
  static Future<LatLng?> getLocationFromAddress({
    required String address,
    String language = 'en',
  }) async {
    return LocationUtils.getLocationFromAddress(
      address: address,
      language: language,
    );
  }

  /// Gets address details from location coordinates.
  static Future<Placemark?> getAddressFromLocation({
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

      if (placemarks.isNotEmpty) {
        return placemarks.first;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Gets a formatted address string from coordinates.
  static Future<String> getFormattedAddress({
    required double latitude,
    required double longitude,
    String language = 'en',
  }) async {
    return LocationUtils.getFormattedAddress(
      latitude: latitude,
      longitude: longitude,
      language: language,
    );
  }

  /// Gets the distance between two points in kilometers.
  static double getDistanceInKm({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return LocationUtils.calculateDistanceInKm(
      startLat,
      startLng,
      endLat,
      endLng,
    );
  }

  static LatLng? _locationFromPlaceId(String placeId) {
    if (!placeId.startsWith('geocoding_')) {
      return null;
    }

    final coords = placeId.substring('geocoding_'.length).split('_');
    if (coords.length != 2) {
      return null;
    }

    final lat = double.tryParse(coords[0]);
    final lng = double.tryParse(coords[1]);
    if (lat == null || lng == null) {
      return null;
    }

    return LatLng(lat, lng);
  }
}
