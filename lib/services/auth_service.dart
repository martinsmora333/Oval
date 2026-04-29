import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_auth_user.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';

class AuthService {
  AuthService._internal();

  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;

  SupabaseClient get _client => SupabaseService.client;

  Stream<AppAuthUser?> get authStateChanges =>
      _client.auth.onAuthStateChange.map(
        (state) => _mapAuthUser(state.session?.user),
      );

  AppAuthUser? get currentUser => _mapAuthUser(_client.auth.currentUser);

  Future<UserModel?> getUserData(String uid) async {
    await _ensureProfileRows(uid);

    final profile = await _fetchProfile(uid);
    final publicProfile = await _fetchPublicProfile(uid);
    final managedCenterIds = await _fetchManagedCenterIds(uid);

    if (profile == null || publicProfile == null) {
      final current = currentUser;
      if (current != null && current.uid == uid) {
        return UserModel.minimal(uid, current.email ?? 'user@example.com');
      }
      return null;
    }

    return _buildUserModel(
      profile: profile,
      publicProfile: publicProfile,
      managedCenterIds: managedCenterIds,
    );
  }

  Future<AppAuthUser?> signInWithEmailAndPassword(
    String email,
    String password, {
    required UserType userType,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Failed to sign in');
      }

      await _ensureProfileRows(
        user.id,
        email: user.email,
        displayName: _bestDisplayName(
          user.userMetadata,
          fallbackEmail: user.email,
        ),
      );

      final userData = await getUserData(user.id);
      if (userData == null) {
        throw Exception('Failed to load your profile');
      }

      if (userData.userType != userType) {
        await _client.auth.signOut();
        throw Exception(
          'Invalid account type. Please use the correct login option.',
        );
      }

      return _mapAuthUser(user);
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<AppAuthUser?> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
    PlayerLevel playerLevel,
    UserType userType,
  ) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Failed to create user account');
      }

      if (_client.auth.currentSession == null) {
        await _client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }

      await _ensureProfileRows(
        user.id,
        email: email,
        displayName: displayName,
        userType: userType,
        playerLevel: playerLevel,
      );

      return _mapAuthUser(_client.auth.currentUser ?? user);
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> updateProfile(
    String uid, {
    String? displayName,
    String? photoURL,
    PlayerLevel? playerLevel,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null || user.id != uid) {
      throw Exception('User not authenticated or ID mismatch');
    }

    await _ensureProfileRows(
      uid,
      email: user.email,
      displayName: displayName ??
          _bestDisplayName(user.userMetadata, fallbackEmail: user.email),
    );

    if (displayName != null && displayName.trim().isNotEmpty) {
      final updatedMetadata = Map<String, dynamic>.from(user.userMetadata ?? {});
      updatedMetadata['display_name'] = displayName.trim();
      await _client.auth.updateUser(
        UserAttributes(
          data: updatedMetadata,
        ),
      );
    }

    final updates = <String, dynamic>{};
    if (displayName != null && displayName.trim().isNotEmpty) {
      updates['display_name'] = displayName.trim();
    }
    if (photoURL != null && photoURL.trim().isNotEmpty) {
      updates['profile_image_path'] = photoURL.trim();
    }
    if (playerLevel != null) {
      updates['player_level'] = _playerLevelToDb(playerLevel);
    }

    if (updates.isNotEmpty) {
      await _client
          .from('public_profiles')
          .update(updates)
          .eq('user_id', uid);
    }
  }

  Future<void> updateUserProfile({
    String? displayName,
    String? phoneNumber,
    String? profileImageUrl,
    PlayerLevel? playerLevel,
    List<String>? preferredPlayTimes,
    List<String>? preferredLocations,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    await _ensureProfileRows(
      user.id,
      email: user.email,
      displayName: displayName ??
          _bestDisplayName(user.userMetadata, fallbackEmail: user.email),
      playerLevel: playerLevel,
    );

    if (displayName != null && displayName.trim().isNotEmpty) {
      final updatedMetadata = Map<String, dynamic>.from(user.userMetadata ?? {});
      updatedMetadata['display_name'] = displayName.trim();
      await _client.auth.updateUser(
        UserAttributes(
          data: updatedMetadata,
        ),
      );
    }

    final privateUpdates = <String, dynamic>{};
    if (phoneNumber != null) {
      privateUpdates['phone_number'] = phoneNumber.trim().isEmpty
          ? null
          : phoneNumber.trim();
    }
    if (preferredPlayTimes != null) {
      privateUpdates['preferred_play_times'] = preferredPlayTimes;
    }
    if (preferredLocations != null) {
      privateUpdates['preferred_locations'] = preferredLocations;
    }

    if (privateUpdates.isNotEmpty) {
      await _client
          .from('profiles')
          .update(privateUpdates)
          .eq('id', user.id);
    }

    final publicUpdates = <String, dynamic>{};
    if (displayName != null && displayName.trim().isNotEmpty) {
      publicUpdates['display_name'] = displayName.trim();
    }
    if (profileImageUrl != null && profileImageUrl.trim().isNotEmpty) {
      publicUpdates['profile_image_path'] = profileImageUrl.trim();
    }
    if (playerLevel != null) {
      publicUpdates['player_level'] = _playerLevelToDb(playerLevel);
    }

    if (publicUpdates.isNotEmpty) {
      await _client
          .from('public_profiles')
          .update(publicUpdates)
          .eq('user_id', user.id);
    }
  }

  Future<void> updateOnboardingStatus(String uid, bool completed) async {
    await _client
        .from('profiles')
        .update({'onboarding_completed': completed})
        .eq('id', uid);
  }

  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> saveStripeCustomerId(String customerId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    await _client
        .from('profiles')
        .update({'stripe_customer_id': customerId})
        .eq('id', user.id);
  }

  Future<void> addPaymentMethod(String paymentMethodId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    await _client.from('user_saved_payment_methods').upsert(
      {
        'user_id': user.id,
        'provider': 'stripe',
        'provider_payment_method_id': paymentMethodId,
        'is_default': true,
      },
      onConflict: 'user_id,provider,provider_payment_method_id',
    );
  }

  Future<void> _ensureProfileRows(
    String uid, {
    String? email,
    String? displayName,
    UserType? userType,
    PlayerLevel? playerLevel,
  }) async {
    final user = _client.auth.currentUser;
    final effectiveEmail = email ?? user?.email;
    final effectiveDisplayName = displayName ??
        _bestDisplayName(user?.userMetadata, fallbackEmail: effectiveEmail);

    if (effectiveEmail == null || effectiveEmail.isEmpty) {
      return;
    }

    await _client.from('profiles').upsert(
      {
        'id': uid,
        'email': effectiveEmail,
      },
      onConflict: 'id',
    );

    await _client.from('public_profiles').upsert(
      {
        'user_id': uid,
        'display_name': effectiveDisplayName,
        if (userType != null) 'user_type': _userTypeToDb(userType),
        if (playerLevel != null) 'player_level': _playerLevelToDb(playerLevel),
      },
      onConflict: 'user_id',
    );
  }

  Future<Map<String, dynamic>?> _fetchProfile(String uid) async {
    final result = await _client
        .from('profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();
    return result == null ? null : Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>?> _fetchPublicProfile(String uid) async {
    final result = await _client
        .from('public_profiles')
        .select()
        .eq('user_id', uid)
        .maybeSingle();
    return result == null ? null : Map<String, dynamic>.from(result);
  }

  Future<List<String>> _fetchManagedCenterIds(String uid) async {
    final rows = await _client
        .from('tennis_center_managers')
        .select('center_id')
        .eq('user_id', uid);

    return (rows as List)
        .map((row) => row['center_id'] as String)
        .toList(growable: false);
  }

  UserModel _buildUserModel({
    required Map<String, dynamic> profile,
    required Map<String, dynamic> publicProfile,
    required List<String> managedCenterIds,
  }) {
    return UserModel(
      id: profile['id'] as String,
      email: (profile['email'] as String?) ?? '',
      displayName: (publicProfile['display_name'] as String?) ?? 'Player',
      playerLevel: _playerLevelFromDb(publicProfile['player_level'] as String?),
      userType: _userTypeFromDb(publicProfile['user_type'] as String?),
      createdAt: DateTime.tryParse(profile['created_at'] as String? ?? '') ??
          DateTime.now(),
      phoneNumber: profile['phone_number'] as String?,
      profileImageUrl: publicProfile['profile_image_path'] as String?,
      preferredPlayTimes: profile['preferred_play_times'] == null
          ? null
          : List<String>.from(profile['preferred_play_times'] as List),
      preferredLocations: profile['preferred_locations'] == null
          ? null
          : List<String>.from(profile['preferred_locations'] as List),
      stripeCustomerId: profile['stripe_customer_id'] as String?,
      paymentMethods: null,
      managedTennisCenters: managedCenterIds,
      onboardingCompleted:
          profile['onboarding_completed'] as bool? ?? false,
    );
  }

  AppAuthUser? _mapAuthUser(User? user) {
    if (user == null) {
      return null;
    }

    return AppAuthUser(
      uid: user.id,
      email: user.email,
      metadata: Map<String, dynamic>.from(user.userMetadata ?? const {}),
    );
  }

  String _bestDisplayName(
    Map<String, dynamic>? metadata, {
    String? fallbackEmail,
  }) {
    final rawDisplayName = metadata == null
        ? null
        : metadata['display_name'] as String?;
    if (rawDisplayName != null && rawDisplayName.trim().isNotEmpty) {
      return rawDisplayName.trim();
    }

    if (fallbackEmail != null && fallbackEmail.contains('@')) {
      return fallbackEmail.split('@').first;
    }

    return 'Tennis Player';
  }

  PlayerLevel _playerLevelFromDb(String? value) {
    switch (value) {
      case 'beginner':
        return PlayerLevel.beginner;
      case 'advanced':
        return PlayerLevel.advanced;
      case 'pro':
        return PlayerLevel.pro;
      case 'intermediate':
      default:
        return PlayerLevel.intermediate;
    }
  }

  String _playerLevelToDb(PlayerLevel level) {
    return level.toString().split('.').last;
  }

  UserType _userTypeFromDb(String? value) {
    switch (value) {
      case 'court_manager':
        return UserType.courtManager;
      case 'player':
      default:
        return UserType.player;
    }
  }

  String _userTypeToDb(UserType type) {
    switch (type) {
      case UserType.courtManager:
        return 'court_manager';
      case UserType.player:
        return 'player';
    }
  }

  String _handleAuthException(AuthException exception) {
    switch (exception.code) {
      case 'invalid_credentials':
        return 'Invalid email or password.';
      case 'email_exists':
      case 'user_already_exists':
        return 'An account with this email already exists.';
      case 'email_not_confirmed':
        return 'Please confirm your email before signing in.';
      case 'weak_password':
        return 'Password is too weak.';
      default:
        return exception.message;
    }
  }
}
