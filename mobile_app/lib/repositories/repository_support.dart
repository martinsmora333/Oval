import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking_model.dart';
import '../models/court_model.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';

abstract class RepositorySupport {
  SupabaseClient get client => SupabaseService.client;

  DateTime parseDbDateTime(dynamic value) {
    if (value is DateTime) {
      return value.toLocal();
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value).toLocal();
    }
    return DateTime.now();
  }

  double readDouble(dynamic value, {required double fallback}) {
    if (value == null) {
      return fallback;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString()) ?? fallback;
  }

  double? readNullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  String normalizeSurface(String? value) {
    switch (value?.toLowerCase()) {
      case 'clay':
        return 'clay';
      case 'grass':
        return 'grass';
      case 'carpet':
        return 'carpet';
      case 'hard':
      default:
        return 'hard';
    }
  }

  SurfaceType surfaceTypeFromDb(String? value) {
    switch (value) {
      case 'clay':
        return SurfaceType.clay;
      case 'grass':
        return SurfaceType.grass;
      case 'carpet':
        return SurfaceType.carpet;
      case 'hard':
      default:
        return SurfaceType.hard;
    }
  }

  PlayerLevel playerLevelFromDb(String? value) {
    switch (value) {
      case 'beginner':
        return PlayerLevel.beginner;
      case 'advanced':
        return PlayerLevel.advanced;
      case 'pro':
        return PlayerLevel.pro;
      case 'intermediate':
      default:
        return PlayerLevel.intermediate;
    }
  }

  UserType userTypeFromDb(String? value) {
    switch (value) {
      case 'court_manager':
        return UserType.courtManager;
      case 'player':
      default:
        return UserType.player;
    }
  }

  bool looksLikeUuid(String value) {
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    return uuidPattern.hasMatch(value);
  }

  String publicStorageUrl(String bucket, String? storagePath) {
    if (storagePath == null || storagePath.trim().isEmpty) {
      return '';
    }
    return client.storage.from(bucket).getPublicUrl(storagePath);
  }

  Map<String, List<Map<String, dynamic>>> groupRowsByKey(
    List<Map<String, dynamic>> rows, {
    required String key,
  }) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final groupKey = row[key] as String;
      grouped.putIfAbsent(groupKey, () => <Map<String, dynamic>>[]).add(row);
    }
    return grouped;
  }

  Map<String, dynamic> singleRpcRow(dynamic result) {
    if (result is List) {
      if (result.isEmpty) {
        throw StateError('RPC returned no rows');
      }
      final row = result.first;
      if (row is Map<String, dynamic>) {
        return row;
      }
      if (row is Map) {
        return row.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    }

    if (result is Map<String, dynamic>) {
      return result;
    }
    if (result is Map) {
      return result.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    throw StateError('Unexpected RPC result: $result');
  }

  BookingStatus bookingStatusFromDb(String? value) =>
      BookingStatus.fromDb(value);
  PaymentStatus paymentStatusFromDb(String? value) =>
      PaymentStatus.fromDb(value);
}
