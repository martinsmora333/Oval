import 'package:flutter/foundation.dart';
import '../models/app_auth_user.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  AppAuthUser? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  AppAuthUser? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;
  
  // Constructor - listen to auth state changes
  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }
  
  // Handle auth state changes
  Future<void> _onAuthStateChanged(AppAuthUser? user) async {
    _user = user;
    
    if (user != null) {
      _isLoading = true;
      notifyListeners();
      
      try {
        _userModel = await _authService.getUserData(user.uid);
        _error = null;
      } catch (e) {
        _error = 'Failed to load user data';
        debugPrint('Error loading user data: $e');
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    } else {
      _userModel = null;
      notifyListeners();
    }
  }
  
  // Sign in with email and password
  Future<bool> signIn(String email, String password, {required UserType userType}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authService.signInWithEmailAndPassword(email, password, userType: userType);
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Sign in error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Register with email and password
  Future<bool> register(String email, String password, String displayName, PlayerLevel playerLevel, UserType userType) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authService.registerWithEmailAndPassword(
        email, 
        password, 
        displayName, 
        playerLevel,
        userType
      );
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Registration error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _authService.signOut();
    } catch (e) {
      _error = 'Failed to sign out';
      debugPrint('Sign out error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Refresh user data from Supabase
  Future<void> refreshUserData() async {
    if (_user == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      _userModel = await _authService.getUserData(_user!.uid);
      _error = null;
    } catch (e) {
      _error = 'Failed to refresh user data';
      debugPrint('Error refreshing user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Password reset error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update user's onboarding status
  Future<bool> updateUserOnboardingStatus({required bool completed}) async {
    if (_user == null) return false;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authService.updateOnboardingStatus(_user!.uid, completed);
      _userModel = await _authService.getUserData(_user!.uid);
      
      return true;
    } catch (e) {
      _error = 'Failed to update onboarding status';
      debugPrint('Update onboarding status error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update user profile
  Future<bool> updateProfile({
    String? displayName,
    String? photoURL,
    PlayerLevel? playerLevel,
  }) async {
    if (_user == null || _userModel == null) return false;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authService.updateProfile(
        _user!.uid,
        displayName: displayName,
        photoURL: photoURL,
        playerLevel: playerLevel,
      );
      
      // Refresh user data
      _userModel = await _authService.getUserData(_user!.uid);
      return true;
    } catch (e) {
      _error = 'Failed to update profile';
      debugPrint('Profile update error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
