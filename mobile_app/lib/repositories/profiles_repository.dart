import '../models/user_model.dart';
import 'repository_support.dart';

class ProfilesRepository extends RepositorySupport {
  ProfilesRepository._internal();

  static final ProfilesRepository _instance = ProfilesRepository._internal();

  factory ProfilesRepository() => _instance;

  Future<List<UserModel>> getUsers() async {
    final profileRows = await client.from('profiles').select('id');
    final ids = (profileRows as List)
        .map((row) => row['id'] as String)
        .toList(growable: false);
    return getUsersByIds(ids);
  }

  Future<List<UserModel>> getUsersByEmail(String email) async {
    final rows = await client.from('profiles').select('id').eq('email', email);
    final ids = (rows as List)
        .map((row) => row['id'] as String)
        .toList(growable: false);
    return getUsersByIds(ids);
  }

  Future<List<UserModel>> searchUsers(String searchTerm) async {
    final trimmed = searchTerm.trim();
    if (trimmed.isEmpty) {
      return const <UserModel>[];
    }

    final rpcRows = await client.rpc(
      'search_player_directory',
      params: {
        'search_term': trimmed,
        'limit_count': 20,
      },
    );

    final ids = (rpcRows as List)
        .map((row) => row['user_id'] as String)
        .toList(growable: false);
    return getUsersByIds(ids);
  }

  Future<void> createUser(UserModel user) => _upsertUser(user);

  Future<void> updateUser(UserModel user) => _upsertUser(user);

  Future<UserModel?> getUser(String userId) async {
    final users = await getUsersByIds(<String>[userId]);
    return users.isEmpty ? null : users.first;
  }

  Future<void> addUserContact(String userId, String contactId) async {
    await client.from('user_contacts').upsert(
      <String, dynamic>{
        'user_id': userId,
        'contact_user_id': contactId,
      },
      onConflict: 'user_id,contact_user_id',
    );
  }

  Future<void> removeUserContact(String userId, String contactId) async {
    await client
        .from('user_contacts')
        .delete()
        .eq('user_id', userId)
        .eq('contact_user_id', contactId);
  }

  Future<List<UserModel>> getUserContacts(String userId) async {
    final rows = await client
        .from('user_contacts')
        .select('contact_user_id')
        .eq('user_id', userId);

    final ids = (rows as List)
        .map((row) => row['contact_user_id'] as String)
        .toList(growable: false);

    return getUsersByIds(ids);
  }

  Future<List<UserModel>> getUsersByIds(List<String> ids) async {
    if (ids.isEmpty) {
      return const <UserModel>[];
    }

    final profileRows =
        await client.from('profiles').select().inFilter('id', ids);
    final publicRows =
        await client.from('public_profiles').select().inFilter('user_id', ids);
    final managerRows = await client
        .from('tennis_center_managers')
        .select('user_id,center_id')
        .inFilter('user_id', ids);

    final profileById = <String, Map<String, dynamic>>{};
    for (final row in profileRows as List) {
      final map = Map<String, dynamic>.from(row);
      profileById[map['id'] as String] = map;
    }

    final publicById = <String, Map<String, dynamic>>{};
    for (final row in publicRows as List) {
      final map = Map<String, dynamic>.from(row);
      publicById[map['user_id'] as String] = map;
    }

    final managedCentersByUser = <String, List<String>>{};
    for (final row in managerRows as List) {
      final map = Map<String, dynamic>.from(row);
      managedCentersByUser
          .putIfAbsent(map['user_id'] as String, () => <String>[])
          .add(
            map['center_id'] as String,
          );
    }

    final orderedUsers = <UserModel>[];
    for (final id in ids) {
      final profile = profileById[id];
      final publicProfile = publicById[id];
      if (profile == null || publicProfile == null) {
        continue;
      }

      orderedUsers.add(
        UserModel(
          id: id,
          email: profile['email'] as String? ?? '',
          displayName: publicProfile['display_name'] as String? ?? 'Player',
          playerLevel:
              playerLevelFromDb(publicProfile['player_level'] as String?),
          userType: userTypeFromDb(publicProfile['user_type'] as String?),
          createdAt: parseDbDateTime(profile['created_at']),
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
          managedTennisCenters: managedCentersByUser[id],
          onboardingCompleted:
              profile['onboarding_completed'] as bool? ?? false,
        ),
      );
    }

    return orderedUsers;
  }

  Future<void> _upsertUser(UserModel user) async {
    await client.from('profiles').upsert(
      <String, dynamic>{
        'id': user.id,
        'email': user.email,
        'phone_number': user.phoneNumber,
        'preferred_play_times': user.preferredPlayTimes,
        'preferred_locations': user.preferredLocations,
        'stripe_customer_id': user.stripeCustomerId,
        'onboarding_completed': user.onboardingCompleted,
      },
      onConflict: 'id',
    );

    await client.from('public_profiles').upsert(
      <String, dynamic>{
        'user_id': user.id,
        'display_name': user.displayName,
        'player_level': user.playerLevel.name,
        'user_type':
            user.userType == UserType.courtManager ? 'court_manager' : 'player',
        'profile_image_path': user.profileImageUrl,
      },
      onConflict: 'user_id',
    );
  }
}
