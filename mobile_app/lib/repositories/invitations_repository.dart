import '../models/booking_model.dart';
import '../models/invitation_model.dart';
import '../models/user_model.dart';
import 'profiles_repository.dart';
import 'repository_support.dart';

class InvitationsRepository extends RepositorySupport {
  InvitationsRepository._internal();

  static final InvitationsRepository _instance =
      InvitationsRepository._internal();

  factory InvitationsRepository() => _instance;

  final ProfilesRepository _profilesRepository = ProfilesRepository();

  Future<String> createInvitation(InvitationModel invitation) async {
    final responseWindowMinutes = invitation.expiresAt
        .difference(invitation.createdAt)
        .inMinutes
        .clamp(5, 10080);

    final created = await client
        .from('booking_invitations')
        .insert(
          <String, dynamic>{
            'booking_id': invitation.bookingId,
            'creator_user_id': invitation.creatorId,
            'invitee_user_id': invitation.inviteeId,
            'priority': invitation.priority,
            'status': invitation.status.dbValue,
            'message': invitation.message,
            'expires_at': invitation.expiresAt.toIso8601String(),
            'response_window_minutes': responseWindowMinutes,
          },
        )
        .select()
        .single();

    return created['id'] as String;
  }

  Future<void> updateInvitation(InvitationModel invitation) async {
    await client.from('booking_invitations').update(
      <String, dynamic>{
        'message': invitation.message,
        'priority': invitation.priority,
        'status': invitation.status.dbValue,
        'expires_at': invitation.expiresAt.toIso8601String(),
      },
    ).eq('id', invitation.id);
  }

  Future<void> updateInvitationStatus(
    String invitationId,
    InvitationStatus status,
    DateTime respondedAt,
  ) async {
    final invitation = await client
        .from('booking_invitations')
        .select('id,booking_id,invitee_user_id')
        .eq('id', invitationId)
        .maybeSingle();

    if (invitation == null) {
      return;
    }

    final booking = await client
        .from('bookings')
        .select('id,status,opponent_user_id')
        .eq('id', invitation['booking_id'] as String)
        .maybeSingle();

    final bookingStatus = booking == null ? null : booking['status'] as String?;

    if ((status == InvitationStatus.accepted ||
            status == InvitationStatus.declined) &&
        bookingStatus == BookingStatus.pending.dbValue) {
      await client.rpc(
        'respond_to_booking_invitation',
        params: <String, dynamic>{
          'target_invitation_id': invitationId,
          'new_status': status.dbValue,
        },
      );
      return;
    }

    await client.from('booking_invitations').update(
      <String, dynamic>{
        'status': status.dbValue,
        'responded_at': respondedAt.toIso8601String(),
      },
    ).eq('id', invitationId);

    if (status == InvitationStatus.accepted && booking != null) {
      await client.from('bookings').update(
        <String, dynamic>{
          'opponent_user_id': invitation['invitee_user_id'],
        },
      ).eq('id', booking['id'] as String);
    }
  }

  Future<void> deleteInvitation(String invitationId) async {
    await client.from('booking_invitations').delete().eq('id', invitationId);
  }

  Future<InvitationModel?> getInvitation(String invitationId) async {
    final row = await client
        .from('booking_invitations')
        .select()
        .eq('id', invitationId)
        .maybeSingle();

    if (row == null) {
      return null;
    }

    final invitations = await _mapInvitationRows(
      <Map<String, dynamic>>[Map<String, dynamic>.from(row)],
    );
    return invitations.first;
  }

  Future<List<InvitationModel>> getSentInvitations(String userId) async {
    final rows = await client
        .from('booking_invitations')
        .select()
        .eq('creator_user_id', userId)
        .order('created_at', ascending: false);

    return _mapInvitationRows(
      (rows as List)
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false),
    );
  }

  Future<List<InvitationModel>> getReceivedInvitations(String userId) async {
    final rows = await client
        .from('booking_invitations')
        .select()
        .eq('invitee_user_id', userId)
        .order('created_at', ascending: false);

    return _mapInvitationRows(
      (rows as List)
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false),
    );
  }

  Future<List<InvitationModel>> _mapInvitationRows(
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) {
      return const <InvitationModel>[];
    }

    final userIds = rows
        .expand<String>(
          (row) => <String?>[
            row['creator_user_id'] as String?,
            row['invitee_user_id'] as String?,
          ].whereType<String>(),
        )
        .toSet()
        .toList(growable: false);

    final users = await _profilesRepository.getUsersByIds(userIds);
    final userNames = <String, String>{
      for (final UserModel user in users) user.id: user.displayName,
    };

    return rows.map((row) {
      final creatorId = row['creator_user_id'] as String? ?? '';
      final inviteeId = row['invitee_user_id'] as String? ?? '';
      return InvitationModel(
        id: row['id'] as String,
        bookingId: row['booking_id'] as String? ?? '',
        creatorId: creatorId,
        inviteeId: inviteeId,
        inviteeName: userNames[inviteeId],
        creatorName: userNames[creatorId],
        status: InvitationStatus.fromDb(row['status'] as String?),
        createdAt: parseDbDateTime(row['created_at']),
        expiresAt: row['expires_at'] == null
            ? DateTime.now().add(const Duration(days: 1))
            : parseDbDateTime(row['expires_at']),
        respondedAt: row['responded_at'] == null
            ? null
            : parseDbDateTime(row['responded_at']),
        priority: row['priority'] as int? ?? 1,
        message: row['message'] as String?,
      );
    }).toList(growable: false);
  }
}
