class User {
  final int id;
  final String name;
  final String imageUrl;

  const User({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  /// Alias for imageUrl to maintain compatibility
  String get photoUrl => imageUrl;
}
