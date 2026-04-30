import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/models/availability_model.dart';
import 'package:mobile_app/models/booking_model.dart';
import 'package:mobile_app/repositories/bookings_repository.dart';
import 'package:mobile_app/repositories/tennis_centers_repository.dart';
import 'package:mobile_app/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const RuntimeBookingSmokeApp());
}

class RuntimeBookingSmokeApp extends StatelessWidget {
  const RuntimeBookingSmokeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RuntimeBookingSmokeScreen(),
    );
  }
}

class RuntimeBookingSmokeScreen extends StatefulWidget {
  const RuntimeBookingSmokeScreen({super.key});

  @override
  State<RuntimeBookingSmokeScreen> createState() =>
      _RuntimeBookingSmokeScreenState();
}

class _RuntimeBookingSmokeScreenState extends State<RuntimeBookingSmokeScreen> {
  final StringBuffer _log = StringBuffer();
  bool _running = true;
  bool _passed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _run();
    });
  }

  Future<void> _run() async {
    try {
      final client = SupabaseService.client;
      final user = client.auth.currentUser;
      _append('Current user: ${user?.email ?? 'none'}');

      if (user == null) {
        _finish('No Supabase session found in the simulator app state.');
        return;
      }

      final centersRepository = TennisCentersRepository();
      final bookingsRepository = BookingsRepository();
      final centers = await centersRepository.getTennisCenters();
      if (centers.isEmpty) {
        _finish('No tennis centers available.');
        return;
      }

      final center = centers.firstWhere(
        (candidate) => candidate.name == 'Oval QA Centre',
        orElse: () => centers.first,
      );
      _append('Using center: ${center.name} (${center.id})');

      final courts = await centersRepository.getCourts(center.id);
      if (courts.isEmpty) {
        _finish('No courts available for ${center.name}.');
        return;
      }

      final court = courts.first;
      _append('Using court: ${court.name} (${court.id})');

      final nowUtc = DateTime.now().toUtc().add(const Duration(minutes: 5));
      AvailabilityModel? selectedSlot;
      DateTime? selectedDate;

      for (var offset = 0; offset < 7; offset += 1) {
        final date = DateTime.now().add(Duration(days: offset));
        final formattedDate = DateFormat('yyyy-MM-dd').format(date);
        final availability = await centersRepository.getCourtAvailability(
          center.id,
          court.id,
          formattedDate,
        );

        _append(
          'Checked $formattedDate: ${availability.length} slots returned',
        );

        for (final slot in availability) {
          if (slot.status != AvailabilityStatus.available ||
              slot.startsAt == null ||
              slot.endsAt == null) {
            continue;
          }
          if (slot.startsAt!.isAfter(nowUtc)) {
            selectedSlot = slot;
            selectedDate = date;
            break;
          }
        }

        if (selectedSlot != null) {
          break;
        }
      }

      if (selectedSlot == null || selectedDate == null) {
        _finish('No future available slot found in the next 7 days.');
        return;
      }

      _append(
        'Selected slot: ${DateFormat('yyyy-MM-dd').format(selectedDate)} '
        '${selectedSlot.startTime}-${selectedSlot.endTime} '
        '(${selectedSlot.startsAt!.toIso8601String()} -> '
        '${selectedSlot.endsAt!.toIso8601String()})',
      );

      final totalAmount = selectedSlot.price > 0 ? selectedSlot.price : court.hourlyRate;
      final booking = BookingModel(
        id: '',
        courtId: court.id,
        courtName: court.name,
        tennisCenter: center.id,
        tennisCenterName: center.name,
        tennisCenterAddress: center.address.formattedAddress,
        startsAt: selectedSlot.startsAt!,
        endsAt: selectedSlot.endsAt!,
        creatorId: user.id,
        creatorName: user.userMetadata?['display_name'] as String?,
        inviteeId: null,
        inviteeName: null,
        status: BookingStatus.pending,
        paymentStatus: PaymentStatus.pending,
        creatorPaymentId: null,
        inviteePaymentId: null,
        totalAmount: totalAmount,
        amountPerPlayer: totalAmount / 2,
        price: totalAmount / 2,
        createdAt: DateTime.now().toUtc(),
        confirmedAt: null,
      );

      final bookingId = await bookingsRepository.createBooking(booking);
      _append('Created booking: $bookingId');

      final savedBooking = await bookingsRepository.getBooking(bookingId);
      if (savedBooking == null) {
        _finish('Booking was created but could not be loaded back from Supabase.');
        return;
      }

      _append(
        'Loaded booking: status=${savedBooking.status.dbValue}, '
        'startsAt=${savedBooking.startsAt.toIso8601String()}, '
        'endsAt=${savedBooking.endsAt.toIso8601String()}',
      );

      await bookingsRepository.cancelBooking(
        bookingId,
        cancelReason: 'runtime_qa_cleanup',
      );
      _append('Cancelled booking for cleanup.');

      final cancelledBooking = await bookingsRepository.getBooking(bookingId);
      if (cancelledBooking == null) {
        _finish('Cancelled booking disappeared before verification.');
        return;
      }

      _append(
        'Post-cancel status: ${cancelledBooking.status.dbValue}',
      );
      _finish('PASS', passed: true);
    } catch (error, stackTrace) {
      _finish('FAIL: $error\n\n$stackTrace');
    }
  }

  void _append(String message) {
    _log.writeln(message);
    if (mounted) {
      setState(() {});
    }
  }

  void _finish(String message, {bool passed = false}) {
    _append(message);
    if (mounted) {
      setState(() {
        _running = false;
        _passed = passed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusText = _running
        ? 'Running runtime booking smoke check...'
        : _passed
            ? 'PASS'
            : 'FAIL';
    final statusColor = _running
        ? Colors.orange.shade700
        : _passed
            ? Colors.green.shade700
            : Colors.red.shade700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Runtime Booking Smoke'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              statusText,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _log.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
