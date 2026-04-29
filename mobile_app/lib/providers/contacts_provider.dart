import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../repositories/profiles_repository.dart';

class ContactsProvider with ChangeNotifier {
  final ProfilesRepository _profilesRepository = ProfilesRepository();

  List<UserModel> _contacts = [];
  bool _isLoading = false;
  String? _error;

  List<UserModel> get contacts => _contacts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadContacts(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _contacts = await _profilesRepository.getUserContacts(userId);
    } catch (e) {
      _error = 'Failed to load contacts';
      debugPrint('Error loading contacts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addContact(String userId, String contactId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _profilesRepository.addUserContact(userId, contactId);
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

  Future<bool> removeContact(String userId, String contactId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _profilesRepository.removeUserContact(userId, contactId);
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

  Future<List<UserModel>> searchUsers(
      String query, String currentUserId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final users = await _profilesRepository.searchUsers(query);
      final filteredUsers = users
          .where(
            (user) =>
                user.id != currentUserId &&
                !_contacts.any((contact) => contact.id == user.id),
          )
          .toList();
      return filteredUsers;
    } catch (e) {
      _error = 'Failed to search users';
      debugPrint('Error searching users: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isContact(String contactId) {
    return _contacts.any((contact) => contact.id == contactId);
  }

  UserModel? getContactById(String contactId) {
    try {
      return _contacts.firstWhere((contact) => contact.id == contactId);
    } catch (_) {
      return null;
    }
  }

  List<UserModel> filterContactsByLevel(PlayerLevel level) {
    return _contacts.where((contact) => contact.playerLevel == level).toList();
  }
}
