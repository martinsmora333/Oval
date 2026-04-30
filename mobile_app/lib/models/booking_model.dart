import 'package:intl/intl.dart';

import 'model_serialization.dart';

enum BookingStatus {
  draft('draft', 'Draft'),
  pending('pending', 'Pending'),
  confirmed('confirmed', 'Confirmed'),
  cancelled('cancelled', 'Cancelled'),
  completed('completed', 'Completed'),
  noShow('no_show', 'No Show');

  const BookingStatus(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static BookingStatus fromDb(String? value) {
    switch (value) {
      case 'draft':
        return BookingStatus.draft;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'completed':
        return BookingStatus.completed;
      case 'no_show':
        return BookingStatus.noShow;
      case 'pending':
      default:
        return BookingStatus.pending;
    }
  }
}

enum PaymentStatus {
  pending('pending', 'Payment Pending'),
  partial('partial', 'Partially Paid'),
  complete('complete', 'Paid'),
  refunded('refunded', 'Refunded'),
  failed('failed', 'Payment Failed');

  const PaymentStatus(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static PaymentStatus fromDb(String? value) {
    switch (value) {
      case 'partial':
        return PaymentStatus.partial;
      case 'complete':
        return PaymentStatus.complete;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'failed':
        return PaymentStatus.failed;
      case 'pending':
      default:
        return PaymentStatus.pending;
    }
  }
}

class BookingModel {
  final String id;
  final String courtId;
  final String? courtName;
  final String tennisCenter;
  final String? tennisCenterName;
  final String? tennisCenterAddress;
  final DateTime startsAt;
  final DateTime endsAt;
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
    this.tennisCenterAddress,
    required this.startsAt,
    required this.endsAt,
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

  String get date => DateFormat('yyyy-MM-dd').format(startsAt);
  String get startTime => DateFormat('HH:mm').format(startsAt);
  String get endTime => DateFormat('HH:mm').format(endsAt);

  factory BookingModel.fromMap(Map<String, dynamic> data, {String? id}) {
    final startsAt = _parseStartsAt(data);
    final endsAt = _parseEndsAt(data, startsAt);

    return BookingModel(
      id: id ?? data['id'] as String? ?? '',
      courtId: data['courtId'] as String? ?? data['court_id'] as String? ?? '',
      courtName: data['courtName'] as String? ?? data['court_name'] as String?,
      tennisCenter:
          data['tennisCenter'] as String? ?? data['center_id'] as String? ?? '',
      tennisCenterName: data['tennisCenterName'] as String? ??
          data['tennis_center_name'] as String?,
      tennisCenterAddress: data['tennisCenterAddress'] as String? ??
          data['tennis_center_address'] as String?,
      startsAt: startsAt,
      endsAt: endsAt,
      creatorId:
          data['creatorId'] as String? ?? data['created_by'] as String? ?? '',
      creatorName:
          data['creatorName'] as String? ?? data['creator_name'] as String?,
      inviteeId:
          data['inviteeId'] as String? ?? data['opponent_user_id'] as String?,
      inviteeName:
          data['inviteeName'] as String? ?? data['invitee_name'] as String?,
      status: BookingStatus.fromDb(
        data['status']?.toString() ?? data['bookingStatus']?.toString(),
      ),
      paymentStatus: PaymentStatus.fromDb(
        data['paymentStatus']?.toString() ?? data['payment_status']?.toString(),
      ),
      creatorPaymentId: data['creatorPaymentId'] as String? ??
          data['creator_payment_id'] as String?,
      inviteePaymentId: data['inviteePaymentId'] as String? ??
          data['invitee_payment_id'] as String?,
      totalAmount: readDouble(data['totalAmount'] ?? data['total_amount']),
      amountPerPlayer:
          readDouble(data['amountPerPlayer'] ?? data['amount_per_player']),
      price: data['price'] == null ? null : readDouble(data['price']),
      createdAt: parseDateTime(data['createdAt'] ?? data['created_at']),
      confirmedAt: data['confirmedAt'] == null && data['confirmed_at'] == null
          ? null
          : parseDateTime(data['confirmedAt'] ?? data['confirmed_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courtId': courtId,
      'courtName': courtName,
      'tennisCenter': tennisCenter,
      'tennisCenterName': tennisCenterName,
      'tennisCenterAddress': tennisCenterAddress,
      'startsAt': serializeDateTime(startsAt),
      'endsAt': serializeDateTime(endsAt),
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'inviteeId': inviteeId,
      'inviteeName': inviteeName,
      'status': status.dbValue,
      'paymentStatus': paymentStatus.dbValue,
      'creatorPaymentId': creatorPaymentId,
      'inviteePaymentId': inviteePaymentId,
      'totalAmount': totalAmount,
      'amountPerPlayer': amountPerPlayer,
      'price': price,
      'createdAt': serializeDateTime(createdAt),
      'confirmedAt': serializeDateTime(confirmedAt),
    };
  }

  static DateTime combineDateAndTime(DateTime date, String time) {
    final formats = <String>['HH:mm', 'H:mm', 'h:mm a', 'hh:mm a'];

    for (final pattern in formats) {
      try {
        final parsedTime = DateFormat(pattern).parse(time);
        return DateTime(
          date.year,
          date.month,
          date.day,
          parsedTime.hour,
          parsedTime.minute,
        );
      } catch (_) {
        // Try the next format.
      }
    }

    throw FormatException('Unsupported time format: $time');
  }

  static DateTime _parseStartsAt(Map<String, dynamic> data) {
    final directValue = data['startsAt'] ?? data['starts_at'];
    if (directValue != null) {
      return parseDateTime(directValue);
    }

    final date = data['date'] as String? ?? '';
    final time =
        data['startTime'] as String? ?? data['start_time'] as String? ?? '';
    if (date.isNotEmpty && time.isNotEmpty) {
      return _combineDateStringAndTime(date, time);
    }

    return parseDateTime(data['createdAt'] ?? data['created_at']);
  }

  static DateTime _parseEndsAt(Map<String, dynamic> data, DateTime startsAt) {
    final directValue = data['endsAt'] ?? data['ends_at'];
    if (directValue != null) {
      return parseDateTime(directValue);
    }

    final date = data['date'] as String? ?? '';
    final time =
        data['endTime'] as String? ?? data['end_time'] as String? ?? '';
    if (date.isNotEmpty && time.isNotEmpty) {
      return _combineDateStringAndTime(date, time);
    }

    return startsAt.add(const Duration(hours: 1));
  }

  static DateTime _combineDateStringAndTime(String date, String time) {
    final parsedDate = DateFormat('yyyy-MM-dd').parse(date);
    return combineDateAndTime(parsedDate, time);
  }

  String get formattedDateTime {
    return '${DateFormat('MMMM d, y').format(startsAt)} • $startTime - $endTime';
  }

  String get statusString => status.label;

  String get paymentStatusString => paymentStatus.label;

  String get formattedTotalAmount => '\$${totalAmount.toStringAsFixed(2)}';

  String get formattedAmountPerPlayer =>
      '\$${amountPerPlayer.toStringAsFixed(2)}';

  bool isUpcoming(DateTime currentDate) => startsAt.isAfter(currentDate);

  bool isInProgress(DateTime currentDate) {
    return currentDate.isAfter(startsAt) && currentDate.isBefore(endsAt);
  }

  BookingModel copyWith({
    String? id,
    String? courtId,
    String? courtName,
    String? tennisCenter,
    String? tennisCenterName,
    DateTime? startsAt,
    DateTime? endsAt,
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
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
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

  bool get canCancel =>
      status == BookingStatus.pending || status == BookingStatus.confirmed;
}
