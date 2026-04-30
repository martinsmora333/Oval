import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/auth_provider.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/squircle_container.dart';
import '../../utils/responsive_utils.dart';
import '../bookings/booking_details_screen.dart';

class BookingsManagementScreen extends StatefulWidget {
  final String tennisCenterId;
  final bool showScaffold;

  const BookingsManagementScreen({
    super.key,
    required this.tennisCenterId,
    this.showScaffold = true,
  });

  @override
  State<BookingsManagementScreen> createState() =>
      _BookingsManagementScreenState();
}

class _BookingsManagementScreenState extends State<BookingsManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadBookings();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BookingsManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tennisCenterId != widget.tennisCenterId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadBookings();
        }
      });
    }
  }

  Future<void> _loadBookings() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDay);

      // Check if we have a valid tennis center ID
      if (widget.tennisCenterId.isNotEmpty) {
        await bookingProvider.loadTennisCenterBookings(
          widget.tennisCenterId,
          date: formattedDate,
        );
      } else {
        // Handle case where tennis center ID is not valid
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid tennis center selected')),
        );
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load bookings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });

      _loadBookings();
    }
  }

  void _openBookingDetails(String bookingId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailsScreen(bookingId: bookingId),
      ),
    );
  }

  Future<void> _cancelBooking(BookingModel booking) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    if (currentUser == null) {
      return;
    }

    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDay);
    final success = await bookingProvider.cancelTennisCenterBooking(
      booking.id,
      widget.tennisCenterId,
      date: formattedDate,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Booking cancelled' : 'Failed to cancel booking',
        ),
      ),
    );
  }

  Future<void> _showCancelDialog(BookingModel booking) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cancel booking'),
            content: const Text(
              'This will cancel the booking for all players. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Keep booking'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Cancel booking'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) {
      return;
    }

    await _cancelBooking(booking);
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);
    final bookings = bookingProvider.tennisCenterBookings;
    final tennisCenterName = bookingProvider.tennisCenterName;

    // Initialize responsive utils for this screen
    ResponsiveUtils.init(context);

    // Calculate responsive sizes
    final double verticalSpacing = ResponsiveUtils.blockSizeVertical * 2;
    final double horizontalSpacing = ResponsiveUtils.blockSizeHorizontal * 3;

    final tabBar = TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: 'Day View'),
        Tab(text: 'Week View'),
      ],
      onTap: (index) {
        setState(() {
          _calendarFormat =
              index == 0 ? CalendarFormat.week : CalendarFormat.twoWeeks;
        });
      },
    );

    final calendarAndList = Column(
      children: [
        // Calendar
        TableCalendar(
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: _onDaySelected,
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          calendarStyle: CalendarStyle(
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),

        // Bookings list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : bookings.isEmpty
                  ? _buildEmptyState()
                  : _buildBookingsList(
                      bookings, verticalSpacing, horizontalSpacing),
        ),
      ],
    );

    if (!widget.showScaffold) {
      return Column(
        children: [
          Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: tabBar,
          ),
          Expanded(child: calendarAndList),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Bookings - $tennisCenterName'),
        automaticallyImplyLeading: false,
        bottom: tabBar,
      ),
      body: calendarAndList,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.calendar_badge_minus,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Bookings Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no bookings for this date.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List<BookingModel> bookings, double verticalSpacing,
      double horizontalSpacing) {
    return ListView.builder(
      padding: EdgeInsets.all(horizontalSpacing),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildBookingCard(booking, verticalSpacing, horizontalSpacing);
      },
    );
  }

  Widget _buildBookingCard(
      BookingModel booking, double verticalSpacing, double horizontalSpacing) {
    // Determine status color
    Color statusColor;
    switch (booking.status) {
      case BookingStatus.confirmed:
        statusColor = Colors.green;
        break;
      case BookingStatus.cancelled:
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
        break;
    }

    final canCancel = booking.status == BookingStatus.pending ||
        booking.status == BookingStatus.confirmed;

    return SquircleContainer(
      margin: EdgeInsets.only(bottom: verticalSpacing),
      padding: EdgeInsets.all(horizontalSpacing),
      color: Colors.white,
      cornerRadius: 16,
      cornerSmoothing: 0.6,
      child: InkWell(
        onTap: () => _openBookingDetails(booking.id),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Court and time info
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.courtName ?? 'Court',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  booking.status.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Time slot
          Row(
            children: [
              Icon(CupertinoIcons.time, color: Colors.grey[600], size: 16),
              const SizedBox(width: 8),
              Text(
                '${booking.startTime} - ${booking.endTime}',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Players
          Row(
            children: [
              Icon(CupertinoIcons.person_2_fill,
                  color: Colors.grey[600], size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  booking.inviteeId != null
                      ? '${booking.creatorName ?? 'Player'} & ${booking.inviteeName ?? 'Guest'}'
                      : booking.creatorName ?? 'Player',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Payment status
          Row(
            children: [
              Icon(CupertinoIcons.money_dollar_circle,
                  color: Colors.grey[600], size: 16),
              const SizedBox(width: 8),
              Text(
                'Payment: ${booking.paymentStatus.toString().split('.').last}',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const Spacer(),
              Text(
                '\$${booking.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(CupertinoIcons.info_circle, size: 16),
                label: const Text('Details'),
                onPressed: () {
                  _openBookingDetails(booking.id);
                },
              ),
              if (canCancel) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(CupertinoIcons.xmark_circle, size: 16),
                  label: const Text('Cancel'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  onPressed: () => _showCancelDialog(booking),
                ),
              ],
            ],
          ),
        ],
        ),
      ),
    );
  }
}
