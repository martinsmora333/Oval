import 'model_serialization.dart';

enum InvitationStatus {
  queued('queued', 'Queued'),
  pending('pending', 'Pending'),
  accepted('accepted', 'Accepted'),
  declined('declined', 'Declined'),
  expired('expired', 'Expired'),
  cancelled('cancelled', 'Cancelled'),
  skipped('skipped', 'Skipped');

  const InvitationStatus(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static InvitationStatus fromDb(String? value) {
    switch (value) {
      case 'queued':
        return InvitationStatus.queued;
      case 'accepted':
        return InvitationStatus.accepted;
      case 'declined':
        return InvitationStatus.declined;
      case 'expired':
        return InvitationStatus.expired;
      case 'cancelled':
        return InvitationStatus.cancelled;
      case 'skipped':
        return InvitationStatus.skipped;
      case 'pending':
      default:
        return InvitationStatus.pending;
    }
  }
}

class InvitationModel {
  final String id;
  final String bookingId;
  final String creatorId;
  final String inviteeId;
  final String? inviteeName;
  final String? creatorName;
  final InvitationStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? respondedAt;
  final int priority;
  final String? message;

  InvitationModel({
    required this.id,
    required this.bookingId,
    required this.creatorId,
    required this.inviteeId,
    this.inviteeName,
    this.creatorName,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.respondedAt,
    required this.priority,
    this.message,
  });

  factory InvitationModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return InvitationModel(
      id: id ?? data['id'] as String? ?? '',
      bookingId:
          data['bookingId'] as String? ?? data['booking_id'] as String? ?? '',
      creatorId: data['creatorId'] as String? ??
          data['creator_user_id'] as String? ??
          '',
      inviteeId: data['inviteeId'] as String? ??
          data['invitee_user_id'] as String? ??
          '',
      inviteeName:
          data['inviteeName'] as String? ?? data['invitee_name'] as String?,
      creatorName:
          data['creatorName'] as String? ?? data['creator_name'] as String?,
      status: InvitationStatus.fromDb(data['status']?.toString()),
      createdAt: parseDateTime(data['createdAt'] ?? data['created_at']),
      expiresAt: parseDateTime(data['expiresAt'] ?? data['expires_at']),
      respondedAt: data['respondedAt'] == null && data['responded_at'] == null
          ? null
          : parseDateTime(data['respondedAt'] ?? data['responded_at']),
      priority: data['priority'] as int? ?? 0,
      message: data['message'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'creatorId': creatorId,
      'inviteeId': inviteeId,
      'inviteeName': inviteeName,
      'creatorName': creatorName,
      'status': status.dbValue,
      'createdAt': serializeDateTime(createdAt),
      'expiresAt': serializeDateTime(expiresAt),
      'respondedAt': serializeDateTime(respondedAt),
      'priority': priority,
      'message': message,
    };
  }

  String get statusString => status.label;

  bool isExpired(DateTime currentTime) => currentTime.isAfter(expiresAt);

  Duration timeRemaining(DateTime currentTime) {
    if (currentTime.isAfter(expiresAt)) {
      return Duration.zero;
    }

    return expiresAt.difference(currentTime);
  }

  String formattedTimeRemaining(DateTime currentTime) {
    final remaining = timeRemaining(currentTime);

    if (remaining == Duration.zero) {
      return 'Expired';
    }

    if (remaining.inDays > 0) {
      return '${remaining.inDays}d ${remaining.inHours % 24}h remaining';
    }
    if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m remaining';
    }
    return '${remaining.inMinutes}m remaining';
  }

  InvitationModel copyWith({
    String? id,
    String? bookingId,
    String? creatorId,
    String? inviteeId,
    String? inviteeName,
    String? creatorName,
    InvitationStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? respondedAt,
    int? priority,
    String? message,
  }) {
    return InvitationModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      creatorId: creatorId ?? this.creatorId,
      inviteeId: inviteeId ?? this.inviteeId,
      inviteeName: inviteeName ?? this.inviteeName,
      creatorName: creatorName ?? this.creatorName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      respondedAt: respondedAt ?? this.respondedAt,
      priority: priority ?? this.priority,
      message: message ?? this.message,
    );
  }
}
