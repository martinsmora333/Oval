import 'geo_point.dart';
import 'model_serialization.dart';

class TennisCenterModel {
  final String id;
  final String name;
  final Address address;
  final GeoPoint location;
  final String phoneNumber;
  final String email;
  final String? website;
  final String description;
  final List<String> amenities;
  final Map<String, OperatingHours> operatingHours;
  final List<String> images;
  final String? stripeAccountId;
  final DateTime createdAt;
  final double? rating;
  final List<String> managerIds;

  String? get phone => phoneNumber;
  String get openingHours => _formatOpeningHours();
  String? get imageUrl => images.isNotEmpty ? images.first : null;
  int get reviewCount => 0;
  int get courtCount => 2;
  double get pricePerHour => 25.0;

  String _formatOpeningHours() {
    if (operatingHours.isEmpty) return 'Hours not available';
    final today = DateTime.now().weekday;
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final todayName = dayNames[today - 1].toLowerCase();

    final hours = operatingHours[todayName];
    if (hours == null) return 'Hours not available';
    return '${hours.openTime} - ${hours.closeTime}';
  }

  TennisCenterModel({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.phoneNumber,
    required this.email,
    this.website,
    required this.description,
    required this.amenities,
    required this.operatingHours,
    required this.images,
    this.stripeAccountId,
    required this.createdAt,
    this.rating,
    this.managerIds = const [],
  });

  factory TennisCenterModel.fromMap(Map<String, dynamic> data, {String? id}) {
    final rawHours = data['operatingHours'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final hours = <String, OperatingHours>{};
    rawHours.forEach((key, value) {
      hours[key] = OperatingHours.fromMap(Map<String, dynamic>.from(value as Map));
    });

    final rawAddress = data['address'];
    final location = data['location'] != null
        ? GeoPoint.fromMap(data['location'])
        : GeoPoint(
            readDouble(data['latitude']),
            readDouble(data['longitude']),
          );

    return TennisCenterModel(
      id: id ?? data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      address: rawAddress is String
          ? Address(
              street: rawAddress,
              city: data['city'] as String? ?? 'City',
              state: data['state'] as String? ?? 'State',
              zipCode: data['zipCode'] as String? ??
                  data['postalCode'] as String? ??
                  '00000',
              country: data['country'] as String? ?? 'Country',
            )
          : Address.fromMap(Map<String, dynamic>.from(rawAddress as Map? ?? const {})),
      location: location,
      phoneNumber: data['phoneNumber'] as String? ?? '',
      email: data['email'] as String? ?? '',
      website: data['website'] as String?,
      description: data['description'] as String? ?? '',
      amenities: data['amenities'] != null
          ? List<String>.from(data['amenities'])
          : const <String>[],
      operatingHours: hours,
      images: data['images'] != null ? List<String>.from(data['images']) : const <String>[],
      stripeAccountId: data['stripeAccountId'] as String?,
      createdAt: parseDateTime(data['createdAt']),
      rating: data['rating'] == null ? null : readDouble(data['rating']),
      managerIds: data['managerIds'] != null
          ? List<String>.from(data['managerIds'])
          : const <String>[],
    );
  }

  Map<String, dynamic> toMap() {
    final hoursMap = <String, dynamic>{};
    operatingHours.forEach((key, value) {
      hoursMap[key] = value.toMap();
    });

    return {
      'id': id,
      'name': name,
      'address': address.toMap(),
      'location': location.toMap(),
      'phoneNumber': phoneNumber,
      'email': email,
      'website': website,
      'description': description,
      'amenities': amenities,
      'operatingHours': hoursMap,
      'images': images,
      'stripeAccountId': stripeAccountId,
      'createdAt': serializeDateTime(createdAt),
      'rating': rating,
      'managerIds': managerIds,
    };
  }
}

class Address {
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;

  Address({
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
  });

  @override
  String toString() {
    return '$street, $city, $state $zipCode';
  }

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      street: map['street'] as String? ?? '',
      city: map['city'] as String? ?? '',
      state: map['state'] as String? ?? '',
      zipCode: map['zipCode'] as String? ?? map['postalCode'] as String? ?? '',
      country: map['country'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'postalCode': zipCode,
      'country': country,
    };
  }

  String get formattedAddress => '$street, $city, $state $zipCode, $country';
}

class OperatingHours {
  final String open;
  final String close;
  final bool isClosed;

  String get openTime => open;
  String get closeTime => close;

  OperatingHours({
    required this.open,
    required this.close,
    this.isClosed = false,
  });

  factory OperatingHours.fromMap(Map<String, dynamic> map) {
    return OperatingHours(
      open: map['open'] as String? ?? map['openTime'] as String? ?? '09:00',
      close: map['close'] as String? ?? map['closeTime'] as String? ?? '21:00',
      isClosed: map['isClosed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'open': open,
      'close': close,
      'isClosed': isClosed,
    };
  }

  String get formattedHours => isClosed ? 'Closed' : '$open - $close';
}
