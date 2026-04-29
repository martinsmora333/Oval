import 'package:flutter/foundation.dart';
import '../models/invitation_model.dart';
import '../services/data_service.dart';

class InvitationProvider with ChangeNotifier {
  final DataService _dataService = DataService();
  
  List<InvitationModel> _sentInvitations = [];
  List<InvitationModel> _receivedInvitations = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<InvitationModel> get sentInvitations => _sentInvitations;
  List<InvitationModel> get receivedInvitations => _receivedInvitations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Load sent invitations
  Future<void> loadSentInvitations(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _sentInvitations = await _dataService.getSentInvitations(userId);
    } catch (e) {
      _error = 'Failed to load sent invitations';
      debugPrint('Error loading sent invitations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load received invitations
  Future<void> loadReceivedInvitations(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _receivedInvitations = await _dataService.getReceivedInvitations(userId);
    } catch (e) {
      _error = 'Failed to load received invitations';
      debugPrint('Error loading received invitations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Create a new invitation
  Future<bool> createInvitation(InvitationModel invitation) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _dataService.createInvitation(invitation);
      
      // Refresh sent invitations
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
  
  // Accept an invitation
  Future<bool> acceptInvitation(String invitationId, String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Accept the invitation in the backend
      await _dataService.updateInvitationStatus(
        invitationId, 
        InvitationStatus.accepted,
        DateTime.now()
      );
      
      // Refresh received invitations
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
  
  // Decline an invitation
  Future<bool> declineInvitation(String invitationId, String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Decline the invitation in the backend
      await _dataService.updateInvitationStatus(
        invitationId, 
        InvitationStatus.declined,
        DateTime.now()
      );
      
      // Refresh received invitations
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
  
  // Cancel an invitation
  Future<bool> cancelInvitation(String invitationId, String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Delete the invitation in the backend
      await _dataService.deleteInvitation(invitationId);
      
      // Refresh sent invitations
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
  
  // Get invitation by ID
  Future<InvitationModel?> getInvitationById(String invitationId) async {
    try {
      return await _dataService.getInvitation(invitationId);
    } catch (e) {
      _error = 'Failed to get invitation details';
      debugPrint('Error getting invitation: $e');
      return null;
    }
  }
  
  // Filter invitations by status
  List<InvitationModel> getSentInvitationsByStatus(InvitationStatus status) {
    return _sentInvitations.where((invitation) => invitation.status == status).toList();
  }
  
  List<InvitationModel> getReceivedInvitationsByStatus(InvitationStatus status) {
    return _receivedInvitations.where((invitation) => invitation.status == status).toList();
  }
  
  // Get pending invitations
  List<InvitationModel> getPendingReceivedInvitations() {
    final now = DateTime.now();
    return _receivedInvitations.where((invitation) => 
      invitation.status == InvitationStatus.pending && !invitation.isExpired(now)
    ).toList();
  }
}
