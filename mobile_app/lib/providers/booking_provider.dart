import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../models/availability_model.dart';
import '../services/data_service.dart';

class BookingProvider with ChangeNotifier {
  final DataService _dataService = DataService();
  
  List<BookingModel> _userBookings = [];
  List<BookingModel> _tennisCenterBookings = [];
  List<AvailabilityModel> _availableTimeSlots = [];
  String _tennisCenterName = '';
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<BookingModel> get userBookings => _userBookings;
  List<BookingModel> get tennisCenterBookings => _tennisCenterBookings;
  List<AvailabilityModel> get availableTimeSlots => _availableTimeSlots;
  String get tennisCenterName => _tennisCenterName;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Internal flag to track initial load
  bool _initialLoadDone = false;

  // Load user bookings with cache prioritization
  Future<void> loadUserBookings(String userId, {bool forceRefresh = false}) async {
    // If we're not forcing a refresh and we already have data, just return
    if (!forceRefresh && _initialLoadDone && _userBookings.isNotEmpty) {
      debugPrint('Using in-memory bookings data, skipping backend refresh');
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Use a timeout to prevent long waits when there's network issues
      _userBookings = await _dataService.getUserBookings(userId, forceRefresh: forceRefresh)
          .timeout(const Duration(seconds: 5), onTimeout: () {
        debugPrint('Booking fetch timed out, returning empty list');
        return []; // Return empty list on timeout
      });
      
      // If we get an empty list, notify immediately
      if (_userBookings.isEmpty) {
        debugPrint('No bookings found for user');
      }
      
      _initialLoadDone = true;
    } catch (e) {
      _error = 'Failed to load bookings';
      debugPrint('Error loading bookings: $e');
      _userBookings = []; // Ensure we have a valid empty list
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Refresh bookings - force backend reload
  Future<void> refreshBookings(String userId) async {
    return loadUserBookings(userId, forceRefresh: true);
  }
  
  // Load court availability
  Future<void> loadCourtAvailability(String tennisCenterId, String courtId, DateTime date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Get tennis center name for display
      final tennisCenter = await _dataService.getTennisCenter(tennisCenterId);
      _tennisCenterName = tennisCenter?.name ?? '';
      
      // Format date for query
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      
      // Get availability slots
      _availableTimeSlots = await _dataService.getCourtAvailability(
        tennisCenterId, 
        courtId, 
        formattedDate
      );
      
      // Sort by start time
      _availableTimeSlots.sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (e) {
      _error = 'Failed to load availability';
      debugPrint('Error loading availability: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Create a booking
  Future<String> createBooking(BookingModel booking) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Create the booking in the backend
      final bookingId = await _dataService.createBooking(booking);
      
      // Refresh user bookings
      await loadUserBookings(booking.creatorId);
      
      return bookingId;
    } catch (e) {
      _error = 'Failed to create booking';
      debugPrint('Error creating booking: $e');
      throw Exception('Failed to create booking: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Cancel a booking
  Future<bool> cancelBooking(String bookingId, String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Cancel the booking in the backend
      await _dataService.updateBookingStatus(
        bookingId, 
        BookingStatus.cancelled
      );
      
      // Refresh user bookings
      await loadUserBookings(userId);
      
      return true;
    } catch (e) {
      _error = 'Failed to cancel booking';
      debugPrint('Error cancelling booking: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get booking by ID
  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      return await _dataService.getBooking(bookingId);
    } catch (e) {
      _error = 'Failed to get booking details';
      debugPrint('Error getting booking: $e');
      return null;
    }
  }
  
  // Filter bookings by status
  List<BookingModel> getBookingsByStatus(BookingStatus status) {
    return _userBookings.where((booking) => booking.status == status).toList();
  }
  
  // Get upcoming bookings
  List<BookingModel> getUpcomingBookings() {
    final now = DateTime.now();
    return _userBookings.where((booking) => 
      booking.status != BookingStatus.cancelled && booking.isUpcoming(now)
    ).toList();
  }
  
  // Get past bookings
  List<BookingModel> getPastBookings() {
    final now = DateTime.now();
    return _userBookings.where((booking) => 
      !booking.isUpcoming(now)
    ).toList();
  }
  
  // Load tennis center bookings
  Future<void> loadTennisCenterBookings(String tennisCenterId, {String? date}) async {
    _isLoading = true;
    _error = null;
    _tennisCenterBookings = []; // Clear existing bookings
    notifyListeners();
    
    try {
      // Validate tennis center ID
      if (tennisCenterId.isEmpty) {
        _error = 'Invalid tennis center ID';
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Get tennis center name for display
      final tennisCenter = await _dataService.getTennisCenter(tennisCenterId);
      _tennisCenterName = tennisCenter?.name ?? 'Tennis Center';
      
      // Get bookings for the tennis center
      try {
        _tennisCenterBookings = await _dataService.getTennisCenterBookings(
          tennisCenterId,
          date: date
        );
        
        // Sort by date and start time if we have bookings
        if (_tennisCenterBookings.isNotEmpty) {
          _tennisCenterBookings.sort((a, b) {
            // First compare dates
            final dateComparison = a.date.compareTo(b.date);
            if (dateComparison != 0) return dateComparison;
            
            // If dates are the same, compare start times
            return a.startTime.compareTo(b.startTime);
          });
        }
      } catch (e) {
        debugPrint('Error fetching bookings: $e');
        _tennisCenterBookings = []; // Ensure we have an empty list on error
      }
    } catch (e) {
      _error = 'Failed to load tennis center bookings';
      debugPrint('Error loading tennis center bookings: $e');
      _tennisCenterBookings = []; // Ensure we have an empty list on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
