import 'social_user.dart';

class StoryItem {
  StoryItem({
    required this.id,
    required this.user,
    required this.caption,
    required this.imageKey,
    required this.cardId,
    required this.cardTitle,
    required this.timestamp,
    required this.duration,
    this.viewed = false,
  });

  final int id;
  final SocialUser user;
  final String caption;
  final String imageKey;
  final int cardId;
  final String cardTitle;
  final DateTime timestamp;
  final int duration;
  bool viewed;

  StoryItem copyWith({bool? viewed}) => StoryItem(
        id: id,
        user: user,
        caption: caption,
        imageKey: imageKey,
        cardId: cardId,
        cardTitle: cardTitle,
        timestamp: timestamp,
        duration: duration,
        viewed: viewed ?? this.viewed,
      );

  factory StoryItem.fromJson(Map<String, dynamic> json) => StoryItem(
        id: (json['id'] as num).toInt(),
        user: SocialUser.fromJson(json['user'] as Map<String, dynamic>),
        caption: json['caption'] as String? ?? '',
        imageKey: json['image_url'] as String? ?? json['media_url'] as String? ?? '',
        cardId: (json['card_id'] as num?)?.toInt() ?? 0,
        cardTitle: json['card_title'] as String? ?? '',
        timestamp: DateTime.parse(json['timestamp'] as String),
        duration: (json['duration'] as num?)?.toInt() ?? 5,
        viewed: json['viewed'] as bool? ?? false,
      );
}
