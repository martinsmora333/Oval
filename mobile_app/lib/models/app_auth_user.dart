class AppAuthUser {
  const AppAuthUser({
    required this.uid,
    this.email,
    this.metadata = const {},
  });

  final String uid;
  final String? email;
  final Map<String, dynamic> metadata;

  String? get displayName => metadata['display_name'] as String?;
}
