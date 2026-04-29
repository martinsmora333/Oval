import 'model_serialization.dart';

enum SurfaceType { clay, hard, grass, carpet }

class CourtModel {
  final String id;
  final String tennisCenter;
  final String name;
  final SurfaceType surface;
  final bool indoor;
  final double hourlyRate;
  final Map<String, dynamic>? availability;
  final List<String> images;
  final List<String> features;
  final double? rating;
  final bool? hasLighting;

  double get pricePerHour => hourlyRate;
  String get surfaceType => surface.name;
  bool? get isIndoor => indoor;

  CourtModel({
    required this.id,
    required this.tennisCenter,
    required this.name,
    required this.surface,
    required this.indoor,
    required this.hourlyRate,
    this.availability,
    required this.images,
    required this.features,
    this.rating,
    this.hasLighting,
  });

  factory CourtModel.fromMap(Map<String, dynamic> data) {
    return CourtModel(
      id: data['id'] as String? ?? '',
      tennisCenter: data['tennisCenter'] as String? ?? '',
      name: data['name'] as String? ?? '',
      surface: _getSurfaceTypeFromString(data['surface'] ?? 'hard'),
      indoor: data['indoor'] as bool? ?? data['isIndoor'] as bool? ?? false,
      hourlyRate: readDouble(
        data['hourlyRate'] ?? data['pricePerHour'],
      ),
      availability: data['availability'] != null
          ? Map<String, dynamic>.from(data['availability'] as Map)
          : null,
      images: data['images'] != null ? List<String>.from(data['images']) : [],
      features: data['features'] != null
          ? List<String>.from(data['features'])
          : [],
      rating: data['rating'] == null ? null : readDouble(data['rating']),
      hasLighting: data['hasLighting'] as bool? ??
          ((data['lighting'] as String?)?.toLowerCase() != 'none'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tennisCenter': tennisCenter,
      'name': name,
      'surface': surface.name,
      'indoor': indoor,
      'hourlyRate': hourlyRate,
      'availability': availability,
      'images': images,
      'features': features,
      'rating': rating,
      'hasLighting': hasLighting,
    };
  }

  CourtModel copyWith({
    String? id,
    String? tennisCenter,
    String? name,
    SurfaceType? surface,
    bool? indoor,
    double? hourlyRate,
    Map<String, dynamic>? availability,
    List<String>? images,
    List<String>? features,
    double? rating,
    bool? hasLighting,
  }) {
    return CourtModel(
      id: id ?? this.id,
      tennisCenter: tennisCenter ?? this.tennisCenter,
      name: name ?? this.name,
      surface: surface ?? this.surface,
      indoor: indoor ?? this.indoor,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      availability: availability ?? this.availability,
      images: images ?? this.images,
      features: features ?? this.features,
      rating: rating ?? this.rating,
      hasLighting: hasLighting ?? this.hasLighting,
    );
  }

  static SurfaceType _getSurfaceTypeFromString(dynamic surface) {
    switch (surface.toString().toLowerCase()) {
      case 'clay':
        return SurfaceType.clay;
      case 'hard':
        return SurfaceType.hard;
      case 'grass':
        return SurfaceType.grass;
      case 'carpet':
        return SurfaceType.carpet;
      default:
        return SurfaceType.hard;
    }
  }

  String get surfaceTypeString {
    switch (surface) {
      case SurfaceType.clay:
        return 'Clay';
      case SurfaceType.hard:
        return 'Hard';
      case SurfaceType.grass:
        return 'Grass';
      case SurfaceType.carpet:
        return 'Carpet';
    }
  }

  String get environmentString => indoor ? 'Indoor' : 'Outdoor';
  String get featuresString => features.join(', ');
  String get formattedRate => '\$${hourlyRate.toStringAsFixed(2)}/hour';
}

class AvailabilitySlot {
  final String id;
  final String date;
  final String startTime;
  final String endTime;
  final String status;
  final double price;
  final bool specialEvent;
  final int maxPlayers;
  final String? bookingId;

  AvailabilitySlot({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.price,
    this.specialEvent = false,
    this.maxPlayers = 2,
    this.bookingId,
  });

  factory AvailabilitySlot.fromMap(Map<String, dynamic> data, {String? id}) {
    return AvailabilitySlot(
      id: id ?? data['id'] as String? ?? '',
      date: data['date'] as String? ?? '',
      startTime: data['startTime'] as String? ?? '',
      endTime: data['endTime'] as String? ?? '',
      status: data['status'] as String? ?? 'available',
      price: readDouble(data['price']),
      specialEvent: data['specialEvent'] as bool? ?? false,
      maxPlayers: data['maxPlayers'] as int? ?? 2,
      bookingId: data['bookingId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
      'price': price,
      'specialEvent': specialEvent,
      'maxPlayers': maxPlayers,
      'bookingId': bookingId,
    };
  }

  String get timeSlot => '$startTime - $endTime';
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
  bool get isAvailable => status == 'available';

  String get statusColor {
    switch (status) {
      case 'available':
        return 'green';
      case 'booked':
        return 'darkGreen';
      case 'pending':
        return 'amber';
      case 'maintenance':
        return 'grey';
      default:
        return 'grey';
    }
  }
}
