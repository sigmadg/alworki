class SocialUser {
  const SocialUser({
    required this.id,
    required this.name,
    required this.avatar,
    this.verified = false,
    this.following = false,
  });

  final int id;
  final String name;
  final String avatar;
  final bool verified;
  final bool following;

  SocialUser copyWith({bool? following}) => SocialUser(
        id: id,
        name: name,
        avatar: avatar,
        verified: verified,
        following: following ?? this.following,
      );

  factory SocialUser.fromJson(Map<String, dynamic> json) => SocialUser(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        avatar: json['avatar'] as String? ?? '',
        verified: json['verified'] as bool? ?? false,
        following: json['following'] as bool? ?? false,
      );
}
