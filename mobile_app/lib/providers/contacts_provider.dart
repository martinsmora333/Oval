import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/data_service.dart';

class ContactsProvider with ChangeNotifier {
  final DataService _dataService = DataService();
  
  List<UserModel> _contacts = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<UserModel> get contacts => _contacts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Load user contacts
  Future<void> loadContacts(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _contacts = await _dataService.getUserContacts(userId);
    } catch (e) {
      _error = 'Failed to load contacts';
      debugPrint('Error loading contacts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Add a contact
  Future<bool> addContact(String userId, String contactId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Add contact in the backend
      await _dataService.addUserContact(userId, contactId);
      
      // Refresh contacts
      await loadContacts(userId);
      
      return true;
    } catch (e) {
      _error = 'Failed to add contact';
      debugPrint('Error adding contact: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Remove a contact
  Future<bool> removeContact(String userId, String contactId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Remove contact in the backend
      await _dataService.removeUserContact(userId, contactId);
      
      // Refresh contacts
      await loadContacts(userId);
      
      return true;
    } catch (e) {
      _error = 'Failed to remove contact';
      debugPrint('Error removing contact: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Search for users to add as contacts
  Future<List<UserModel>> searchUsers(String query, String currentUserId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final users = await _dataService.searchUsers(query);
      
      // Filter out current user and existing contacts
      final filteredUsers = users.where((user) => 
        user.id != currentUserId && 
        !_contacts.any((contact) => contact.id == user.id)
      ).toList();
      
      _isLoading = false;
      notifyListeners();
      
      return filteredUsers;
    } catch (e) {
      _error = 'Failed to search users';
      debugPrint('Error searching users: $e');
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }
  
  // Check if a user is in contacts
  bool isContact(String contactId) {
    return _contacts.any((contact) => contact.id == contactId);
  }
  
  // Get contact by ID
  UserModel? getContactById(String contactId) {
    try {
      return _contacts.firstWhere((contact) => contact.id == contactId);
    } catch (e) {
      return null;
    }
  }
  
  // Filter contacts by player level
  List<UserModel> filterContactsByLevel(PlayerLevel level) {
    return _contacts.where((contact) => contact.playerLevel == level).toList();
  }
}
