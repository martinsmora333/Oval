import '../models/availability_model.dart';
import '../models/booking_model.dart';
import '../models/court_model.dart';
import '../models/invitation_model.dart';
import '../models/tennis_center.dart';
import '../models/tennis_center_model.dart';
import '../models/user_model.dart';
import '../repositories/bookings_repository.dart';
import '../repositories/invitations_repository.dart';
import '../repositories/profiles_repository.dart';
import '../repositories/tennis_centers_repository.dart';

class DataService {
  DataService._internal();

  static final DataService _instance = DataService._internal();

  factory DataService() => _instance;

  final ProfilesRepository _profilesRepository = ProfilesRepository();
  final TennisCentersRepository _tennisCentersRepository =
      TennisCentersRepository();
  final BookingsRepository _bookingsRepository = BookingsRepository();
  final InvitationsRepository _invitationsRepository = InvitationsRepository();

  Future<List<UserModel>> getUsers() => _profilesRepository.getUsers();

  Future<List<UserModel>> getUsersByEmail(String email) =>
      _profilesRepository.getUsersByEmail(email);

  Future<List<UserModel>> searchUsers(String searchTerm) =>
      _profilesRepository.searchUsers(searchTerm);

  Future<void> createUser(UserModel user) =>
      _profilesRepository.createUser(user);

  Future<void> updateUser(UserModel user) =>
      _profilesRepository.updateUser(user);

  Future<UserModel?> getUser(String userId) =>
      _profilesRepository.getUser(userId);

  Future<void> addUserContact(String userId, String contactId) =>
      _profilesRepository.addUserContact(userId, contactId);

  Future<void> removeUserContact(String userId, String contactId) =>
      _profilesRepository.removeUserContact(userId, contactId);

  Future<List<UserModel>> getUserContacts(String userId) =>
      _profilesRepository.getUserContacts(userId);

  Future<Map<String, dynamic>?> getTennisCenterById(String tennisCenterId) =>
      _tennisCentersRepository.getTennisCenterById(tennisCenterId);

  Future<List<TennisCenterModel>> getTennisCenters() =>
      _tennisCentersRepository.getTennisCenters();

  Future<List<TennisCenter>> getTennisCentersForMap() =>
      _tennisCentersRepository.getTennisCentersForMap();

  Future<TennisCenterModel?> getTennisCenter(String id) =>
      _tennisCentersRepository.getTennisCenter(id);

  Future<List<Map<String, dynamic>>> getCourtsForTennisCenter(
          String tennisCenterId) =>
      _tennisCentersRepository.getCourtsForTennisCenter(tennisCenterId);

  Future<List<CourtModel>> getCourts(String tennisCenterId) =>
      _tennisCentersRepository.getCourts(tennisCenterId);

  Future<CourtModel?> getCourt(String tennisCenterId, String courtId) =>
      _tennisCentersRepository.getCourt(tennisCenterId, courtId);

  Future<String> createOrUpdateTennisCenter(
    TennisCenterModel tennisCenter, {
    required String ownerUserId,
  }) =>
      _tennisCentersRepository.createOrUpdateTennisCenter(
        tennisCenter,
        ownerUserId: ownerUserId,
      );

  Future<String> addCourt(
          String tennisCenterId, Map<String, dynamic> courtData) =>
      _tennisCentersRepository.addCourt(tennisCenterId, courtData);

  Future<void> updateCourt(
    String tennisCenterId,
    String courtId,
    Map<String, dynamic> courtData,
  ) =>
      _tennisCentersRepository.updateCourt(tennisCenterId, courtId, courtData);

  Future<void> deleteCourt(String tennisCenterId, String courtId) =>
      _tennisCentersRepository.deleteCourt(tennisCenterId, courtId);

  Future<void> updateTennisCenterField(
    String tennisCenterId,
    String field,
    dynamic value,
  ) =>
      _tennisCentersRepository.updateTennisCenterField(
          tennisCenterId, field, value);

  Future<Map<String, dynamic>> getTennisCenterOperatingHours(
          String tennisCenterId) =>
      _tennisCentersRepository.getTennisCenterOperatingHours(tennisCenterId);

  Future<Map<String, dynamic>> getCourtOperatingHours(
    String tennisCenterId,
    String courtId,
  ) =>
      _tennisCentersRepository.getCourtOperatingHours(tennisCenterId, courtId);

  Future<void> updateCourtAvailability(
    String tennisCenterId,
    String courtId,
    Map<String, dynamic>? availability,
  ) =>
      _tennisCentersRepository.updateCourtAvailability(
        tennisCenterId,
        courtId,
        availability,
      );

  Future<List<AvailabilitySlot>> getAvailability(
    String tennisCenterId,
    String courtId,
    DateTime date,
  ) =>
      _tennisCentersRepository.getAvailability(tennisCenterId, courtId, date);

  Future<List<AvailabilityModel>> getCourtAvailability(
    String tennisCenterId,
    String courtId,
    String formattedDate,
  ) =>
      _tennisCentersRepository.getCourtAvailability(
        tennisCenterId,
        courtId,
        formattedDate,
      );

  Future<String> createBooking(BookingModel booking) =>
      _bookingsRepository.createBooking(booking);

  Future<void> updateBooking(BookingModel booking) =>
      _bookingsRepository.updateBooking(booking);

  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status, {
    DateTime? confirmedAt,
  }) =>
      _bookingsRepository.updateBookingStatus(
        bookingId,
        status,
        confirmedAt: confirmedAt,
      );

  Future<BookingModel?> getBooking(String bookingId) =>
      _bookingsRepository.getBooking(bookingId);

  Future<List<BookingModel>> getTennisCenterBookings(
    String tennisCenterId, {
    String? date,
  }) =>
      _bookingsRepository.getTennisCenterBookings(tennisCenterId, date: date);

  Future<List<BookingModel>> getUserBookings(
    String userId, {
    bool forceRefresh = false,
  }) =>
      _bookingsRepository.getUserBookings(userId, forceRefresh: forceRefresh);

  Future<String> createInvitation(InvitationModel invitation) =>
      _invitationsRepository.createInvitation(invitation);

  Future<void> updateInvitation(InvitationModel invitation) =>
      _invitationsRepository.updateInvitation(invitation);

  Future<void> updateInvitationStatus(
    String invitationId,
    InvitationStatus status,
    DateTime respondedAt,
  ) =>
      _invitationsRepository.updateInvitationStatus(
        invitationId,
        status,
        respondedAt,
      );

  Future<void> deleteInvitation(String invitationId) =>
      _invitationsRepository.deleteInvitation(invitationId);

  Future<InvitationModel?> getInvitation(String invitationId) =>
      _invitationsRepository.getInvitation(invitationId);

  Future<List<InvitationModel>> getSentInvitations(String userId) =>
      _invitationsRepository.getSentInvitations(userId);

  Future<List<InvitationModel>> getReceivedInvitations(String userId) =>
      _invitationsRepository.getReceivedInvitations(userId);

  Map<String, dynamic> validateAddress(dynamic address) =>
      _tennisCentersRepository.validateAddress(address);
}
