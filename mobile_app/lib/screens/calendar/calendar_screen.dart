import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/booking_model.dart';
import '../../widgets/squircle_button.dart';
import '../../widgets/squircle_container.dart';
import '../bookings/booking_details_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, this.showScaffold = true});

  final bool showScaffold;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<BookingModel>> _bookingEvents = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDay = _focusedDay;
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

  // Format date and time for display
  String _formatDateTime(DateTime dateTime) {
    return '${DateFormat('EEE, MMM d, y').format(dateTime)} • ${DateFormat('h:mm a').format(dateTime)}';
  }

  // Get booking date time
  DateTime _getBookingDateTime(BookingModel booking) {
    try {
      final date = booking.date;
      final time = booking.startTime;
      final dateTimeStr = '$date ${time.padLeft(5, '0')}';
      return DateFormat('yyyy-MM-dd HH:mm').parse(dateTimeStr);
    } catch (e) {
      return DateTime.now();
    }
  }

  // Launch maps with tennis center address
  Future<void> _launchMaps(String address) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _loadBookings() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);

      // Check if we already have data to avoid unnecessary loading
      if (bookingProvider.userBookings.isEmpty) {
        // Set a loading indicator
        setState(() {
          _isLoading = true;
        });

        // Use a timeout to prevent UI freezing if the backend is slow
        await bookingProvider
            .loadUserBookings(authProvider.user!.uid)
            .timeout(const Duration(seconds: 5), onTimeout: () {
          debugPrint('Calendar bookings load timed out');
          return;
        });

        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Convert bookings to format expected by the calendar
  Map<DateTime, List<BookingModel>> _getBookingEvents() {
    final bookingProvider = Provider.of<BookingProvider>(context);
    Map<DateTime, List<BookingModel>> events = {};

    for (var booking in bookingProvider.userBookings) {
      // Parse date string to DateTime
      final dateParts = booking.date.split('-');
      if (dateParts.length == 3) {
        try {
          final year = int.parse(dateParts[0]);
          final month = int.parse(dateParts[1]);
          final day = int.parse(dateParts[2]);

          final bookingDate = DateTime(year, month, day);

          if (events[bookingDate] != null) {
            events[bookingDate]!.add(booking);
          } else {
            events[bookingDate] = [booking];
          }
        } catch (e) {
          // Skip invalid dates
          debugPrint('Error parsing date: ${booking.date}');
        }
      }
    }

    return events;
  }

  List<BookingModel> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _bookingEvents[normalizedDay] ?? [];
  }

  Future<void> _refreshCalendarData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      setState(() {
        _isLoading = true;
      });
      await bookingProvider.refreshBookings(authProvider.user!.uid);
      setState(() {
        _isLoading = false;
        _bookingEvents = _getBookingEvents();
      });
    }
    return Future.value();
  }

  // Build booking card widget
  Widget _buildBookingCard(BookingModel booking, BuildContext context) {
    final dateTime = _getBookingDateTime(booking);
    final isPast = dateTime.isBefore(DateTime.now());
    final opponentName = booking.inviteeName ?? 'Solo Play';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to booking details
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and time row
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: isPast
                        ? Colors.grey
                        : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatDateTime(dateTime),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isPast ? Colors.grey.shade600 : Colors.black,
                      ),
                    ),
                  ),
                  // Edit button
                  IconButton(
                    icon:
                        Icon(Icons.edit, size: 20, color: Colors.grey.shade600),
                    onPressed: () {
                      // TODO: Implement edit functionality
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  // Map button
                  IconButton(
                    icon: Icon(Icons.location_on,
                        size: 20, color: Colors.blue.shade600),
                    onPressed: () {
                      final address =
                          '${booking.tennisCenterName}, ${booking.tennisCenter}';
                      _launchMaps(address);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tennis center name and address
              Text(
                booking.tennisCenterName ?? 'Tennis Court',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isPast ? Colors.grey.shade600 : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                booking.tennisCenter,
                style: TextStyle(
                  fontSize: 14,
                  color: isPast ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),

              // Opponent info
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 20,
                    color: isPast ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Playing with: $opponentName',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isPast ? Colors.grey.shade500 : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return TabBar(
      controller: _tabController,
      labelColor: Theme.of(context).colorScheme.primary,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Theme.of(context).colorScheme.primary,
      tabs: const [
        Tab(icon: Icon(CupertinoIcons.calendar)),
        Tab(icon: Icon(CupertinoIcons.list_bullet)),
      ],
    );
  }

  Widget _buildTabView() {
    return TabBarView(
      controller: _tabController,
      children: [
        // Calendar Tab
        RefreshIndicator(
          onRefresh: _refreshCalendarData,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                eventLoader: _getEventsForDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  }
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() => _calendarFormat = format);
                  }
                },
                availableCalendarFormats: const {
                  CalendarFormat.week: 'Week',
                  CalendarFormat.month: 'Month',
                },
                onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                calendarStyle: CalendarStyle(
                  markerDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.red[100],
                    border: Border.all(color: Colors.red, width: 2.0),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  formatButtonTextStyle: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Consumer<BookingProvider>(
                builder: (context, bookingProvider, _) {
                  if (_isLoading || bookingProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final dayEvents = _selectedDay != null
                      ? _getEventsForDay(_selectedDay!)
                      : [];

                  if (dayEvents.isEmpty) {
                    return SizedBox(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.calendar,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedDay == null
                                  ? 'Select a date to view bookings'
                                  : 'No bookings for this day',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dayEvents.length,
                    itemBuilder: (context, index) {
                      return _buildBookingCard(dayEvents[index], context);
                    },
                  );
                },
              ),
            ],
          ),
        ),

        // Bookings Tab
        Consumer<BookingProvider>(
          builder: (context, bookingProvider, _) {
            if (bookingProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final allBookings =
                List<BookingModel>.from(bookingProvider.userBookings)
                  ..sort((a, b) =>
                      _getBookingDateTime(b).compareTo(_getBookingDateTime(a)));

            if (allBookings.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.calendar,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No bookings yet',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: SquircleButton(
                        label: 'Book a Court',
                        onPressed: () =>
                            Navigator.pushNamed(context, '/tennis_centers'),
                        width: double.infinity,
                        height: 40,
                        labelStyle: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refreshCalendarData,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: allBookings.length,
                itemBuilder: (context, index) {
                  return _buildBookingCard(allBookings[index], context);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _bookingEvents = _getBookingEvents();

    if (widget.showScaffold) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          toolbarHeight: kToolbarHeight * 0.7,
          titleSpacing: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kTextTabBarHeight),
            child: _buildTabBar(context),
          ),
        ),
        body: _buildTabView(),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/tennis_centers'),
          child: const Icon(Icons.add),
        ),
      );
    }

    return Column(
      children: [
        Material(color: Colors.white, child: _buildTabBar(context)),
        Expanded(child: _buildTabView()),
      ],
    );
  }
}

class BookingCard extends StatelessWidget {
  final BookingModel booking;

  const BookingCard({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    // Format time
    final startTime = booking.startTime;
    final endTime = booking.endTime;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingDetailsScreen(bookingId: booking.id),
          ),
        );
      },
      child: SquircleContainer(
        elevation: 2,
        color: Colors.white,
        cornerRadius: 20,
        cornerSmoothing: 0.8,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking.tennisCenterName ?? 'Tennis Center',
                      style: const TextStyle(
                        fontFamily: 'TexGyreAdventor',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: booking.status == BookingStatus.confirmed
                          ? const Color(0xFFE8F5E9) // Light green
                          : booking.status == BookingStatus.pending
                              ? const Color(0xFFFFF8E1) // Light orange
                              : const Color(0xFFFFEBEE), // Light red
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: booking.status == BookingStatus.confirmed
                            ? Theme.of(context).colorScheme.primary
                            : booking.status == BookingStatus.pending
                                ? Colors.orange
                                : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          booking.status == BookingStatus.confirmed
                              ? Icons.check_circle_outline
                              : booking.status == BookingStatus.pending
                                  ? Icons.access_time
                                  : Icons.cancel_outlined,
                          size: 14,
                          color: booking.status == BookingStatus.confirmed
                              ? Theme.of(context).colorScheme.primary
                              : booking.status == BookingStatus.pending
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          booking.statusString,
                          style: TextStyle(
                            color: booking.status == BookingStatus.confirmed
                                ? Theme.of(context).colorScheme.primary
                                : booking.status == BookingStatus.pending
                                    ? Colors.orange
                                    : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Payment status
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  booking.paymentStatusString,
                  style: TextStyle(
                    color: booking.paymentStatus == PaymentStatus.complete
                        ? Colors.green
                        : booking.paymentStatus == PaymentStatus.partial
                            ? Colors.orange
                            : Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(CupertinoIcons.sportscourt,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Court ${booking.courtName ?? ""}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(CupertinoIcons.time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '$startTime - $endTime',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              if (booking.inviteeId != null && booking.inviteeId!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.person_2,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'With ${booking.inviteeName ?? 'a partner'}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

              // Total amount
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      booking.formattedTotalAmount,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
