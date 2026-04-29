enum AvailabilityStatus {
  available,
  booked,
  pending,
  maintenance
}

class AvailabilityModel {
  final String id;
  final String date;
  final String startTime;
  final String endTime;
  final AvailabilityStatus status;
  final double price;
  final bool specialEvent;
  final int maxPlayers;
  final String? bookingId;

  AvailabilityModel({
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

  factory AvailabilityModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return AvailabilityModel(
      id: id ?? data['id'] as String? ?? '',
      date: data['date'] as String? ?? '',
      startTime: data['startTime'] as String? ?? '',
      endTime: data['endTime'] as String? ?? '',
      status: _getStatusFromString(data['status'] ?? 'available'),
      price: (data['price'] as num? ?? 0).toDouble(),
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
      'status': status.name,
      'price': price,
      'specialEvent': specialEvent,
      'maxPlayers': maxPlayers,
      'bookingId': bookingId,
    };
  }

  AvailabilityModel copyWith({
    String? id,
    String? date,
    String? startTime,
    String? endTime,
    AvailabilityStatus? status,
    double? price,
    bool? specialEvent,
    int? maxPlayers,
    String? bookingId,
  }) {
    return AvailabilityModel(
      id: id ?? this.id,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      price: price ?? this.price,
      specialEvent: specialEvent ?? this.specialEvent,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      bookingId: bookingId ?? this.bookingId,
    );
  }

  static AvailabilityStatus _getStatusFromString(dynamic status) {
    switch (status.toString().toLowerCase()) {
      case 'booked':
        return AvailabilityStatus.booked;
      case 'pending':
        return AvailabilityStatus.pending;
      case 'maintenance':
        return AvailabilityStatus.maintenance;
      case 'available':
      default:
        return AvailabilityStatus.available;
    }
  }
}
