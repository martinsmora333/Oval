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

    final result = await client.rpc(
      'queue_booking_invitation',
      params: <String, dynamic>{
        'target_booking_id': invitation.bookingId,
        'target_invitee_user_id': invitation.inviteeId,
        'invitation_message': invitation.message,
        'invitation_response_window_minutes': responseWindowMinutes,
      },
    );

    final row = singleRpcRow(result);
    return row['invitation_id'] as String;
  }

  Future<void> updateInvitation(InvitationModel invitation) async {
    throw UnsupportedError(
      'Direct invitation edits are not supported. Queue a new invitation or cancel the existing one.',
    );
  }

  Future<void> updateInvitationStatus(
    String invitationId,
    InvitationStatus status,
    DateTime respondedAt,
  ) async {
    switch (status) {
      case InvitationStatus.accepted:
      case InvitationStatus.declined:
        await client.rpc(
          'respond_to_booking_invitation',
          params: <String, dynamic>{
            'target_invitation_id': invitationId,
            'new_status': status.dbValue,
          },
        );
        return;
      case InvitationStatus.cancelled:
        await deleteInvitation(invitationId);
        return;
      case InvitationStatus.queued:
      case InvitationStatus.pending:
      case InvitationStatus.expired:
      case InvitationStatus.skipped:
        throw UnsupportedError(
          'Invitation status $status must be managed by the booking workflow.',
        );
    }
  }

  Future<void> deleteInvitation(String invitationId) async {
    await client.rpc(
      'cancel_booking_invitation',
      params: <String, dynamic>{'target_invitation_id': invitationId},
    );
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
