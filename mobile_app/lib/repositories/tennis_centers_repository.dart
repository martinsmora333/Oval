import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/availability_model.dart';
import '../models/court_model.dart';
import '../models/geo_point.dart';
import '../models/tennis_center.dart';
import '../models/tennis_center_model.dart';
import 'repository_support.dart';

class TennisCentersRepository extends RepositorySupport {
  TennisCentersRepository._internal();

  static final TennisCentersRepository _instance =
      TennisCentersRepository._internal();

  factory TennisCentersRepository() => _instance;

  static const List<String> _dayNames = <String>[
    'sunday',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
  ];

  Future<Map<String, dynamic>?> getTennisCenterById(
      String tennisCenterId) async {
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
    final centerRows =
        await client.from('tennis_centers').select().order('name');

    final rows = (centerRows as List)
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);

    return _buildTennisCenterModels(rows);
  }

  Future<List<TennisCenter>> getTennisCentersForMap() async {
    final centerRows =
        await client.from('tennis_centers').select().order('name');

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
            hoursRows: hoursByCenter[row['id'] as String] ??
                const <Map<String, dynamic>>[],
            imageRows: imagesByCenter[row['id'] as String] ??
                const <Map<String, dynamic>>[],
            courtCount: courtCountByCenter[row['id'] as String] ?? 0,
          ),
        )
        .toList(growable: false);
  }

  Future<TennisCenterModel?> getTennisCenter(String id) async {
    final row =
        await client.from('tennis_centers').select().eq('id', id).maybeSingle();

    if (row == null) {
      return null;
    }

    final hoursByCenter = await _fetchCenterHours(<String>[id]);
    final imagesByCenter = await _fetchCenterImages(<String>[id]);
    final managersByCenter = await _fetchCenterManagers(<String>[id]);
    final courtCountByCenter = await _fetchCourtCounts(<String>[id]);
    final minimumRateByCenter = await _fetchMinimumCourtRates(<String>[id]);

    return _mapTennisCenterModel(
      Map<String, dynamic>.from(row),
      hoursRows: hoursByCenter[id] ?? const <Map<String, dynamic>>[],
      imageRows: imagesByCenter[id] ?? const <Map<String, dynamic>>[],
      courtCount: courtCountByCenter[id] ?? 0,
      pricePerHour: minimumRateByCenter[id] ?? 0,
      managerIds: managersByCenter[id] ?? const <String>[],
    );
  }

  Future<List<Map<String, dynamic>>> getCourtsForTennisCenter(
      String tennisCenterId) async {
    final courtRows = await client
        .from('courts')
        .select()
        .eq('center_id', tennisCenterId)
        .order('name');

    return (courtRows as List)
        .map((row) => _mapCourtRowToLegacyMap(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<List<CourtModel>> getCourts(String tennisCenterId) async {
    final courtRows = await client
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
            imageRows: imageRows[row['id'] as String] ??
                const <Map<String, dynamic>>[],
          ),
        )
        .toList(growable: false);
  }

  Future<CourtModel?> getCourt(String tennisCenterId, String courtId) async {
    final row = await client
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
    if (looksLikeUuid(tennisCenter.id)) {
      final result = await client
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
      final result =
          await client.from('tennis_centers').insert(payload).select().single();
      savedRow = Map<String, dynamic>.from(result);
    }

    final centerId = savedRow['id'] as String;
    await _replaceCenterOperatingHours(centerId, tennisCenter.operatingHours);
    return centerId;
  }

  Future<String> addCourt(
      String tennisCenterId, Map<String, dynamic> courtData) async {
    final payload = <String, dynamic>{
      'center_id': tennisCenterId,
      'name': (courtData['name'] as String?)?.trim() ?? 'Court',
      'surface': normalizeSurface(courtData['surface'] as String?),
      'indoor': courtData['indoor'] as bool? ?? false,
      'has_lighting': courtData['hasLighting'] as bool? ??
          courtData['lighting'] as bool? ??
          false,
      'hourly_rate': readDouble(
        courtData['hourlyRate'] ?? courtData['pricePerHour'],
        fallback: 0,
      ),
      'features':
          List<String>.from(courtData['features'] as List? ?? const <String>[]),
      'status': (courtData['active'] as bool? ?? true) ? 'active' : 'inactive',
    };

    final created =
        await client.from('courts').insert(payload).select().single();

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
      updates['surface'] = normalizeSurface(courtData['surface'] as String?);
    }
    if (courtData.containsKey('indoor')) {
      updates['indoor'] = courtData['indoor'] as bool? ?? false;
    }
    if (courtData.containsKey('hasLighting') ||
        courtData.containsKey('lighting')) {
      updates['has_lighting'] = courtData['hasLighting'] as bool? ??
          courtData['lighting'] as bool? ??
          false;
    }
    if (courtData.containsKey('hourlyRate') ||
        courtData.containsKey('pricePerHour')) {
      updates['hourly_rate'] = readDouble(
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
      await client
          .from('courts')
          .update(updates)
          .eq('center_id', tennisCenterId)
          .eq('id', courtId);
    }
  }

  Future<void> deleteCourt(String tennisCenterId, String courtId) async {
    await client
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
      await client.from('tennis_centers').update(
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

    await client
        .from('tennis_centers')
        .update(<String, dynamic>{mappedField: value}).eq('id', tennisCenterId);
  }

  Future<Map<String, dynamic>> getTennisCenterOperatingHours(
      String tennisCenterId) async {
    final rows = await client
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
    final rows = await client
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
    await client.from('court_operating_hours').delete().eq('court_id', courtId);

    if (availability == null || availability.isEmpty) {
      return;
    }

    final rows = _operatingHoursMapToRows(
      availability,
      foreignKey: 'court_id',
      foreignId: courtId,
    );

    if (rows.isNotEmpty) {
      await client.from('court_operating_hours').insert(rows);
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
      final rows = await client.rpc(
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
              startsAt: _parseAvailabilityInstant(row['starts_at']),
              endsAt: _parseAvailabilityInstant(row['ends_at']),
              status: _availabilityStatusFromDb(row['status'] as String?),
              price: readDouble(row['price'], fallback: 0),
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

  DateTime? _parseAvailabilityInstant(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value.isUtc ? value : value.toUtc();
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value).toUtc();
    }
    return null;
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
    final courtCountByCenter = await _fetchCourtCounts(ids);
    final minimumRateByCenter = await _fetchMinimumCourtRates(ids);

    return rows
        .map(
          (row) => _mapTennisCenterModel(
            row,
            hoursRows: hoursByCenter[row['id'] as String] ??
                const <Map<String, dynamic>>[],
            imageRows: imagesByCenter[row['id'] as String] ??
                const <Map<String, dynamic>>[],
            courtCount: courtCountByCenter[row['id'] as String] ?? 0,
            pricePerHour: minimumRateByCenter[row['id'] as String] ?? 0,
            managerIds:
                managersByCenter[row['id'] as String] ?? const <String>[],
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

    final rows = await client
        .from('center_operating_hours')
        .select()
        .inFilter('center_id', centerIds);

    return groupRowsByKey(
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

    final rows = await client
        .from('tennis_center_images')
        .select()
        .inFilter('center_id', centerIds)
        .order('sort_order');

    return groupRowsByKey(
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

    final rows = await client
        .from('court_images')
        .select()
        .inFilter('court_id', courtIds)
        .order('sort_order');

    return groupRowsByKey(
      (rows as List)
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false),
      key: 'court_id',
    );
  }

  Future<Map<String, List<String>>> _fetchCenterManagers(
      List<String> centerIds) async {
    if (centerIds.isEmpty) {
      return const <String, List<String>>{};
    }

    final rows = await client
        .from('tennis_center_managers')
        .select('center_id,user_id')
        .inFilter('center_id', centerIds);

    final grouped = <String, List<String>>{};
    for (final row in rows as List) {
      final map = Map<String, dynamic>.from(row);
      grouped.putIfAbsent(map['center_id'] as String, () => <String>[]).add(
            map['user_id'] as String,
          );
    }
    return grouped;
  }

  Future<Map<String, int>> _fetchCourtCounts(List<String> centerIds) async {
    if (centerIds.isEmpty) {
      return const <String, int>{};
    }

    final rows = await client
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

  Future<Map<String, double>> _fetchMinimumCourtRates(
    List<String> centerIds,
  ) async {
    if (centerIds.isEmpty) {
      return const <String, double>{};
    }

    final rows = await client
        .from('courts')
        .select('center_id,hourly_rate')
        .inFilter('center_id', centerIds);

    final minimumRates = <String, double>{};
    for (final row in rows as List) {
      final centerId = row['center_id'] as String;
      final hourlyRate = readDouble(row['hourly_rate'], fallback: 0);

      final currentMinimum = minimumRates[centerId];
      if (currentMinimum == null || hourlyRate < currentMinimum) {
        minimumRates[centerId] = hourlyRate;
      }
    }

    return minimumRates;
  }

  TennisCenterModel _mapTennisCenterModel(
    Map<String, dynamic> row, {
    required List<Map<String, dynamic>> hoursRows,
    required List<Map<String, dynamic>> imageRows,
    required int courtCount,
    required double pricePerHour,
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
        readDouble(row['latitude'], fallback: 0),
        readDouble(row['longitude'], fallback: 0),
      ),
      phoneNumber: row['phone_number'] as String? ?? '',
      email: row['email'] as String? ?? '',
      website: row['website'] as String?,
      description: row['description'] as String? ?? '',
      amenities:
          List<String>.from(row['amenities'] as List? ?? const <String>[]),
      operatingHours: _rowsToOperatingHoursModels(hoursRows),
      images: imageRows
          .map((image) => publicStorageUrl(
              'tennis-center-images', image['storage_path'] as String?))
          .where((url) => url.isNotEmpty)
          .toList(growable: false),
      stripeAccountId: null,
      createdAt: parseDbDateTime(row['created_at']),
      rating: readNullableDouble(row['rating_average']),
      reviewCount: row['rating_count'] as int? ?? 0,
      courtCount: courtCount,
      pricePerHour: pricePerHour,
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
      amenities:
          List<String>.from(row['amenities'] as List? ?? const <String>[]),
      operatingHours: operatingHours,
      latitude: readDouble(row['latitude'], fallback: 0),
      longitude: readDouble(row['longitude'], fallback: 0),
      rating: readDouble(row['rating_average'], fallback: 0),
      ratingCount: row['rating_count'] as int? ?? 0,
      imageUrls: imageRows
          .map((image) => publicStorageUrl(
              'tennis-center-images', image['storage_path'] as String?))
          .where((url) => url.isNotEmpty)
          .toList(growable: false),
      courtCount: courtCount,
      isActive: row['is_active'] as bool? ?? true,
      createdAt: parseDbDateTime(row['created_at']),
      updatedAt: parseDbDateTime(row['updated_at']),
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
      surface: surfaceTypeFromDb(row['surface'] as String?),
      indoor: row['indoor'] as bool? ?? false,
      hourlyRate: readDouble(row['hourly_rate'], fallback: 0),
      availability: null,
      images: imageRows
          .map((image) => publicStorageUrl(
              'court-images', image['storage_path'] as String?))
          .where((url) => url.isNotEmpty)
          .toList(growable: false),
      features: List<String>.from(row['features'] as List? ?? const <String>[]),
      rating: readNullableDouble(row['rating_average']),
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
      'hourlyRate': readDouble(row['hourly_rate'], fallback: 0),
      'hasLighting': row['has_lighting'] ?? false,
      'features':
          List<String>.from(row['features'] as List? ?? const <String>[]),
    };
  }

  Future<void> _replaceCenterOperatingHours(
    String centerId,
    Map<String, dynamic> operatingHours,
  ) async {
    await client
        .from('center_operating_hours')
        .delete()
        .eq('center_id', centerId);

    final rows = _operatingHoursMapToRows(
      operatingHours,
      foreignKey: 'center_id',
      foreignId: centerId,
    );
    if (rows.isNotEmpty) {
      await client.from('center_operating_hours').insert(rows);
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

      final value = entry.value;
      late final Map<String, dynamic> hourValue;
      if (value is OperatingHours) {
        hourValue = value.toMap();
      } else if (value is Map<String, dynamic>) {
        hourValue = value;
      } else if (value is Map) {
        hourValue = Map<String, dynamic>.from(value);
      } else {
        continue;
      }

      final isClosed = hourValue['isClosed'] as bool? ?? false;
      rows.add(
        <String, dynamic>{
          foreignKey: foreignId,
          'day_of_week': dayIndex,
          'opens_at': isClosed ? null : hourValue['open'],
          'closes_at': isClosed ? null : hourValue['close'],
          'is_closed': isClosed,
        },
      );
    }
    return rows;
  }

  Map<String, dynamic> _rowsToOperatingHoursMap(
      List<Map<String, dynamic>> rows) {
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

  Map<String, OperatingHours> _rowsToOperatingHoursModels(
      List<Map<String, dynamic>> rows) {
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
}
