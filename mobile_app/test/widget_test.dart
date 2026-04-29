import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app/models/booking_model.dart';

void main() {
  test('BookingModel formats booking details consistently', () {
    final booking = BookingModel(
      id: 'booking-1',
      courtId: 'court-1',
      courtName: 'Centre Court',
      tennisCenter: 'center-1',
      tennisCenterName: 'Oval Tennis Centre',
      startsAt: DateTime(2026, 5, 3, 18, 30),
      endsAt: DateTime(2026, 5, 3, 20, 0),
      creatorId: 'user-1',
      creatorName: 'Alex',
      inviteeId: 'user-2',
      inviteeName: 'Jamie',
      status: BookingStatus.confirmed,
      paymentStatus: PaymentStatus.partial,
      totalAmount: 48,
      amountPerPlayer: 24,
      createdAt: DateTime.utc(2026, 4, 21),
      confirmedAt: DateTime.utc(2026, 4, 21, 1),
    );

    expect(booking.formattedDateTime, 'May 3, 2026 • 18:30 - 20:00');
    expect(booking.statusString, 'Confirmed');
    expect(booking.paymentStatusString, 'Partially Paid');
    expect(booking.formattedTotalAmount, '\$48.00');
    expect(booking.formattedAmountPerPlayer, '\$24.00');
    expect(booking.isUpcoming(DateTime(2026, 5, 3, 17, 0)), isTrue);
    expect(booking.isInProgress(DateTime(2026, 5, 3, 19, 0)), isTrue);
  });
}
