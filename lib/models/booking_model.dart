import 'model_serialization.dart';

enum BookingStatus { pending, confirmed, cancelled }
enum PaymentStatus { pending, partial, complete, refunded }

class BookingModel {
  final String id;
  final String courtId;
  final String? courtName;
  final String tennisCenter;
  final String? tennisCenterName;
  final String date;
  final String startTime;
  final String endTime;
  final String creatorId;
  final String? creatorName;
  final String? inviteeId;
  final String? inviteeName;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final String? creatorPaymentId;
  final String? inviteePaymentId;
  final double totalAmount;
  final double amountPerPlayer;
  final double? price;
  final DateTime createdAt;
  final DateTime? confirmedAt;

  BookingModel({
    required this.id,
    required this.courtId,
    this.courtName,
    required this.tennisCenter,
    this.tennisCenterName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.creatorId,
    this.creatorName,
    this.inviteeId,
    this.inviteeName,
    required this.status,
    required this.paymentStatus,
    this.creatorPaymentId,
    this.inviteePaymentId,
    required this.totalAmount,
    required this.amountPerPlayer,
    this.price,
    required this.createdAt,
    this.confirmedAt,
  });

  factory BookingModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return BookingModel(
      id: id ?? data['id'] as String? ?? '',
      courtId: data['courtId'] as String? ?? '',
      courtName: data['courtName'] as String?,
      tennisCenter: data['tennisCenter'] as String? ?? '',
      tennisCenterName: data['tennisCenterName'] as String?,
      date: data['date'] as String? ?? '',
      startTime: data['startTime'] as String? ?? '',
      endTime: data['endTime'] as String? ?? '',
      creatorId: data['creatorId'] as String? ?? '',
      creatorName: data['creatorName'] as String?,
      inviteeId: data['inviteeId'] as String?,
      inviteeName: data['inviteeName'] as String?,
      status: _getBookingStatusFromString(data['status'] ?? 'pending'),
      paymentStatus: _getPaymentStatusFromString(
        data['paymentStatus'] ?? 'pending',
      ),
      creatorPaymentId: data['creatorPaymentId'] as String?,
      inviteePaymentId: data['inviteePaymentId'] as String?,
      totalAmount: readDouble(data['totalAmount']),
      amountPerPlayer: readDouble(data['amountPerPlayer']),
      price: data['price'] == null ? null : readDouble(data['price']),
      createdAt: parseDateTime(data['createdAt']),
      confirmedAt: data['confirmedAt'] == null
          ? null
          : parseDateTime(data['confirmedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courtId': courtId,
      'courtName': courtName,
      'tennisCenter': tennisCenter,
      'tennisCenterName': tennisCenterName,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'inviteeId': inviteeId,
      'inviteeName': inviteeName,
      'status': status.name,
      'paymentStatus': paymentStatus.name,
      'creatorPaymentId': creatorPaymentId,
      'inviteePaymentId': inviteePaymentId,
      'totalAmount': totalAmount,
      'amountPerPlayer': amountPerPlayer,
      'price': price,
      'createdAt': serializeDateTime(createdAt),
      'confirmedAt': serializeDateTime(confirmedAt),
    };
  }

  static BookingStatus _getBookingStatusFromString(dynamic status) {
    switch (status.toString().toLowerCase()) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }

  static PaymentStatus _getPaymentStatusFromString(dynamic status) {
    switch (status.toString().toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'partial':
        return PaymentStatus.partial;
      case 'complete':
        return PaymentStatus.complete;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }

  String get formattedDateTime {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    final parts = date.split('-');
    if (parts.length != 3) return '$date $startTime - $endTime';

    final year = parts[0];
    final month = int.tryParse(parts[1]) ?? 1;
    final day = int.tryParse(parts[2]) ?? 1;

    return '${months[month - 1]} $day, $year • $startTime - $endTime';
  }

  String get statusString {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get paymentStatusString {
    switch (paymentStatus) {
      case PaymentStatus.pending:
        return 'Payment Pending';
      case PaymentStatus.partial:
        return 'Partially Paid';
      case PaymentStatus.complete:
        return 'Paid';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  String get formattedTotalAmount => '\$${totalAmount.toStringAsFixed(2)}';

  String get formattedAmountPerPlayer =>
      '\$${amountPerPlayer.toStringAsFixed(2)}';

  bool isUpcoming(DateTime currentDate) {
    final bookingDate = _parseBookingDate();
    return bookingDate.isAfter(currentDate);
  }

  bool isInProgress(DateTime currentDate) {
    final bookingDate = _parseBookingDate();
    final bookingEndDate = _parseBookingEndDate();

    return currentDate.isAfter(bookingDate) &&
        currentDate.isBefore(bookingEndDate);
  }

  DateTime _parseBookingDate() {
    final dateParts = date.split('-');
    final timeParts = startTime.split(':');

    return DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  DateTime _parseBookingEndDate() {
    final dateParts = date.split('-');
    final timeParts = endTime.split(':');

    return DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  BookingModel copyWith({
    String? id,
    String? courtId,
    String? courtName,
    String? tennisCenter,
    String? tennisCenterName,
    String? date,
    String? startTime,
    String? endTime,
    String? creatorId,
    String? creatorName,
    String? inviteeId,
    String? inviteeName,
    BookingStatus? status,
    PaymentStatus? paymentStatus,
    String? creatorPaymentId,
    String? inviteePaymentId,
    double? totalAmount,
    double? amountPerPlayer,
    double? price,
    DateTime? createdAt,
    DateTime? confirmedAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      courtId: courtId ?? this.courtId,
      courtName: courtName ?? this.courtName,
      tennisCenter: tennisCenter ?? this.tennisCenter,
      tennisCenterName: tennisCenterName ?? this.tennisCenterName,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      inviteeId: inviteeId ?? this.inviteeId,
      inviteeName: inviteeName ?? this.inviteeName,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      creatorPaymentId: creatorPaymentId ?? this.creatorPaymentId,
      inviteePaymentId: inviteePaymentId ?? this.inviteePaymentId,
      totalAmount: totalAmount ?? this.totalAmount,
      amountPerPlayer: amountPerPlayer ?? this.amountPerPlayer,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }

  String? get courtSurface => 'Clay';
  String get surfaceType => 'Clay';
  bool get canCancel => status == BookingStatus.confirmed;
}
