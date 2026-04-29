import 'model_serialization.dart';

enum InvitationStatus { pending, accepted, declined, expired }

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
      bookingId: data['bookingId'] as String? ?? '',
      creatorId: data['creatorId'] as String? ?? '',
      inviteeId: data['inviteeId'] as String? ?? '',
      inviteeName: data['inviteeName'] as String?,
      creatorName: data['creatorName'] as String?,
      status: _getInvitationStatusFromString(data['status'] ?? 'pending'),
      createdAt: parseDateTime(data['createdAt']),
      expiresAt: parseDateTime(data['expiresAt']),
      respondedAt: data['respondedAt'] == null
          ? null
          : parseDateTime(data['respondedAt']),
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
      'status': status.name,
      'createdAt': serializeDateTime(createdAt),
      'expiresAt': serializeDateTime(expiresAt),
      'respondedAt': serializeDateTime(respondedAt),
      'priority': priority,
      'message': message,
    };
  }

  static InvitationStatus _getInvitationStatusFromString(dynamic status) {
    switch (status.toString().toLowerCase()) {
      case 'pending':
        return InvitationStatus.pending;
      case 'accepted':
        return InvitationStatus.accepted;
      case 'declined':
        return InvitationStatus.declined;
      case 'expired':
        return InvitationStatus.expired;
      default:
        return InvitationStatus.pending;
    }
  }

  String get statusString {
    switch (status) {
      case InvitationStatus.pending:
        return 'Pending';
      case InvitationStatus.accepted:
        return 'Accepted';
      case InvitationStatus.declined:
        return 'Declined';
      case InvitationStatus.expired:
        return 'Expired';
    }
  }

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
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m remaining';
    } else {
      return '${remaining.inMinutes}m remaining';
    }
  }

  InvitationModel copyWith({
    String? id,
    String? bookingId,
    String? creatorId,
    String? inviteeId,
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
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      respondedAt: respondedAt ?? this.respondedAt,
      priority: priority ?? this.priority,
      message: message ?? this.message,
    );
  }
}
