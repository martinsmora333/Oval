import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';

import '../models/availability_model.dart';
import '../models/booking_model.dart';
import '../repositories/bookings_repository.dart';
import '../repositories/tennis_centers_repository.dart';

class BookingProvider with ChangeNotifier {
  final BookingsRepository _bookingsRepository = BookingsRepository();
  final TennisCentersRepository _tennisCentersRepository =
      TennisCentersRepository();

  List<BookingModel> _userBookings = [];
  List<BookingModel> _tennisCenterBookings = [];
  List<AvailabilityModel> _availableTimeSlots = [];
  String _tennisCenterName = '';
  bool _isLoading = false;
  String? _error;
  bool _initialLoadDone = false;

  List<BookingModel> get userBookings => _userBookings;
  List<BookingModel> get tennisCenterBookings => _tennisCenterBookings;
  List<AvailabilityModel> get availableTimeSlots => _availableTimeSlots;
  String get tennisCenterName => _tennisCenterName;
  bool get isLoading => _isLoading;
  String? get error => _error;
  void _notifyListenersSafely() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      super.notifyListeners();
      return;
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) {
        super.notifyListeners();
      }
    });
  }


  Future<void> loadUserBookings(String userId,
      {bool forceRefresh = false}) async {
    if (!forceRefresh && _initialLoadDone && _userBookings.isNotEmpty) {
      debugPrint('Using in-memory bookings data, skipping backend refresh');
      return;
    }

    _isLoading = true;
    _error = null;
    _notifyListenersSafely();

    try {
      _userBookings = await _bookingsRepository
          .getUserBookings(userId, forceRefresh: forceRefresh)
          .timeout(const Duration(seconds: 5), onTimeout: () {
        debugPrint('Booking fetch timed out, returning empty list');
        return <BookingModel>[];
      });

      if (_userBookings.isEmpty) {
        debugPrint('No bookings found for user');
      }

      _initialLoadDone = true;
    } catch (e) {
      _error = 'Failed to load bookings';
      debugPrint('Error loading bookings: $e');
      _userBookings = <BookingModel>[];
    } finally {
      _isLoading = false;
      _notifyListenersSafely();
    }
  }

  Future<void> refreshBookings(String userId) {
    return loadUserBookings(userId, forceRefresh: true);
  }

  Future<void> loadCourtAvailability(
    String tennisCenterId,
    String courtId,
    DateTime date,
  ) async {
    _isLoading = true;
    _error = null;
    _notifyListenersSafely();

    try {
      final tennisCenter =
          await _tennisCentersRepository.getTennisCenter(tennisCenterId);
      _tennisCenterName = tennisCenter?.name ?? '';

      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      _availableTimeSlots = await _tennisCentersRepository.getCourtAvailability(
        tennisCenterId,
        courtId,
        formattedDate,
      );
      _availableTimeSlots.sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (e) {
      _error = 'Failed to load availability';
      debugPrint('Error loading availability: $e');
    } finally {
      _isLoading = false;
      _notifyListenersSafely();
    }
  }

  Future<String> createBooking(BookingModel booking) async {
    _isLoading = true;
    _error = null;
    _notifyListenersSafely();

    try {
      final bookingId = await _bookingsRepository.createBooking(booking);
      await loadUserBookings(booking.creatorId, forceRefresh: true);
      return bookingId;
    } catch (e) {
      _error = 'Failed to create booking';
      debugPrint('Error creating booking: $e');
      throw Exception('Failed to create booking: $e');
    } finally {
      _isLoading = false;
      _notifyListenersSafely();
    }
  }

  Future<bool> cancelBooking(String bookingId, String userId) async {
    _isLoading = true;
    _error = null;
    _notifyListenersSafely();

    try {
      await _bookingsRepository.cancelBooking(
        bookingId,
        cancelReason: 'user_cancelled',
      );
      await loadUserBookings(userId, forceRefresh: true);
      return true;
    } catch (e) {
      _error = 'Failed to cancel booking';
      debugPrint('Error cancelling booking: $e');
      return false;
    } finally {
      _isLoading = false;
      _notifyListenersSafely();
    }
  }

  Future<bool> cancelTennisCenterBooking(
    String bookingId,
    String tennisCenterId, {
    String? date,
  }) async {
    _isLoading = true;
    _error = null;
    _notifyListenersSafely();

    try {
      await _bookingsRepository.cancelBooking(
        bookingId,
        cancelReason: 'manager_cancelled',
      );
      await loadTennisCenterBookings(tennisCenterId, date: date);
      return true;
    } catch (e) {
      _error = 'Failed to cancel tennis center booking';
      debugPrint('Error cancelling tennis center booking: $e');
      return false;
    } finally {
      _isLoading = false;
      _notifyListenersSafely();
    }
  }

  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      return await _bookingsRepository.getBooking(bookingId);
    } catch (e) {
      _error = 'Failed to get booking details';
      debugPrint('Error getting booking: $e');
      return null;
    }
  }

  List<BookingModel> getBookingsByStatus(BookingStatus status) {
    return _userBookings.where((booking) => booking.status == status).toList();
  }

  List<BookingModel> getUpcomingBookings() {
    final now = DateTime.now();
    return _userBookings
        .where((booking) =>
            booking.status != BookingStatus.cancelled &&
            booking.isUpcoming(now))
        .toList();
  }

  List<BookingModel> getPastBookings() {
    final now = DateTime.now();
    return _userBookings.where((booking) => !booking.isUpcoming(now)).toList();
  }

  Future<void> loadTennisCenterBookings(String tennisCenterId,
      {String? date}) async {
    _isLoading = true;
    _error = null;
    _tennisCenterBookings = <BookingModel>[];
    _notifyListenersSafely();

    try {
      if (tennisCenterId.isEmpty) {
        _error = 'Invalid tennis center ID';
        return;
      }

      final tennisCenter =
          await _tennisCentersRepository.getTennisCenter(tennisCenterId);
      _tennisCenterName = tennisCenter?.name ?? 'Tennis Center';

      _tennisCenterBookings = List<BookingModel>.from(
        await _bookingsRepository.getTennisCenterBookings(
          tennisCenterId,
          date: date,
        ),
      );
      _tennisCenterBookings.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    } catch (e) {
      _error = 'Failed to load tennis center bookings';
      debugPrint('Error loading tennis center bookings: $e');
      _tennisCenterBookings = <BookingModel>[];
    } finally {
      _isLoading = false;
      _notifyListenersSafely();
    }
  }
}
