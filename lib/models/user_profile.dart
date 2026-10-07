import 'social_user.dart';

class ProfileSkill {
  const ProfileSkill({required this.id, required this.name});
  final int id;
  final String name;
}

class PortfolioItem {
  const PortfolioItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageKey,
    this.tag = 'LOCAL',
    this.category = '',
    this.profession = '',
    this.priceMxn = 0,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.location = 'México',
  });

  final int id;
  final String title;
  final String description;
  final String imageKey;
  final String tag;
  final String category;
  final String profession;
  final int priceMxn;
  final int likes;
  final int comments;
  final int shares;
  final String location;

  factory PortfolioItem.fromJson(Map<String, dynamic> p) => PortfolioItem(
        id: (p['id'] as num).toInt(),
        title: p['title'] as String? ?? '',
        description: p['description'] as String? ?? '',
        imageKey: p['image'] as String? ?? p['image_url'] as String? ?? 'background1.png',
        tag: p['tag'] as String? ?? 'LOCAL',
        category: p['category'] as String? ?? '',
        profession: p['profession'] as String? ?? '',
        priceMxn: (p['priceMxn'] as num?)?.toInt() ?? (p['price_mxn'] as num?)?.toInt() ?? 0,
        likes: (p['likes'] as num?)?.toInt() ?? 0,
        comments: (p['comments'] as num?)?.toInt() ?? 0,
        shares: (p['shares'] as num?)?.toInt() ?? 0,
        location: p['location'] as String? ?? 'México',
      );
}

class ProfileReview {
  const ProfileReview({
    required this.id,
    required this.user,
    required this.rating,
    required this.date,
    required this.text,
    this.serviceTitle,
  });
  final int id;
  final SocialUser user;
  final int rating;
  final String date;
  final String text;
  final String? serviceTitle;
}

class UserProfile {
  UserProfile({
    required this.id,
    required this.name,
    required this.verified,
    required this.avatar,
    required this.contacts,
    required this.professions,
    required this.localContacts,
    required this.remoteContacts,
    required this.localAvailable,
    required this.remoteAvailable,
    required this.skills,
    required this.materials,
    required this.portfolio,
    required this.reviews,
  });

  final int id;
  final String name;
  final bool verified;
  final String avatar;
  final int contacts;
  final List<String> professions;
  final int localContacts;
  final int remoteContacts;
  bool localAvailable;
  bool remoteAvailable;
  final List<ProfileSkill> skills;
  final List<ProfileSkill> materials;
  final List<PortfolioItem> portfolio;
  final List<ProfileReview> reviews;

  UserProfile copyWith({
    bool? localAvailable,
    bool? remoteAvailable,
    List<String>? professions,
    List<PortfolioItem>? portfolio,
    List<ProfileSkill>? skills,
    List<ProfileSkill>? materials,
    int? contacts,
  }) =>
      UserProfile(
        id: id,
        name: name,
        verified: verified,
        avatar: avatar,
        contacts: contacts ?? this.contacts,
        professions: professions ?? this.professions,
        localContacts: localContacts,
        remoteContacts: remoteContacts,
        localAvailable: localAvailable ?? this.localAvailable,
        remoteAvailable: remoteAvailable ?? this.remoteAvailable,
        skills: skills ?? this.skills,
        materials: materials ?? this.materials,
        portfolio: portfolio ?? this.portfolio,
        reviews: reviews,
      );

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        verified: json['verified'] as bool? ?? false,
        avatar: json['avatar'] as String? ?? 'users/user.jpg',
        contacts: (json['contacts'] as num?)?.toInt() ?? 0,
        professions: (json['professions'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        localContacts: (json['localContacts'] as num?)?.toInt() ?? 0,
        remoteContacts: (json['remoteContacts'] as num?)?.toInt() ?? 0,
        localAvailable: json['localAvailable'] as bool? ?? true,
        remoteAvailable: json['remoteAvailable'] as bool? ?? true,
        skills: (json['skills'] as List<dynamic>? ?? [])
            .map((s) => ProfileSkill(id: (s['id'] as num).toInt(), name: s['name'] as String))
            .toList(),
        materials: (json['materials'] as List<dynamic>? ?? [])
            .map((s) => ProfileSkill(id: (s['id'] as num).toInt(), name: s['name'] as String))
            .toList(),
        portfolio: (json['portfolio'] as List<dynamic>? ?? [])
            .map((p) => PortfolioItem.fromJson(p as Map<String, dynamic>))
            .toList(),
        reviews: (json['reviews'] as List<dynamic>? ?? [])
            .map(
              (r) => ProfileReview(
                id: (r['id'] as num).toInt(),
                user: SocialUser.fromJson(r['user'] as Map<String, dynamic>),
                rating: (r['rating'] as num).toInt(),
                date: r['date'] as String? ?? '',
                text: r['text'] as String? ?? '',
                serviceTitle: r['serviceTitle'] as String? ?? r['service_title'] as String?,
              ),
            )
            .toList(),
      );
}
