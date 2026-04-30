import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../invitations/create_invitation_screen.dart';
import '../../widgets/squircle_button.dart';
import '../../widgets/squircle_container.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String bookingId;
  final bool autoOpenInviteComposer;

  const BookingDetailsScreen({
    super.key,
    required this.bookingId,
    this.autoOpenInviteComposer = false,
  });

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  BookingModel? _booking;
  bool _isLoading = true;
  String? _error;
  bool _didHandleAutoInvite = false;

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
  }

  Future<void> _loadBookingDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = Provider.of<BookingProvider>(context, listen: false);
      final booking = await provider.getBookingById(widget.bookingId);

      if (mounted) {
        setState(() {
          _booking = booking;
          _isLoading = false;
        });
        _maybeOpenInviteComposer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load booking details: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelBooking() async {
    if (_booking == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);

      if (authProvider.user != null) {
        final success = await bookingProvider.cancelBooking(
            _booking!.id, authProvider.user!.uid);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Booking cancelled successfully')),
            );

            // Refresh booking details
            _loadBookingDetails();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to cancel booking')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error cancelling booking: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
            'Are you sure you want to cancel this booking? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep It'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelBooking();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _invitePlayer() {
    if (_booking == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateInvitationScreen(
          bookingId: _booking!.id,
          courtName: _booking!.courtName ?? 'Court',
          tennisCenterName: _booking!.tennisCenterName ?? 'Tennis Center',
          date: _parseBookingDate(_booking!),
          startTime: _parseBookingTime(_booking!, _booking!.startTime),
          endTime: _parseBookingTime(_booking!, _booking!.endTime),
        ),
      ),
    ).then((_) => _loadBookingDetails());
  }

  void _maybeOpenInviteComposer() {
    if (_didHandleAutoInvite ||
        !widget.autoOpenInviteComposer ||
        _booking == null) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.uid;
    final isCreator =
        currentUserId != null && currentUserId == _booking!.creatorId;
    final canInvite = _booking!.isUpcoming(DateTime.now()) &&
        isCreator &&
        _booking!.status == BookingStatus.pending &&
        _booking!.inviteeId == null;

    if (!canInvite) {
      _didHandleAutoInvite = true;
      return;
    }

    _didHandleAutoInvite = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _invitePlayer();
    });
  }

  DateTime _parseBookingDate(BookingModel booking) {
    return DateTime(
      booking.startsAt.year,
      booking.startsAt.month,
      booking.startsAt.day,
    );
  }

  DateTime _parseBookingTime(BookingModel booking, String timeString) {
    if (timeString == booking.startTime) {
      return booking.startsAt;
    }
    if (timeString == booking.endTime) {
      return booking.endsAt;
    }
    return booking.startsAt;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Booking Details'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Booking Details'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_circle,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading booking details',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadBookingDetails,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_booking == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Booking Details'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Booking not found'),
        ),
      );
    }

    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    final bookingDate = _parseBookingDate(_booking!);
    final startTime = _parseBookingTime(_booking!, _booking!.startTime);
    final endTime = _parseBookingTime(_booking!, _booking!.endTime);

    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.uid;
    final isCreator = currentUserId != null && currentUserId == _booking!.creatorId;
    final isOpponent = currentUserId != null && currentUserId == _booking!.inviteeId;
    final isUpcoming = _booking!.isUpcoming(DateTime.now());
    final canCancel = isUpcoming &&
        (isCreator || isOpponent) &&
        (_booking!.status == BookingStatus.pending ||
            _booking!.status == BookingStatus.confirmed);
    final canInvite = isUpcoming &&
        isCreator &&
        _booking!.status == BookingStatus.pending &&
        _booking!.inviteeId == null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Booking Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            SquircleContainer(
              color: Colors.white,
              cornerRadius: 12,
              cornerSmoothing: 0.6,
              border: Border.all(color: Colors.grey[200]!),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Booking Status',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        SquircleContainer(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          color: _getStatusColor(_booking!.status),
                          cornerRadius: 20,
                          cornerSmoothing: 0.6,
                          child: Text(
                            _booking!.statusString,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Payment Status',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _getPaymentIcon(_booking!.paymentStatus),
                          color: _getPaymentColor(_booking!.paymentStatus),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _booking!.paymentStatusString,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getPaymentColor(_booking!.paymentStatus),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Date and time section
            const Text(
              'Date & Time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            SquircleContainer(
              color: Colors.white,
              cornerRadius: 12,
              cornerSmoothing: 0.6,
              border: Border.all(color: Colors.grey[200]!),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.calendar,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          dateFormat.format(bookingDate),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.time,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${timeFormat.format(startTime)} - ${timeFormat.format(endTime)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.time,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_getDurationInHours(startTime, endTime)} hour(s)',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Court details section
            const Text(
              'Court Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            SquircleContainer(
              color: Colors.white,
              cornerRadius: 12,
              cornerSmoothing: 0.6,
              border: Border.all(color: Colors.grey[200]!),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _booking!.courtName ?? 'Court',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _booking!.tennisCenterName ?? 'Tennis Center',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Payment details section
            const Text(
              'Payment Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            SquircleContainer(
              color: Colors.white,
              cornerRadius: 12,
              cornerSmoothing: 0.6,
              border: Border.all(color: Colors.grey[200]!),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Court Fee',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          _booking!.formattedTotalAmount,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (_booking!.inviteeId != null) ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Your Share',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            _booking!.formattedAmountPerPlayer,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (_booking!.status == BookingStatus.confirmed &&
                        _booking!.paymentStatus != PaymentStatus.complete) ...[
                      SquircleButton(
                        label: 'Make Payment',
                        onPressed: () {
                          // Navigate to payment screen
                        },
                        width: double.infinity,
                        height: 50,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Players section
            const Text(
              'Players',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            SquircleContainer(
              color: Colors.white,
              cornerRadius: 12,
              cornerSmoothing: 0.6,
              border: Border.all(color: Colors.grey[200]!),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          radius: 20,
                          child: const Icon(
                            CupertinoIcons.person,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _booking!.creatorName ?? 'You',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Booking Creator',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_booking!.inviteeId != null &&
                        _booking!.inviteeName != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.orange,
                            radius: 20,
                            child: const Icon(
                              CupertinoIcons.person,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _booking!.inviteeName!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Invited Player',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else if (canInvite) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _invitePlayer,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.person_add,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Invite a Player',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Cancel booking button
            if (canCancel)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _showCancelDialog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel Booking',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.draft:
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.completed:
        return Colors.blue;
      case BookingStatus.noShow:
        return Colors.deepOrange;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }

  Color _getPaymentColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.partial:
        return Colors.blue;
      case PaymentStatus.complete:
        return Colors.green;
      case PaymentStatus.refunded:
        return Colors.purple;
      case PaymentStatus.failed:
        return Colors.red;
    }
  }

  IconData _getPaymentIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return CupertinoIcons.hourglass;
      case PaymentStatus.partial:
        return CupertinoIcons.money_dollar_circle;
      case PaymentStatus.complete:
        return CupertinoIcons.checkmark_circle;
      case PaymentStatus.refunded:
        return CupertinoIcons.arrow_counterclockwise_circle;
      case PaymentStatus.failed:
        return CupertinoIcons.xmark_circle;
    }
  }

  String _getDurationInHours(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final hours = duration.inMinutes / 60;
    return hours.toStringAsFixed(1);
  }
}
