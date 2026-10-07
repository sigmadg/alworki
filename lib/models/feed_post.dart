import 'social_user.dart';

class FeedPost {
  FeedPost({
    required this.id,
    required this.user,
    required this.imageKey,
    required this.description,
    required this.likes,
    required this.comments,
    required this.cost,
    required this.costType,
    required this.cardId,
    required this.cardTitle,
    required this.location,
    required this.timestamp,
    this.lat,
    this.lng,
    this.recommended = false,
    this.saved = false,
    this.liked = false,
    this.category = '',
  });

  final int id;
  final SocialUser user;
  final String imageKey;
  final String description;
  int likes;
  final int comments;
  final int cost;
  final String costType;
  final int cardId;
  final String cardTitle;
  final String location;
  final DateTime timestamp;
  final double? lat;
  final double? lng;
  bool recommended;
  bool saved;
  bool liked;
  final String category;

  FeedPost copyWith({
    SocialUser? user,
    int? likes,
    bool? recommended,
    bool? saved,
    bool? liked,
  }) =>
      FeedPost(
        id: id,
        user: user ?? this.user,
        imageKey: imageKey,
        description: description,
        likes: likes ?? this.likes,
        comments: comments,
        cost: cost,
        costType: costType,
        cardId: cardId,
        cardTitle: cardTitle,
        location: location,
        timestamp: timestamp,
        lat: lat,
        lng: lng,
        recommended: recommended ?? this.recommended,
        saved: saved ?? this.saved,
        liked: liked ?? this.liked,
        category: category,
      );

  factory FeedPost.fromJson(Map<String, dynamic> json) => FeedPost(
        id: (json['id'] as num).toInt(),
        user: SocialUser.fromJson(json['user'] as Map<String, dynamic>),
        imageKey: json['image_url'] as String? ?? '',
        description: json['description'] as String,
        likes: (json['likes'] as num?)?.toInt() ?? 0,
        comments: (json['comments'] as num?)?.toInt() ?? 0,
        cost: (json['cost'] as num?)?.toInt() ?? 0,
        costType: json['cost_type'] as String? ?? 'Favor',
        cardId: (json['card_id'] as num).toInt(),
        cardTitle: json['card_title'] as String,
        location: json['location'] as String? ?? '',
        timestamp: DateTime.parse(json['timestamp'] as String),
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        recommended: json['recommended'] as bool? ?? false,
        saved: json['saved'] as bool? ?? false,
        liked: json['liked'] as bool? ?? false,
        category: json['category'] as String? ?? '',
      );
}
