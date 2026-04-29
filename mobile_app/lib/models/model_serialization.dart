DateTime parseDateTime(dynamic value, {DateTime? fallback}) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? (fallback ?? DateTime.now());
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value is Map<String, dynamic>) {
    final seconds = value['_seconds'] ?? value['seconds'];
    if (seconds is num) {
      final nanoseconds = value['_nanoseconds'] ?? value['nanoseconds'];
      final milliseconds = seconds.toInt() * 1000 +
          ((nanoseconds is num ? nanoseconds.toInt() : 0) ~/ 1000000);
      return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true)
          .toLocal();
    }
  }
  return fallback ?? DateTime.now();
}

String? serializeDateTime(DateTime? value) => value?.toIso8601String();

double readDouble(dynamic value, {double fallback = 0}) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}
