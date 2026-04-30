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
    final result = await client.rpc(
      'create_booking_workflow',
      params: <String, dynamic>{
        'target_center_id': booking.tennisCenter,
        'target_court_id': booking.courtId,
        'target_starts_at': booking.startsAt.toIso8601String(),
        'target_ends_at': booking.endsAt.toIso8601String(),
        'booking_total_amount': booking.totalAmount,
        'booking_amount_per_player': booking.amountPerPlayer,
        'booking_currency': 'AUD',
        'initial_invitee_ids': booking.inviteeId == null
            ? <String>[]
            : <String>[booking.inviteeId!],
      },
    );

    final row = singleRpcRow(result);
    return row['booking_id'] as String;
  }

  Future<void> updateBooking(BookingModel booking) async {
    throw UnsupportedError(
      'Direct booking edits are not supported. Use workflow functions or dedicated payment updates.',
    );
  }

  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status, {
    DateTime? confirmedAt,
  }) async {
    if (status == BookingStatus.cancelled) {
      await cancelBooking(bookingId);
      return;
    }

    throw UnsupportedError(
      'Booking status changes must go through the booking workflow.',
    );
  }

  Future<void> cancelBooking(
    String bookingId, {
    String? cancelReason,
  }) async {
    await client.rpc(
      'cancel_booking_workflow',
      params: <String, dynamic>{
        'target_booking_id': bookingId,
        'requested_cancel_reason': cancelReason,
      },
    );
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
                .select('id,name,street,city,state,postal_code,country')
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
    final centerAddresses = <String, String>{
      for (final row in centerRows)
        row['id'] as String: _formatCenterAddress(row),
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
        tennisCenterAddress: centerAddresses[centerId],
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

  String _formatCenterAddress(Map<String, dynamic> row) {
    final parts = <String>[
      row['street'] as String? ?? '',
      row['city'] as String? ?? '',
      row['state'] as String? ?? '',
      row['postal_code'] as String? ?? '',
      row['country'] as String? ?? '',
    ].where((part) => part.trim().isNotEmpty).toList(growable: false);

    return parts.join(', ');
  }
}
