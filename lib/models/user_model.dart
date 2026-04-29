import 'model_serialization.dart';

enum PlayerLevel { beginner, intermediate, advanced, pro }

enum UserType { player, courtManager }

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final PlayerLevel playerLevel;
  final UserType userType;
  final DateTime createdAt;
  final String? phoneNumber;
  final String? profileImageUrl;
  final List<String>? preferredPlayTimes;
  final List<String>? preferredLocations;
  final String? stripeCustomerId;
  final List<String>? paymentMethods;
  final List<String>? managedTennisCenters;
  final bool onboardingCompleted;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.playerLevel,
    required this.userType,
    required this.createdAt,
    this.phoneNumber,
    this.profileImageUrl,
    this.preferredPlayTimes,
    this.preferredLocations,
    this.stripeCustomerId,
    this.paymentMethods,
    this.managedTennisCenters,
    this.onboardingCompleted = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return UserModel(
      id: id ?? data['id'] as String? ?? '',
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      playerLevel: _playerLevelFromString(data['playerLevel']),
      userType: _userTypeFromString(data['userType']),
      createdAt: parseDateTime(data['createdAt']),
      phoneNumber: data['phoneNumber'] as String?,
      profileImageUrl: data['profileImageUrl'] as String?,
      preferredPlayTimes: _stringList(data['preferredPlayTimes']),
      preferredLocations: _stringList(data['preferredLocations']),
      stripeCustomerId: data['stripeCustomerId'] as String?,
      paymentMethods: _stringList(data['paymentMethods']),
      managedTennisCenters: _stringList(data['managedTennisCenters']),
      onboardingCompleted: data['onboardingCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'playerLevel': playerLevel.name,
      'userType': userType.name,
      'createdAt': serializeDateTime(createdAt),
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'preferredPlayTimes': preferredPlayTimes,
      'preferredLocations': preferredLocations,
      'stripeCustomerId': stripeCustomerId,
      'paymentMethods': paymentMethods,
      'managedTennisCenters': managedTennisCenters,
      'onboardingCompleted': onboardingCompleted,
    };
  }

  factory UserModel.minimal(String uid, String email) {
    return UserModel(
      id: uid,
      email: email,
      displayName: email.split('@').first,
      playerLevel: PlayerLevel.intermediate,
      userType: UserType.player,
      createdAt: DateTime.now(),
      onboardingCompleted: false,
    );
  }

  UserModel copyWith({
    String? displayName,
    PlayerLevel? playerLevel,
    UserType? userType,
    String? phoneNumber,
    String? profileImageUrl,
    List<String>? preferredPlayTimes,
    List<String>? preferredLocations,
    String? stripeCustomerId,
    List<String>? paymentMethods,
    List<String>? managedTennisCenters,
    bool? onboardingCompleted,
  }) {
    return UserModel(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      playerLevel: playerLevel ?? this.playerLevel,
      userType: userType ?? this.userType,
      createdAt: createdAt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      preferredPlayTimes: preferredPlayTimes ?? this.preferredPlayTimes,
      preferredLocations: preferredLocations ?? this.preferredLocations,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      managedTennisCenters: managedTennisCenters ?? this.managedTennisCenters,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  static PlayerLevel _playerLevelFromString(dynamic value) {
    final levelString = value?.toString().toLowerCase();
    return PlayerLevel.values.firstWhere(
      (level) => level.name == levelString,
      orElse: () => PlayerLevel.intermediate,
    );
  }

  static UserType _userTypeFromString(dynamic value) {
    final typeString = value?.toString().toLowerCase();
    if (typeString == 'courtmanager' || typeString == 'court_manager') {
      return UserType.courtManager;
    }
    return UserType.values.firstWhere(
      (type) => type.name.toLowerCase() == typeString,
      orElse: () => UserType.player,
    );
  }

  static List<String>? _stringList(dynamic value) {
    if (value is List) {
      return List<String>.from(value);
    }
    return null;
  }
}
