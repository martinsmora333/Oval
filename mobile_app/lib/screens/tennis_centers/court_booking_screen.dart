import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/court_model.dart';
import '../../models/availability_model.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/squircle_container.dart';
import '../bookings/booking_details_screen.dart';

class CourtBookingScreen extends StatefulWidget {
  final CourtModel court;
  final String tennisCenterId;

  const CourtBookingScreen({
    super.key,
    required this.court,
    required this.tennisCenterId,
  });

  @override
  State<CourtBookingScreen> createState() => _CourtBookingScreenState();
}

class _CourtBookingScreenState extends State<CourtBookingScreen> {
  DateTime _selectedDate = DateTime.now();
  AvailabilityModel? _selectedTimeSlot;
  bool _isInvitingPlayer = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Load availability for the selected date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAvailability();
    });
  }

  void _loadAvailability() {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    provider.loadCourtAvailability(
      widget.tennisCenterId,
      widget.court.id,
      _selectedDate,
    );
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = null;
      });
      _loadAvailability();
    }
  }

  Future<void> _bookCourt() async {
    if (_selectedTimeSlot == null || _isSubmitting) {
      if (_selectedTimeSlot == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a time slot')),
        );
      }
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);

    if (authProvider.user == null || authProvider.userModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to book a court')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final booking = BookingModel(
        id: '',
        courtId: widget.court.id,
        tennisCenter: widget.tennisCenterId,
        creatorId: authProvider.user!.uid,
        creatorName: authProvider.userModel!.displayName,
        startsAt: _selectedTimeSlot!.startsAt ??
            BookingModel.combineDateAndTime(
              _selectedDate,
              _selectedTimeSlot!.startTime,
            ),
        endsAt: _selectedTimeSlot!.endsAt ??
            BookingModel.combineDateAndTime(
              _selectedDate,
              _selectedTimeSlot!.endTime,
            ),
        price: widget.court.pricePerHour,
        status: BookingStatus.pending,
        paymentStatus: PaymentStatus.pending,
        totalAmount: widget.court.pricePerHour,
        amountPerPlayer: widget.court.pricePerHour / 2,
        createdAt: DateTime.now(),
      );

      final bookingId = await bookingProvider.createBooking(booking);
      if (!mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      final successMessage = _isInvitingPlayer
          ? 'Booking hold created. Choose a player to invite next.'
          : 'Booking hold created.';

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => BookingDetailsScreen(
            bookingId: bookingId,
            autoOpenInviteComposer: _isInvitingPlayer,
          ),
        ),
      );
      messenger.showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error booking court: $e')),
      );
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Book a Court',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Court info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.court.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getSurfaceColor(widget.court.surfaceType),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.court.surfaceType,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${widget.court.pricePerHour.toStringAsFixed(0)} per hour',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Date selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Date',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(CupertinoIcons.calendar),
                  label: Text(
                    DateFormat('MMM d, yyyy').format(_selectedDate),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Time slots
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Available Time Slots',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Time slots grid
          Expanded(
            child: Consumer<BookingProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.availableTimeSlots.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No available time slots for this date',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => _selectDate(context),
                          child: const Text('Select Another Date'),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: provider.availableTimeSlots.length,
                  itemBuilder: (context, index) {
                    final timeSlot = provider.availableTimeSlots[index];
                    final isSelected = _selectedTimeSlot == timeSlot;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedTimeSlot = timeSlot;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: SquircleContainer(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[100],
                        cornerRadius: 8,
                        cornerSmoothing: 0.6,
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[300]!,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${timeSlot.startTime} - '
                          '${timeSlot.endTime}',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Booking options
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Invite player checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _isInvitingPlayer,
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              setState(() {
                                _isInvitingPlayer = value ?? false;
                              });
                            },
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                    const Text(
                      'Invite a player after booking',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Book button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedTimeSlot != null && !_isSubmitting
                        ? _bookCourt
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Book Court for \$${_selectedTimeSlot != null ? widget.court.pricePerHour.toStringAsFixed(0) : '0'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSurfaceColor(String surfaceType) {
    switch (surfaceType.toLowerCase()) {
      case 'clay':
        return Colors.deepOrange;
      case 'grass':
        return Colors.green;
      case 'hard':
        return Colors.blue;
      case 'carpet':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
