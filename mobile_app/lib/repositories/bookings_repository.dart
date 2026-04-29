import 'package:intl/intl.dart';

import '../models/booking_model.dart';
import '../models/user_model.dart';
import 'profiles_repository.dart';
import 'repository_support.dart';

class BookingsRepository extends RepositorySupport {
  BookingsRepository._internal();

  static final BookingsRepository _instance = BookingsRepository._internal();

  factory BookingsRepository() => _instance;

  final ProfilesRepository _profilesRepository = ProfilesRepository();

  Future<String> createBooking(BookingModel booking) async {
    final payload = <String, dynamic>{
      'center_id': booking.tennisCenter,
      'court_id': booking.courtId,
      'created_by': booking.creatorId,
      'opponent_user_id': booking.inviteeId,
      'status': booking.status.dbValue,
      'payment_status': booking.paymentStatus.dbValue,
      'total_amount': booking.totalAmount,
      'amount_per_player': booking.amountPerPlayer,
      'starts_at': booking.startsAt.toIso8601String(),
      'ends_at': booking.endsAt.toIso8601String(),
      'confirmed_at': booking.confirmedAt?.toIso8601String(),
    };

    final created =
        await client.from('bookings').insert(payload).select().single();
    return created['id'] as String;
  }

  Future<void> updateBooking(BookingModel booking) async {
    await client.from('bookings').update(
      <String, dynamic>{
        'court_id': booking.courtId,
        'center_id': booking.tennisCenter,
        'created_by': booking.creatorId,
        'opponent_user_id': booking.inviteeId,
        'status': booking.status.dbValue,
        'payment_status': booking.paymentStatus.dbValue,
        'total_amount': booking.totalAmount,
        'amount_per_player': booking.amountPerPlayer,
        'starts_at': booking.startsAt.toIso8601String(),
        'ends_at': booking.endsAt.toIso8601String(),
        'confirmed_at': booking.confirmedAt?.toIso8601String(),
      },
    ).eq('id', booking.id);
  }

  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status, {
    DateTime? confirmedAt,
  }) async {
    final updates = <String, dynamic>{
      'status': status.dbValue,
    };

    if (status == BookingStatus.confirmed) {
      updates['confirmed_at'] =
          (confirmedAt ?? DateTime.now()).toIso8601String();
    }
    if (status == BookingStatus.cancelled) {
      updates['cancelled_at'] = DateTime.now().toIso8601String();
    }

    await client.from('bookings').update(updates).eq('id', bookingId);
  }

  Future<BookingModel?> getBooking(String bookingId) async {
    final row = await client
        .from('bookings')
        .select()
        .eq('id', bookingId)
        .maybeSingle();
    if (row == null) {
      return null;
    }

    final bookings = await _mapBookingRows(<Map<String, dynamic>>[
      Map<String, dynamic>.from(row),
    ]);
    return bookings.first;
  }

  Future<List<BookingModel>> getTennisCenterBookings(
    String tennisCenterId, {
    String? date,
  }) async {
    var query =
        client.from('bookings').select().eq('center_id', tennisCenterId);

    if (date != null && date.isNotEmpty) {
      final day = DateFormat('yyyy-MM-dd').parse(date);
      final nextDay = day.add(const Duration(days: 1));
      query = query
          .gte('starts_at', day.toIso8601String())
          .lt('starts_at', nextDay.toIso8601String());
    }

    final rows = await query.order('starts_at');
    return _mapBookingRows(
      (rows as List)
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false),
    );
  }

  Future<List<BookingModel>> getUserBookings(
    String userId, {
    bool forceRefresh = false,
  }) async {
    final rows = await client
        .from('bookings')
        .select()
        .or('created_by.eq.$userId,opponent_user_id.eq.$userId')
        .order('starts_at');

    return _mapBookingRows(
      (rows as List)
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false),
    );
  }

  Future<List<BookingModel>> _mapBookingRows(
      List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) {
      return const <BookingModel>[];
    }

    final centerIds = rows
        .map((row) => row['center_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList(growable: false);
    final courtIds = rows
        .map((row) => row['court_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList(growable: false);
    final userIds = rows
        .expand<String>(
          (row) => <String?>[
            row['created_by'] as String?,
            row['opponent_user_id'] as String?,
          ].whereType<String>(),
        )
        .toSet()
        .toList(growable: false);

    final centerRows = centerIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : ((await client
                .from('tennis_centers')
                .select('id,name')
                .inFilter('id', centerIds)) as List)
            .map((row) => Map<String, dynamic>.from(row))
            .toList(growable: false);
    final courtRows = courtIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : ((await client
                .from('courts')
                .select('id,name')
                .inFilter('id', courtIds)) as List)
            .map((row) => Map<String, dynamic>.from(row))
            .toList(growable: false);
    final users = await _profilesRepository.getUsersByIds(userIds);

    final centerNames = <String, String>{
      for (final row in centerRows)
        row['id'] as String: row['name'] as String? ?? '',
    };
    final courtNames = <String, String>{
      for (final row in courtRows)
        row['id'] as String: row['name'] as String? ?? '',
    };
    final userNames = <String, String>{
      for (final UserModel user in users) user.id: user.displayName,
    };

    return rows.map((row) {
      final startsAt = parseDbDateTime(row['starts_at']);
      final endsAt = parseDbDateTime(row['ends_at']);
      final centerId = row['center_id'] as String? ?? '';
      final courtId = row['court_id'] as String? ?? '';
      final creatorId = row['created_by'] as String? ?? '';
      final inviteeId = row['opponent_user_id'] as String?;

      return BookingModel(
        id: row['id'] as String,
        courtId: courtId,
        courtName: courtNames[courtId],
        tennisCenter: centerId,
        tennisCenterName: centerNames[centerId],
        startsAt: startsAt,
        endsAt: endsAt,
        creatorId: creatorId,
        creatorName: userNames[creatorId],
        inviteeId: inviteeId,
        inviteeName: inviteeId == null ? null : userNames[inviteeId],
        status: BookingStatus.fromDb(row['status'] as String?),
        paymentStatus: PaymentStatus.fromDb(row['payment_status'] as String?),
        creatorPaymentId: null,
        inviteePaymentId: null,
        totalAmount: readDouble(row['total_amount'], fallback: 0),
        amountPerPlayer: readDouble(row['amount_per_player'], fallback: 0),
        price: readNullableDouble(row['amount_per_player']),
        createdAt: parseDbDateTime(row['created_at']),
        confirmedAt: row['confirmed_at'] == null
            ? null
            : parseDbDateTime(row['confirmed_at']),
      );
    }).toList(growable: false);
  }
}
