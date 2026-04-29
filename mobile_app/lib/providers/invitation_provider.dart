import 'package:flutter/foundation.dart';

import '../models/invitation_model.dart';
import '../repositories/invitations_repository.dart';

class InvitationProvider with ChangeNotifier {
  final InvitationsRepository _invitationsRepository = InvitationsRepository();

  List<InvitationModel> _sentInvitations = [];
  List<InvitationModel> _receivedInvitations = [];
  bool _isLoading = false;
  String? _error;

  List<InvitationModel> get sentInvitations => _sentInvitations;
  List<InvitationModel> get receivedInvitations => _receivedInvitations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSentInvitations(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sentInvitations =
          await _invitationsRepository.getSentInvitations(userId);
    } catch (e) {
      _error = 'Failed to load sent invitations';
      debugPrint('Error loading sent invitations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadReceivedInvitations(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _receivedInvitations =
          await _invitationsRepository.getReceivedInvitations(userId);
    } catch (e) {
      _error = 'Failed to load received invitations';
      debugPrint('Error loading received invitations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createInvitation(InvitationModel invitation) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _invitationsRepository.createInvitation(invitation);
      await loadSentInvitations(invitation.creatorId);
      return true;
    } catch (e) {
      _error = 'Failed to create invitation';
      debugPrint('Error creating invitation: $e');
      throw Exception('Failed to create invitation: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> acceptInvitation(String invitationId, String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _invitationsRepository.updateInvitationStatus(
        invitationId,
        InvitationStatus.accepted,
        DateTime.now(),
      );
      await loadReceivedInvitations(userId);
      return true;
    } catch (e) {
      _error = 'Failed to accept invitation';
      debugPrint('Error accepting invitation: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> declineInvitation(String invitationId, String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _invitationsRepository.updateInvitationStatus(
        invitationId,
        InvitationStatus.declined,
        DateTime.now(),
      );
      await loadReceivedInvitations(userId);
      return true;
    } catch (e) {
      _error = 'Failed to decline invitation';
      debugPrint('Error declining invitation: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelInvitation(String invitationId, String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _invitationsRepository.deleteInvitation(invitationId);
      await loadSentInvitations(userId);
      return true;
    } catch (e) {
      _error = 'Failed to cancel invitation';
      debugPrint('Error cancelling invitation: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<InvitationModel?> getInvitationById(String invitationId) async {
    try {
      return await _invitationsRepository.getInvitation(invitationId);
    } catch (e) {
      _error = 'Failed to get invitation details';
      debugPrint('Error getting invitation: $e');
      return null;
    }
  }

  List<InvitationModel> getSentInvitationsByStatus(InvitationStatus status) {
    return _sentInvitations
        .where((invitation) => invitation.status == status)
        .toList();
  }

  List<InvitationModel> getReceivedInvitationsByStatus(
      InvitationStatus status) {
    return _receivedInvitations
        .where((invitation) => invitation.status == status)
        .toList();
  }

  List<InvitationModel> getPendingReceivedInvitations() {
    final now = DateTime.now();
    return _receivedInvitations
        .where((invitation) =>
            invitation.status == InvitationStatus.pending &&
            !invitation.isExpired(now))
        .toList();
  }
}
