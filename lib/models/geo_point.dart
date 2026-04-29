class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint(this.latitude, this.longitude);

  factory GeoPoint.fromMap(dynamic value) {
    if (value is GeoPoint) {
      return value;
    }

    if (value is Map<String, dynamic>) {
      return GeoPoint(
        _readCoordinate(value['latitude'] ?? value['lat']),
        _readCoordinate(value['longitude'] ?? value['lng'] ?? value['lon']),
      );
    }

    return const GeoPoint(0, 0);
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static double _readCoordinate(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}
