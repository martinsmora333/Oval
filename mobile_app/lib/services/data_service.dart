import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/availability_model.dart';
import '../models/booking_model.dart';
import '../models/court_model.dart';
import '../models/geo_point.dart';
import '../models/invitation_model.dart';
import '../models/tennis_center.dart';
import '../models/tennis_center_model.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';

class DataService {
  DataService._internal();

  static final DataService _instance = DataService._internal();

  factory DataService() => _instance;

  SupabaseClient get _client => SupabaseService.client;

  static const List<String> _dayNames = <String>[
    'sunday',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
  ];

  Future<List<UserModel>> getUsers() async {
    final profileRows = await _client.from('profiles').select('id');
    final ids = (profileRows as List)
        .map((row) => row['id'] as String)
        .toList(growable: false);
    return _getUsersByIds(ids);
  }

  Future<List<UserModel>> getUsersByEmail(String email) async {
    final rows = await _client
        .from('profiles')
        .select('id')
        .eq('email', email);
    final ids = (rows as List)
        .map((row) => row['id'] as String)
        .toList(growable: false);
    return _getUsersByIds(ids);
  }

  Future<List<UserModel>> searchUsers(String searchTerm) async {
    final trimmed = searchTerm.trim();
    if (trimmed.isEmpty) {
      return const <UserModel>[];
    }

    final rpcRows = await _client.rpc(
      'search_player_directory',
      params: {
        'search_term': trimmed,
        'limit_count': 20,
      },
    );

    final ids = (rpcRows as List)
        .map((row) => row['user_id'] as String)
        .toList(growable: false);
    return _getUsersByIds(ids);
  }

  Future<void> createUser(UserModel user) async {
    await _upsertUser(user);
  }

  Future<void> updateUser(UserModel user) async {
    await _upsertUser(user);
  }

  Future<UserModel?> getUser(String userId) async {
    final users = await _getUsersByIds(<String>[userId]);
    return users.isEmpty ? null : users.first;
  }

  Future<Map<String, dynamic>?> getTennisCenterById(String tennisCenterId) async {
    final center = await getTennisCenter(tennisCenterId);
    if (center == null) {
      return null;
    }

    return <String, dynamic>{
      'id': center.id,
      'name': center.name,
      'description': center.description,
      'phoneNumber': center.phoneNumber,
      'email': center.email,
      'website': center.website,
      'amenities': center.amenities,
      'managerIds': center.managerIds,
      'address': center.address.toMap(),
      'latitude': center.location.latitude,
      'longitude': center.location.longitude,
      'images': center.images,
      'operatingHours': center.operatingHours.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
    };
  }

  Future<List<TennisCenterModel>> getTennisCenters() async {
    final centerRows = await _client
        .from('tennis_centers')
        .select()
        .order('name');

    final rows = (centerRows as List)
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);

    return _buildTennisCenterModels(rows);
  }

  Future<List<TennisCenter>> getTennisCentersForMap() async {
    final centerRows = await _client
        .from('tennis_centers')
        .select()
        .order('name');

    final rows = (centerRows as List)
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);

    if (rows.isEmpty) {
      return const <TennisCenter>[];
    }

    final ids = rows.map((row) => row['id'] as String).toList(growable: false);
    final hoursByCenter = await _fetchCenterHours(ids);
    final imagesByCenter = await _fetchCenterImages(ids);
    final courtCountByCenter = await _fetchCourtCounts(ids);

    return rows
        .map(
          (row) => _mapTennisCenterForMap(
            row,
            hoursRows: hoursByCenter[row['id'] as String] ?? const <Map<String, dynamic>>[],
            imageRows: imagesByCenter[row['id'] as String] ?? const <Map<String, dynamic>>[],
            courtCount: courtCountByCenter[row['id'] as String] ?? 0,
          ),
        )
        .toList(growable: false);
  }

  Future<TennisCenterModel?> getTennisCenter(String id) async {
    final row = await _client
        .from('tennis_centers')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (row == null) {
      return null;
    }

    final hoursByCenter = await _fetchCenterHours(<String>[id]);
    final imagesByCenter = await _fetchCenterImages(<String>[id]);
    final managersByCenter = await _fetchCenterManagers(<String>[id]);

    return _mapTennisCenterModel(
      Map<String, dynamic>.from(row),
      hoursRows: hoursByCenter[id] ?? const <Map<String, dynamic>>[],
      imageRows: imagesByCenter[id] ?? const <Map<String, dynamic>>[],
      managerIds: managersByCenter[id] ?? const <String>[],
    );
  }

  Future<List<Map<String, dynamic>>> getCourtsForTennisCenter(String tennisCenterId) async {
    final courtRows = await _client
        .from('courts')
        .select()
        .eq('center_id', tennisCenterId)
        .order('name');

    return (courtRows as List)
        .map((row) => _mapCourtRowToLegacyMap(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<List<CourtModel>> getCourts(String tennisCenterId) async {
    final courtRows = await _client
        .from('courts')
        .select()
        .eq('center_id', tennisCenterId)
        .order('name');

    final rows = (courtRows as List)
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);

    final ids = rows.map((row) => row['id'] as String).toList(growable: false);
    final imageRows = await _fetchCourtImages(ids);

    return rows
        .map(
          (row) => _mapCourtModel(
            row,
            imageRows: imageRows[row['id'] as String] ?? const <Map<String, dynamic>>[],
          ),
        )
        .toList(growable: false);
  }

  Future<CourtModel?> getCourt(String tennisCenterId, String courtId) async {
    final row = await _client
        .from('courts')
        .select()
        .eq('center_id', tennisCenterId)
        .eq('id', courtId)
        .maybeSingle();

    if (row == null) {
      return null;
    }

    final imageRows = await _fetchCourtImages(<String>[courtId]);
    return _mapCourtModel(
      Map<String, dynamic>.from(row),
      imageRows: imageRows[courtId] ?? const <Map<String, dynamic>>[],
    );
  }

  Future<String> createOrUpdateTennisCenter(
    TennisCenterModel tennisCenter, {
    required String ownerUserId,
  }) async {
    final payload = <String, dynamic>{
      'name': tennisCenter.name,
      'description': tennisCenter.description,
      'phone_number': tennisCenter.phoneNumber,
      'email': tennisCenter.email.isEmpty ? null : tennisCenter.email,
      'website': tennisCenter.website,
      'street': tennisCenter.address.street,
      'city': tennisCenter.address.city,
      'state': tennisCenter.address.state,
      'postal_code': tennisCenter.address.zipCode,
      'country': tennisCenter.address.country,
      'latitude': tennisCenter.location.latitude,
      'longitude': tennisCenter.location.longitude,
      'amenities': tennisCenter.amenities,
      'created_by': ownerUserId,
      'is_active': true,
    };

    late final Map<String, dynamic> savedRow;
    if (_looksLikeUuid(tennisCenter.id)) {
      final result = await _client
          .from('tennis_centers')
          .upsert(
            <String, dynamic>{
              'id': tennisCenter.id,
              ...payload,
            },
            onConflict: 'id',
          )
          .select()
          .single();
      savedRow = Map<String, dynamic>.from(result);
    } else {
      final result = await _client
          .from('tennis_centers')
          .insert(payload)
          .select()
          .single();
      savedRow = Map<String, dynamic>.from(result);
    }

    final centerId = savedRow['id'] as String;
    await _replaceCenterOperatingHours(centerId, tennisCenter.operatingHours);
    return centerId;
  }

  Future<String> addCourt(String tennisCenterId, Map<String, dynamic> courtData) async {
    final payload = <String, dynamic>{
      'center_id': tennisCenterId,
      'name': (courtData['name'] as String?)?.trim() ?? 'Court',
      'surface': _normalizeSurface(courtData['surface'] as String?),
      'indoor': courtData['indoor'] as bool? ?? false,
      'has_lighting':
          courtData['hasLighting'] as bool? ?? courtData['lighting'] as bool? ?? false,
      'hourly_rate': _readDouble(
        courtData['hourlyRate'] ?? courtData['pricePerHour'],
        fallback: 0,
      ),
      'features': List<String>.from(courtData['features'] as List? ?? const <String>[]),
      'status': (courtData['active'] as bool? ?? true) ? 'active' : 'inactive',
    };

    final created = await _client
        .from('courts')
        .insert(payload)
        .select()
        .single();

    final courtId = created['id'] as String;
    final availability = courtData['availability'];
    if (availability is Map<String, dynamic>) {
      await updateCourtAvailability(tennisCenterId, courtId, availability);
    }

    return courtId;
  }

  Future<void> updateCourt(
    String tennisCenterId,
    String courtId,
    Map<String, dynamic> courtData,
  ) async {
    final updates = <String, dynamic>{};

    if (courtData.containsKey('name')) {
      updates['name'] = (courtData['name'] as String?)?.trim();
    }
    if (courtData.containsKey('surface')) {
      updates['surface'] = _normalizeSurface(courtData['surface'] as String?);
    }
    if (courtData.containsKey('indoor')) {
      updates['indoor'] = courtData['indoor'] as bool? ?? false;
    }
    if (courtData.containsKey('hasLighting') || courtData.containsKey('lighting')) {
      updates['has_lighting'] =
          courtData['hasLighting'] as bool? ?? courtData['lighting'] as bool? ?? false;
    }
    if (courtData.containsKey('hourlyRate') || courtData.containsKey('pricePerHour')) {
      updates['hourly_rate'] = _readDouble(
        courtData['hourlyRate'] ?? courtData['pricePerHour'],
        fallback: 0,
      );
    }
    if (courtData.containsKey('features')) {
      updates['features'] = List<String>.from(
        courtData['features'] as List? ?? const <String>[],
      );
    }

    if (updates.isNotEmpty) {
      await _client
          .from('courts')
          .update(updates)
          .eq('center_id', tennisCenterId)
          .eq('id', courtId);
    }
  }

  Future<void> deleteCourt(String tennisCenterId, String courtId) async {
    await _client
        .from('courts')
        .delete()
        .eq('center_id', tennisCenterId)
        .eq('id', courtId);
  }

  Future<void> updateTennisCenterField(
    String tennisCenterId,
    String field,
    dynamic value,
  ) async {
    if (field == 'operatingHours' && value is Map<String, dynamic>) {
      await _replaceCenterOperatingHours(tennisCenterId, value);
      return;
    }

    if (field == 'address') {
      final address = validateAddress(value);
      await _client.from('tennis_centers').update(
        <String, dynamic>{
          'street': address['street'],
          'city': address['city'],
          'state': address['state'],
          'postal_code': address['zipCode'],
          'country': address['country'],
        },
      ).eq('id', tennisCenterId);
      return;
    }

    final mappedField = <String, String>{
      'phoneNumber': 'phone_number',
      'isActive': 'is_active',
    }[field] ??
        field;

    await _client
        .from('tennis_centers')
        .update(<String, dynamic>{mappedField: value})
        .eq('id', tennisCenterId);
  }

  Future<Map<String, dynamic>> getTennisCenterOperatingHours(String tennisCenterId) async {
    final rows = await _client
        .from('center_operating_hours')
        .select()
        .eq('center_id', tennisCenterId);

    return _rowsToOperatingHoursMap(
      (rows as List)
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false),
    );
  }

  Future<Map<String, dynamic>> getCourtOperatingHours(
    String tennisCenterId,
    String courtId,
  ) async {
    final rows = await _client
        .from('court_operating_hours')
        .select()
        .eq('court_id', courtId);

    return _rowsToOperatingHoursMap(
      (rows as List)
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false),
    );
  }

  Future<void> updateCourtAvailability(
    String tennisCenterId,
    String courtId,
    Map<String, dynamic>? availability,
  ) async {
    await _client
        .from('court_operating_hours')
        .delete()
        .eq('court_id', courtId);

    if (availability == null || availability.isEmpty) {
      return;
    }

    final rows = _operatingHoursMapToRows(
      availability,
      foreignKey: 'court_id',
      foreignId: courtId,
    );

    if (rows.isNotEmpty) {
      await _client.from('court_operating_hours').insert(rows);
    }
  }

  Future<List<AvailabilitySlot>> getAvailability(
    String tennisCenterId,
    String courtId,
    DateTime date,
  ) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final availability = await getCourtAvailability(
      tennisCenterId,
      courtId,
      formattedDate,
    );

    return availability
        .map(
          (slot) => AvailabilitySlot(
            id: slot.id,
            date: slot.date,
            startTime: slot.startTime,
            endTime: slot.endTime,
            status: slot.status.name,
            price: slot.price,
            specialEvent: slot.specialEvent,
            maxPlayers: slot.maxPlayers,
            bookingId: slot.bookingId,
          ),
        )
        .toList(growable: false);
  }

  Future<List<AvailabilityModel>> getCourtAvailability(
    String tennisCenterId,
    String courtId,
    String formattedDate,
  ) async {
    try {
      final rows = await _client.rpc(
        'get_court_day_availability',
        params: <String, dynamic>{
          'target_court_id': courtId,
          'target_date': formattedDate,
        },
      );

      return (rows as List)
          .map((row) => Map<String, dynamic>.from(row))
          .map(
            (row) => AvailabilityModel(
              id: row['slot_id'] as String,
              date: row['slot_date'] as String? ?? formattedDate,
              startTime: row['start_time'] as String? ?? '',
              endTime: row['end_time'] as String? ?? '',
              status: _availabilityStatusFromDb(row['status'] as String?),
              price: _readDouble(row['price'], fallback: 0),
              specialEvent: row['special_event'] as bool? ?? false,
              maxPlayers: row['max_players'] as int? ?? 2,
              bookingId: row['booking_id'] as String?,
            ),
          )
          .toList(growable: false);
    } catch (e) {
      debugPrint('Error getting court availability: $e');
      return const <AvailabilityModel>[];
    }
  }

  Future<String> createBooking(BookingModel booking) async {
    final startsAt = _bookingDateTime(booking.date, booking.startTime);
    final endsAt = _bookingDateTime(booking.date, booking.endTime);

    final payload = <String, dynamic>{
      'center_id': booking.tennisCenter,
      'court_id': booking.courtId,
      'created_by': booking.creatorId,
      'opponent_user_id': booking.inviteeId,
      'status': _bookingStatusToDb(booking.status),
      'payment_status': _paymentStatusToDb(booking.paymentStatus),
      'total_amount': booking.totalAmount,
      'amount_per_player': booking.amountPerPlayer,
      'starts_at': startsAt.toIso8601String(),
      'ends_at': endsAt.toIso8601String(),
      'confirmed_at': booking.confirmedAt?.toIso8601String(),
    };

    final created = await _client
        .from('bookings')
        .insert(payload)
        .select()
        .single();

    return created['id'] as String;
  }

  Future<void> updateBooking(BookingModel booking) async {
    final startsAt = _bookingDateTime(booking.date, booking.startTime);
    final endsAt = _bookingDateTime(booking.date, booking.endTime);

    await _client.from('bookings').update(
      <String, dynamic>{
        'court_id': booking.courtId,
        'center_id': booking.tennisCenter,
        'created_by': booking.creatorId,
        'opponent_user_id': booking.inviteeId,
        'status': _bookingStatusToDb(booking.status),
        'payment_status': _paymentStatusToDb(booking.paymentStatus),
        'total_amount': booking.totalAmount,
        'amount_per_player': booking.amountPerPlayer,
        'starts_at': startsAt.toIso8601String(),
        'ends_at': endsAt.toIso8601String(),
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
      'status': _bookingStatusToDb(status),
    };

    if (status == BookingStatus.confirmed) {
      updates['confirmed_at'] =
          (confirmedAt ?? DateTime.now()).toIso8601String();
    }
    if (status == BookingStatus.cancelled) {
      updates['cancelled_at'] = DateTime.now().toIso8601String();
    }

    await _client
        .from('bookings')
        .update(updates)
        .eq('id', bookingId);
  }

  Future<BookingModel?> getBooking(String bookingId) async {
    final row = await _client
        .from('bookings')
        .select()
        .eq('id', bookingId)
        .maybeSingle();

    if (row == null) {
      return null;
    }

    final bookings = await _mapBookingRows(
      <Map<String, dynamic>>[Map<String, dynamic>.from(row)],
    );
    return bookings.first;
  }

  Future<List<BookingModel>> getTennisCenterBookings(
    String tennisCenterId, {
    String? date,
  }) async {
    var query = _client
        .from('bookings')
        .select()
        .eq('center_id', tennisCenterId);

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
    final rows = await _client
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

  Future<String> createInvitation(InvitationModel invitation) async {
    final responseWindowMinutes = invitation.expiresAt
        .difference(invitation.createdAt)
        .inMinutes
        .clamp(5, 10080);

    final created = await _client
        .from('booking_invitations')
        .insert(
          <String, dynamic>{
            'booking_id': invitation.bookingId,
            'creator_user_id': invitation.creatorId,
            'invitee_user_id': invitation.inviteeId,
            'priority': invitation.priority,
            'status': _invitationStatusToDb(invitation.status),
            'message': invitation.message,
            'expires_at': invitation.expiresAt.toIso8601String(),
            'response_window_minutes': responseWindowMinutes,
          },
        )
        .select()
        .single();

    return created['id'] as String;
  }

  Future<void> updateInvitation(InvitationModel invitation) async {
    await _client.from('booking_invitations').update(
      <String, dynamic>{
        'message': invitation.message,
        'priority': invitation.priority,
        'status': _invitationStatusToDb(invitation.status),
        'expires_at': invitation.expiresAt.toIso8601String(),
      },
    ).eq('id', invitation.id);
  }

  Future<void> updateInvitationStatus(
    String invitationId,
    InvitationStatus status,
    DateTime respondedAt,
  ) async {
    final invitation = await _client
        .from('booking_invitations')
        .select('id,booking_id,invitee_user_id')
        .eq('id', invitationId)
        .maybeSingle();

    if (invitation == null) {
      return;
    }

    final booking = await _client
        .from('bookings')
        .select('id,status,opponent_user_id')
        .eq('id', invitation['booking_id'] as String)
        .maybeSingle();

    final bookingStatus = booking == null
        ? null
        : booking['status'] as String?;

    if ((status == InvitationStatus.accepted || status == InvitationStatus.declined) &&
        bookingStatus == 'pending') {
      await _client.rpc(
        'respond_to_booking_invitation',
        params: <String, dynamic>{
          'target_invitation_id': invitationId,
          'new_status': _invitationStatusToDb(status),
        },
      );
      return;
    }

    await _client.from('booking_invitations').update(
      <String, dynamic>{
        'status': _invitationStatusToDb(status),
        'responded_at': respondedAt.toIso8601String(),
      },
    ).eq('id', invitationId);

    if (status == InvitationStatus.accepted && booking != null) {
      await _client.from('bookings').update(
        <String, dynamic>{
          'opponent_user_id': invitation['invitee_user_id'],
        },
      ).eq('id', booking['id'] as String);
    }
  }

  Future<void> deleteInvitation(String invitationId) async {
    await _client
        .from('booking_invitations')
        .delete()
        .eq('id', invitationId);
  }

  Future<InvitationModel?> getInvitation(String invitationId) async {
    final row = await _client
        .from('booking_invitations')
        .select()
        .eq('id', invitationId)
        .maybeSingle();

    if (row == null) {
      return null;
    }

    final invitations = await _mapInvitationRows(
      <Map<String, dynamic>>[Map<String, dynamic>.from(row)],
    );
    return invitations.first;
  }

  Future<List<InvitationModel>> getSentInvitations(String userId) async {
    final rows = await _client
        .from('booking_invitations')
        .select()
        .eq('creator_user_id', userId)
        .order('created_at', ascending: false);

    return _mapInvitationRows(
      (rows as List)
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false),
    );
  }

  Future<List<InvitationModel>> getReceivedInvitations(String userId) async {
    final rows = await _client
        .from('booking_invitations')
        .select()
        .eq('invitee_user_id', userId)
        .order('created_at', ascending: false);

    return _mapInvitationRows(
      (rows as List)
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false),
    );
  }

  Future<void> addUserContact(String userId, String contactId) async {
    await _client.from('user_contacts').upsert(
      <String, dynamic>{
        'user_id': userId,
        'contact_user_id': contactId,
      },
      onConflict: 'user_id,contact_user_id',
    );
  }

  Future<void> removeUserContact(String userId, String contactId) async {
    await _client
        .from('user_contacts')
        .delete()
        .eq('user_id', userId)
        .eq('contact_user_id', contactId);
  }

  Future<List<UserModel>> getUserContacts(String userId) async {
    final rows = await _client
        .from('user_contacts')
        .select('contact_user_id')
        .eq('user_id', userId);

    final ids = (rows as List)
        .map((row) => row['contact_user_id'] as String)
        .toList(growable: false);

    return _getUsersByIds(ids);
  }

  Map<String, dynamic> validateAddress(dynamic address) {
    if (address is! Map<String, dynamic>) {
      throw Exception(
        'Address must be a map with street, city, state, zipCode, and country fields',
      );
    }

    const requiredFields = <String>[
      'street',
      'city',
      'state',
      'zipCode',
      'country',
    ];

    for (final field in requiredFields) {
      if (!address.containsKey(field) ||
          address[field] == null ||
          address[field].toString().isEmpty) {
        throw Exception('Address is missing required field: $field');
      }
    }

    return <String, dynamic>{
      'street': address['street'].toString(),
      'city': address['city'].toString(),
      'state': address['state'].toString(),
      'zipCode': address['zipCode'].toString(),
      'country': address['country'].toString(),
    };
  }

  Future<void> _upsertUser(UserModel user) async {
    await _client.from('profiles').upsert(
      <String, dynamic>{
        'id': user.id,
        'email': user.email,
        'phone_number': user.phoneNumber,
        'preferred_play_times': user.preferredPlayTimes,
        'preferred_locations': user.preferredLocations,
        'stripe_customer_id': user.stripeCustomerId,
        'onboarding_completed': user.onboardingCompleted,
      },
      onConflict: 'id',
    );

    await _client.from('public_profiles').upsert(
      <String, dynamic>{
        'user_id': user.id,
        'display_name': user.displayName,
        'player_level': user.playerLevel.toString().split('.').last,
        'user_type': user.userType == UserType.courtManager
            ? 'court_manager'
            : 'player',
        'profile_image_path': user.profileImageUrl,
      },
      onConflict: 'user_id',
    );
  }

  Future<List<UserModel>> _getUsersByIds(List<String> ids) async {
    if (ids.isEmpty) {
      return const <UserModel>[];
    }

    final profileRows = await _client
        .from('profiles')
        .select()
        .inFilter('id', ids);
    final publicRows = await _client
        .from('public_profiles')
        .select()
        .inFilter('user_id', ids);
    final managerRows = await _client
        .from('tennis_center_managers')
        .select('user_id,center_id')
        .inFilter('user_id', ids);

    final profileById = <String, Map<String, dynamic>>{};
    for (final row in profileRows as List) {
      final map = Map<String, dynamic>.from(row);
      profileById[map['id'] as String] = map;
    }

    final publicById = <String, Map<String, dynamic>>{};
    for (final row in publicRows as List) {
      final map = Map<String, dynamic>.from(row);
      publicById[map['user_id'] as String] = map;
    }

    final managedCentersByUser = <String, List<String>>{};
    for (final row in managerRows as List) {
      final map = Map<String, dynamic>.from(row);
      managedCentersByUser.putIfAbsent(map['user_id'] as String, () => <String>[])
          .add(map['center_id'] as String);
    }

    final orderedUsers = <UserModel>[];
    for (final id in ids) {
      final profile = profileById[id];
      final publicProfile = publicById[id];
      if (profile == null || publicProfile == null) {
        continue;
      }

      orderedUsers.add(
        UserModel(
          id: id,
          email: profile['email'] as String? ?? '',
          displayName: publicProfile['display_name'] as String? ?? 'Player',
          playerLevel: _playerLevelFromDb(publicProfile['player_level'] as String?),
          userType: _userTypeFromDb(publicProfile['user_type'] as String?),
          createdAt: _parseDbDateTime(profile['created_at']),
          phoneNumber: profile['phone_number'] as String?,
          profileImageUrl: publicProfile['profile_image_path'] as String?,
          preferredPlayTimes: profile['preferred_play_times'] == null
              ? null
              : List<String>.from(profile['preferred_play_times'] as List),
          preferredLocations: profile['preferred_locations'] == null
              ? null
              : List<String>.from(profile['preferred_locations'] as List),
          stripeCustomerId: profile['stripe_customer_id'] as String?,
          paymentMethods: null,
          managedTennisCenters: managedCentersByUser[id],
          onboardingCompleted: profile['onboarding_completed'] as bool? ?? false,
        ),
      );
    }

    return orderedUsers;
  }

  Future<List<TennisCenterModel>> _buildTennisCenterModels(
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) {
      return const <TennisCenterModel>[];
    }

    final ids = rows.map((row) => row['id'] as String).toList(growable: false);
    final hoursByCenter = await _fetchCenterHours(ids);
    final imagesByCenter = await _fetchCenterImages(ids);
    final managersByCenter = await _fetchCenterManagers(ids);

    return rows
        .map(
          (row) => _mapTennisCenterModel(
            row,
            hoursRows: hoursByCenter[row['id'] as String] ?? const <Map<String, dynamic>>[],
            imageRows: imagesByCenter[row['id'] as String] ?? const <Map<String, dynamic>>[],
            managerIds: managersByCenter[row['id'] as String] ?? const <String>[],
          ),
        )
        .toList(growable: false);
  }

  Future<Map<String, List<Map<String, dynamic>>>> _fetchCenterHours(
    List<String> centerIds,
  ) async {
    if (centerIds.isEmpty) {
      return const <String, List<Map<String, dynamic>>>{};
    }

    final rows = await _client
        .from('center_operating_hours')
        .select()
        .inFilter('center_id', centerIds);

    return _groupRowsByKey(
      (rows as List)
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false),
      key: 'center_id',
    );
  }

  Future<Map<String, List<Map<String, dynamic>>>> _fetchCenterImages(
    List<String> centerIds,
  ) async {
    if (centerIds.isEmpty) {
      return const <String, List<Map<String, dynamic>>>{};
    }

    final rows = await _client
        .from('tennis_center_images')
        .select()
        .inFilter('center_id', centerIds)
        .order('sort_order');

    return _groupRowsByKey(
      (rows as List)
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false),
      key: 'center_id',
    );
  }

  Future<Map<String, List<Map<String, dynamic>>>> _fetchCourtImages(
    List<String> courtIds,
  ) async {
    if (courtIds.isEmpty) {
      return const <String, List<Map<String, dynamic>>>{};
    }

    final rows = await _client
        .from('court_images')
        .select()
        .inFilter('court_id', courtIds)
        .order('sort_order');

    return _groupRowsByKey(
      (rows as List)
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false),
      key: 'court_id',
    );
  }

  Future<Map<String, List<String>>> _fetchCenterManagers(List<String> centerIds) async {
    if (centerIds.isEmpty) {
      return const <String, List<String>>{};
    }

    final rows = await _client
        .from('tennis_center_managers')
        .select('center_id,user_id')
        .inFilter('center_id', centerIds);

    final grouped = <String, List<String>>{};
    for (final row in rows as List) {
      final map = Map<String, dynamic>.from(row);
      grouped.putIfAbsent(map['center_id'] as String, () => <String>[])
          .add(map['user_id'] as String);
    }
    return grouped;
  }

  Future<Map<String, int>> _fetchCourtCounts(List<String> centerIds) async {
    if (centerIds.isEmpty) {
      return const <String, int>{};
    }

    final rows = await _client
        .from('courts')
        .select('center_id')
        .inFilter('center_id', centerIds);

    final counts = <String, int>{};
    for (final row in rows as List) {
      final centerId = row['center_id'] as String;
      counts[centerId] = (counts[centerId] ?? 0) + 1;
    }
    return counts;
  }

  TennisCenterModel _mapTennisCenterModel(
    Map<String, dynamic> row, {
    required List<Map<String, dynamic>> hoursRows,
    required List<Map<String, dynamic>> imageRows,
    required List<String> managerIds,
  }) {
    return TennisCenterModel(
      id: row['id'] as String,
      name: row['name'] as String? ?? '',
      address: Address(
        street: row['street'] as String? ?? '',
        city: row['city'] as String? ?? '',
        state: row['state'] as String? ?? '',
        zipCode: row['postal_code'] as String? ?? '',
        country: row['country'] as String? ?? '',
      ),
      location: GeoPoint(
        _readDouble(row['latitude'], fallback: 0),
        _readDouble(row['longitude'], fallback: 0),
      ),
      phoneNumber: row['phone_number'] as String? ?? '',
      email: row['email'] as String? ?? '',
      website: row['website'] as String?,
      description: row['description'] as String? ?? '',
      amenities: List<String>.from(row['amenities'] as List? ?? const <String>[]),
      operatingHours: _rowsToOperatingHoursModels(hoursRows),
      images: imageRows
          .map((image) => _publicStorageUrl('tennis-center-images', image['storage_path'] as String))
          .toList(growable: false),
      stripeAccountId: null,
      createdAt: _parseDbDateTime(row['created_at']),
      rating: _readNullableDouble(row['rating_average']),
      managerIds: managerIds,
    );
  }

  TennisCenter _mapTennisCenterForMap(
    Map<String, dynamic> row, {
    required List<Map<String, dynamic>> hoursRows,
    required List<Map<String, dynamic>> imageRows,
    required int courtCount,
  }) {
    final operatingHours = _rowsToOperatingHoursStringMap(hoursRows);
    return TennisCenter(
      id: row['id'] as String,
      name: row['name'] as String? ?? '',
      address: row['street'] as String? ?? '',
      city: row['city'] as String? ?? '',
      state: row['state'] as String? ?? '',
      zipCode: row['postal_code'] as String? ?? '',
      country: row['country'] as String? ?? '',
      phoneNumber: row['phone_number'] as String? ?? '',
      email: row['email'] as String? ?? '',
      website: row['website'] as String? ?? '',
      description: row['description'] as String? ?? '',
      amenities: List<String>.from(row['amenities'] as List? ?? const <String>[]),
      operatingHours: operatingHours,
      latitude: _readDouble(row['latitude'], fallback: 0),
      longitude: _readDouble(row['longitude'], fallback: 0),
      rating: _readDouble(row['rating_average'], fallback: 0),
      ratingCount: row['rating_count'] as int? ?? 0,
      imageUrls: imageRows
          .map((image) => _publicStorageUrl('tennis-center-images', image['storage_path'] as String))
          .toList(growable: false),
      courtCount: courtCount,
      isActive: row['is_active'] as bool? ?? true,
      createdAt: _parseDbDateTime(row['created_at']),
      updatedAt: _parseDbDateTime(row['updated_at']),
    );
  }

  CourtModel _mapCourtModel(
    Map<String, dynamic> row, {
    required List<Map<String, dynamic>> imageRows,
  }) {
    return CourtModel(
      id: row['id'] as String,
      tennisCenter: row['center_id'] as String? ?? '',
      name: row['name'] as String? ?? '',
      surface: _surfaceTypeFromDb(row['surface'] as String?),
      indoor: row['indoor'] as bool? ?? false,
      hourlyRate: _readDouble(row['hourly_rate'], fallback: 0),
      availability: null,
      images: imageRows
          .map((image) => _publicStorageUrl('court-images', image['storage_path'] as String))
          .toList(growable: false),
      features: List<String>.from(row['features'] as List? ?? const <String>[]),
      rating: _readNullableDouble(row['rating_average']),
      hasLighting: row['has_lighting'] as bool?,
    );
  }

  Map<String, dynamic> _mapCourtRowToLegacyMap(Map<String, dynamic> row) {
    return <String, dynamic>{
      'id': row['id'],
      'tennisCenter': row['center_id'],
      'name': row['name'],
      'surface': row['surface'],
      'indoor': row['indoor'] ?? false,
      'hourlyRate': _readDouble(row['hourly_rate'], fallback: 0),
      'hasLighting': row['has_lighting'] ?? false,
      'features': List<String>.from(row['features'] as List? ?? const <String>[]),
    };
  }

  Future<List<BookingModel>> _mapBookingRows(List<Map<String, dynamic>> rows) async {
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
        : ((await _client
                .from('tennis_centers')
                .select('id,name')
                .inFilter('id', centerIds)) as List)
            .map((row) => Map<String, dynamic>.from(row))
            .toList(growable: false);
    final courtRows = courtIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : ((await _client
                .from('courts')
                .select('id,name')
                .inFilter('id', courtIds)) as List)
            .map((row) => Map<String, dynamic>.from(row))
            .toList(growable: false);
    final users = await _getUsersByIds(userIds);

    final centerNames = <String, String>{
      for (final row in centerRows) row['id'] as String: row['name'] as String? ?? '',
    };
    final courtNames = <String, String>{
      for (final row in courtRows) row['id'] as String: row['name'] as String? ?? '',
    };
    final userNames = <String, String>{
      for (final user in users) user.id: user.displayName,
    };

    return rows.map((row) {
      final startsAt = _parseDbDateTime(row['starts_at']);
      final endsAt = _parseDbDateTime(row['ends_at']);
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
        date: DateFormat('yyyy-MM-dd').format(startsAt),
        startTime: DateFormat('HH:mm').format(startsAt),
        endTime: DateFormat('HH:mm').format(endsAt),
        creatorId: creatorId,
        creatorName: userNames[creatorId],
        inviteeId: inviteeId,
        inviteeName: inviteeId == null ? null : userNames[inviteeId],
        status: _bookingStatusFromDb(row['status'] as String?),
        paymentStatus: _paymentStatusFromDb(row['payment_status'] as String?),
        creatorPaymentId: null,
        inviteePaymentId: null,
        totalAmount: _readDouble(row['total_amount'], fallback: 0),
        amountPerPlayer: _readDouble(row['amount_per_player'], fallback: 0),
        price: _readNullableDouble(row['amount_per_player']),
        createdAt: _parseDbDateTime(row['created_at']),
        confirmedAt: row['confirmed_at'] == null
            ? null
            : _parseDbDateTime(row['confirmed_at']),
      );
    }).toList(growable: false);
  }

  Future<List<InvitationModel>> _mapInvitationRows(
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) {
      return const <InvitationModel>[];
    }

    final userIds = rows
        .expand<String>(
          (row) => <String?>[
            row['creator_user_id'] as String?,
            row['invitee_user_id'] as String?,
          ].whereType<String>(),
        )
        .toSet()
        .toList(growable: false);

    final users = await _getUsersByIds(userIds);
    final userNames = <String, String>{
      for (final user in users) user.id: user.displayName,
    };

    return rows.map((row) {
      final creatorId = row['creator_user_id'] as String? ?? '';
      final inviteeId = row['invitee_user_id'] as String? ?? '';
      return InvitationModel(
        id: row['id'] as String,
        bookingId: row['booking_id'] as String? ?? '',
        creatorId: creatorId,
        inviteeId: inviteeId,
        inviteeName: userNames[inviteeId],
        creatorName: userNames[creatorId],
        status: _invitationStatusFromDb(row['status'] as String?),
        createdAt: _parseDbDateTime(row['created_at']),
        expiresAt: row['expires_at'] == null
            ? DateTime.now().add(const Duration(days: 1))
            : _parseDbDateTime(row['expires_at']),
        respondedAt: row['responded_at'] == null
            ? null
            : _parseDbDateTime(row['responded_at']),
        priority: row['priority'] as int? ?? 1,
        message: row['message'] as String?,
      );
    }).toList(growable: false);
  }

  Future<void> _replaceCenterOperatingHours(
    String centerId,
    Map<String, dynamic> operatingHours,
  ) async {
    await _client
        .from('center_operating_hours')
        .delete()
        .eq('center_id', centerId);

    final rows = _operatingHoursMapToRows(
      operatingHours,
      foreignKey: 'center_id',
      foreignId: centerId,
    );
    if (rows.isNotEmpty) {
      await _client.from('center_operating_hours').insert(rows);
    }
  }

  List<Map<String, dynamic>> _operatingHoursMapToRows(
    Map<String, dynamic> operatingHours, {
    required String foreignKey,
    required String foreignId,
  }) {
    final rows = <Map<String, dynamic>>[];
    for (final entry in operatingHours.entries) {
      final dayIndex = _dayNames.indexOf(entry.key.toLowerCase());
      if (dayIndex == -1) {
        continue;
      }

      final value = Map<String, dynamic>.from(entry.value as Map);
      final isClosed = value['isClosed'] as bool? ?? false;
      rows.add(
        <String, dynamic>{
          foreignKey: foreignId,
          'day_of_week': dayIndex,
          'opens_at': isClosed ? null : value['open'],
          'closes_at': isClosed ? null : value['close'],
          'is_closed': isClosed,
        },
      );
    }
    return rows;
  }

  Map<String, dynamic> _rowsToOperatingHoursMap(List<Map<String, dynamic>> rows) {
    final result = <String, dynamic>{};
    for (final row in rows) {
      final dayIndex = row['day_of_week'] as int? ?? 0;
      final dayName = _dayNames[dayIndex];
      result[dayName] = <String, dynamic>{
        'open': row['opens_at'] as String?,
        'close': row['closes_at'] as String?,
        'isClosed': row['is_closed'] as bool? ?? false,
      };
    }
    return result;
  }

  Map<String, OperatingHours> _rowsToOperatingHoursModels(List<Map<String, dynamic>> rows) {
    final result = <String, OperatingHours>{};
    for (final row in rows) {
      final dayIndex = row['day_of_week'] as int? ?? 0;
      final dayName = _dayNames[dayIndex];
      result[dayName] = OperatingHours(
        open: row['opens_at'] as String? ?? '09:00',
        close: row['closes_at'] as String? ?? '21:00',
        isClosed: row['is_closed'] as bool? ?? false,
      );
    }
    return result;
  }

  Map<String, Map<String, String>> _rowsToOperatingHoursStringMap(
    List<Map<String, dynamic>> rows,
  ) {
    final result = <String, Map<String, String>>{};
    for (final row in rows) {
      final dayIndex = row['day_of_week'] as int? ?? 0;
      final dayName = _dayNames[dayIndex];
      result[dayName] = <String, String>{
        'open': row['opens_at'] as String? ?? '',
        'close': row['closes_at'] as String? ?? '',
      };
    }
    return result;
  }

  Map<String, List<Map<String, dynamic>>> _groupRowsByKey(
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

  DateTime _bookingDateTime(String date, String time) {
    final parsedDate = DateFormat('yyyy-MM-dd').parse(date);
    final formats = <String>['HH:mm', 'H:mm', 'h:mm a', 'hh:mm a'];

    for (final pattern in formats) {
      try {
        final parsedTime = DateFormat(pattern).parse(time);
        return DateTime(
          parsedDate.year,
          parsedDate.month,
          parsedDate.day,
          parsedTime.hour,
          parsedTime.minute,
        );
      } catch (_) {
        // Try the next format.
      }
    }

    throw FormatException('Unsupported time format: $time');
  }

  DateTime _parseDbDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value).toLocal();
    }
    return DateTime.now();
  }

  double _readDouble(dynamic value, {required double fallback}) {
    if (value == null) {
      return fallback;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString()) ?? fallback;
  }

  double? _readNullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  String _normalizeSurface(String? value) {
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

  SurfaceType _surfaceTypeFromDb(String? value) {
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

  BookingStatus _bookingStatusFromDb(String? value) {
    switch (value) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'pending':
      default:
        return BookingStatus.pending;
    }
  }

  String _bookingStatusToDb(BookingStatus status) {
    return status.toString().split('.').last;
  }

  PaymentStatus _paymentStatusFromDb(String? value) {
    switch (value) {
      case 'partial':
        return PaymentStatus.partial;
      case 'complete':
        return PaymentStatus.complete;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'pending':
      default:
        return PaymentStatus.pending;
    }
  }

  String _paymentStatusToDb(PaymentStatus status) {
    return status.toString().split('.').last;
  }

  InvitationStatus _invitationStatusFromDb(String? value) {
    switch (value) {
      case 'accepted':
        return InvitationStatus.accepted;
      case 'declined':
        return InvitationStatus.declined;
      case 'expired':
        return InvitationStatus.expired;
      case 'pending':
      default:
        return InvitationStatus.pending;
    }
  }

  String _invitationStatusToDb(InvitationStatus status) {
    return status.toString().split('.').last;
  }

  AvailabilityStatus _availabilityStatusFromDb(String? value) {
    switch (value) {
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

  PlayerLevel _playerLevelFromDb(String? value) {
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

  UserType _userTypeFromDb(String? value) {
    switch (value) {
      case 'court_manager':
        return UserType.courtManager;
      case 'player':
      default:
        return UserType.player;
    }
  }

  bool _looksLikeUuid(String value) {
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    return uuidPattern.hasMatch(value);
  }

  String _publicStorageUrl(String bucket, String storagePath) {
    return _client.storage.from(bucket).getPublicUrl(storagePath);
  }
}
