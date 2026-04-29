import 'geo_point.dart';
import 'model_serialization.dart';

class TennisCenter {
  final String id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final String phoneNumber;
  final String email;
  final String website;
  final String description;
  final List<String> amenities;
  final Map<String, Map<String, String>> operatingHours;
  final double latitude;
  final double longitude;
  final double rating;
  final int ratingCount;
  final List<String> imageUrls;
  final int courtCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  TennisCenter({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    required this.phoneNumber,
    required this.email,
    required this.website,
    required this.description,
    required this.amenities,
    required this.operatingHours,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.ratingCount,
    required this.imageUrls,
    required this.courtCount,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TennisCenter.fromMap(Map<String, dynamic> data, {String? id}) {
    final location = GeoPoint.fromMap(
      data['location'] ??
          {
            'latitude': data['latitude'],
            'longitude': data['longitude'],
          },
    );

    return TennisCenter(
      id: id ?? data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      address: data['address'] as String? ?? '',
      city: data['city'] as String? ?? '',
      state: data['state'] as String? ?? '',
      zipCode: data['zipCode'] as String? ?? '',
      country: data['country'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      email: data['email'] as String? ?? '',
      website: data['website'] as String? ?? '',
      description: data['description'] as String? ?? '',
      amenities: data['amenities'] != null
          ? List<String>.from(data['amenities'])
          : const <String>[],
      operatingHours: _parseOperatingHours(data['operatingHours']),
      latitude: location.latitude,
      longitude: location.longitude,
      rating: readDouble(data['rating']),
      ratingCount: data['ratingCount'] as int? ?? 0,
      imageUrls: data['imageUrls'] != null
          ? List<String>.from(data['imageUrls'])
          : const <String>[],
      courtCount: data['courtCount'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: parseDateTime(data['createdAt']),
      updatedAt: parseDateTime(
        data['updatedAt'],
        fallback: parseDateTime(data['createdAt']),
      ),
    );
  }

  static Map<String, Map<String, String>> _parseOperatingHours(dynamic hours) {
    if (hours is! Map) {
      return {};
    }

    final result = <String, Map<String, String>>{};
    (hours as Map<String, dynamic>).forEach((day, times) {
      final timeMap = Map<String, dynamic>.from(times as Map? ?? const {});
      result[day] = {
        'open': timeMap['open'] as String? ?? '',
        'close': timeMap['close'] as String? ?? '',
      };
    });

    return result;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'phoneNumber': phoneNumber,
      'email': email,
      'website': website,
      'description': description,
      'amenities': amenities,
      'operatingHours': operatingHours,
      'location': GeoPoint(latitude, longitude).toMap(),
      'rating': rating,
      'ratingCount': ratingCount,
      'imageUrls': imageUrls,
      'courtCount': courtCount,
      'isActive': isActive,
      'createdAt': serializeDateTime(createdAt),
      'updatedAt': serializeDateTime(updatedAt),
    };
  }

  TennisCenter copyWith({
    String? id,
    String? name,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    String? phoneNumber,
    String? email,
    String? website,
    String? description,
    List<String>? amenities,
    Map<String, Map<String, String>>? operatingHours,
    double? latitude,
    double? longitude,
    double? rating,
    int? ratingCount,
    List<String>? imageUrls,
    int? courtCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TennisCenter(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      website: website ?? this.website,
      description: description ?? this.description,
      amenities: amenities ?? this.amenities,
      operatingHours: operatingHours ?? this.operatingHours,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      imageUrls: imageUrls ?? this.imageUrls,
      courtCount: courtCount ?? this.courtCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get fullAddress => '$address, $city, $state $zipCode, $country';

  String getFormattedHoursForDay(String day) {
    final hours = operatingHours[day];
    if (hours == null || hours['open']?.isEmpty == true || hours['close']?.isEmpty == true) {
      return 'Closed';
    }
    return '${hours['open']} - ${hours['close']}';
  }

  bool isOpenOnDay(String day) {
    final hours = operatingHours[day];
    return hours != null &&
        hours['open']?.isNotEmpty == true &&
        hours['close']?.isNotEmpty == true;
  }
}
