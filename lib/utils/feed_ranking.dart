import 'dart:math' as math;

import '../models/feed_post.dart';
import '../models/story_item.dart';
import '../models/user_profile.dart';

/// Ranking de feed y sugerencias — señales al estilo Instagram.
class FeedRanking {
  FeedRanking._();

  static const weightInterest = 0.35;
  static const weightRelationship = 0.30;
  static const weightEngagement = 0.20;
  static const weightRecency = 0.15;
  static const recencyHalfLifeHours = 72.0;

  static Set<String> _tokenize(String text) {
    final re = RegExp(r'[a-záéíóúñ0-9]+', caseSensitive: false);
    return re
        .allMatches(text.toLowerCase())
        .map((m) => m.group(0)!)
        .where((t) => t.length > 2)
        .toSet();
  }

  static double interestScore({
    required String text,
    required FeedRankingSignals signals,
  }) {
    final keywords = <String>{};
    for (final s in signals.skills) {
      keywords.addAll(_tokenize(s));
    }
    for (final p in signals.professions) {
      keywords.addAll(_tokenize(p));
    }
    signals.categoryAffinity.forEach((cat, weight) {
      for (var i = 0; i < weight.clamp(0, 5); i++) {
        keywords.addAll(_tokenize(cat));
      }
    });

    if (keywords.isEmpty) return 0.35;

    final postTokens = _tokenize(text);
    if (postTokens.isEmpty) return 0.2;

    final overlap = keywords.intersection(postTokens).length;
    return math.min(1.0, overlap / math.max(3, keywords.length * 0.25));
  }

  static double relationshipScore({
    required int authorId,
    required bool following,
    required bool verified,
    required FeedRankingSignals signals,
  }) {
    if (authorId == signals.userId) return 0;
    var score = 0.0;
    if (following) score += 0.55;
    if (signals.trustedUserIds.contains(authorId)) score += 0.35;
    if (signals.contactUserIds.contains(authorId)) score += 0.45;
    if (verified) score += 0.12;
    return score.clamp(0.0, 1.0);
  }

  static double engagementScore(FeedPost post) {
    final raw = math.log(post.likes + 1) * 0.35 + post.comments * 0.08 + (post.saved ? 0.4 : 0);
    return (raw / 3.0).clamp(0.0, 1.0);
  }

  static double recencyScore(DateTime timestamp) {
    final hours = DateTime.now().difference(timestamp).inHours.toDouble().clamp(0.0, double.infinity);
    return math.exp(-hours / recencyHalfLifeHours);
  }

  static double proximityBonus(FeedPost post, FeedRankingSignals signals) {
    if (!signals.proximityEnabled || !post.hasCoords) return 0;
    final dLat = (post.lat! - signals.centerLat) * 111.0;
    final dLng = (post.lng! - signals.centerLng) * 111.0 * math.cos(signals.centerLat * math.pi / 180);
    final km = math.sqrt(dLat * dLat + dLng * dLng);
    if (km > signals.radiusKm) return 0;
    return 0.15 * (1.0 - km / signals.radiusKm);
  }

  static double scorePost(FeedPost post, FeedRankingSignals signals) {
    final text = '${post.description} ${post.cardTitle} ${post.category} ${post.location}';
    final base = weightInterest * interestScore(text: text, signals: signals) +
        weightRelationship * relationshipScore(
          authorId: post.user.id,
          following: post.user.following,
          verified: post.user.verified,
          signals: signals,
        ) +
        weightEngagement * engagementScore(post) +
        weightRecency * recencyScore(post.timestamp);
    return base + proximityBonus(post, signals);
  }

  static List<FeedPost> rankPosts(List<FeedPost> posts, FeedRankingSignals signals) {
    final scored = posts
        .map((p) => (score: scorePost(p, signals), post: p))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final result = <FeedPost>[];
    final pool = scored.map((e) => e).toList();
    final recentAuthors = <int>[];

    while (pool.isNotEmpty) {
      var bestIdx = 0;
      var bestAdjusted = -1.0;
      final window = pool.length < 8 ? pool.length : 8;
      for (var i = 0; i < window; i++) {
        final author = pool[i].post.user.id;
        final penalty = recentAuthors.reversed.take(3).where((a) => a == author).length * 0.18;
        final adjusted = pool[i].score - penalty;
        if (adjusted > bestAdjusted) {
          bestAdjusted = adjusted;
          bestIdx = i;
        }
      }
      final picked = pool.removeAt(bestIdx);
      recentAuthors.add(picked.post.user.id);
      result.add(
        picked.post.copyWith(recommended: picked.score >= 0.45),
      );
    }
    return result;
  }

  static double scoreStory(StoryItem story, FeedRankingSignals signals) {
    if (signals.trustedUserIds.contains(story.user.id)) return -1;
    if (story.user.following) return -1;
    if (story.user.id == signals.userId) return -1;

    final text = '${story.caption} ${story.cardTitle}';
    var score = 0.25;
    if (story.user.verified) score += 0.2;
    score += 0.45 * interestScore(text: text, signals: signals);
    score += 0.25 * recencyScore(story.timestamp);
    if (signals.contactUserIds.contains(story.user.id)) score += 0.15;
    return score;
  }

  static List<StoryItem> rankStories(List<StoryItem> stories, FeedRankingSignals signals, {int limit = 12}) {
    final scored = stories
        .map((s) => (score: scoreStory(s, signals), story: s))
        .where((e) => e.score >= 0)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return scored.take(limit).map((e) => e.story).toList();
  }

  static FeedRankingSignals signalsFromProfile({
    required UserProfile profile,
    Set<int> trustedUserIds = const {},
    Set<int> contactUserIds = const {},
    Map<String, int> categoryAffinity = const {},
    bool proximityEnabled = false,
    double centerLat = 19.4326,
    double centerLng = -99.1332,
    double radiusKm = 15,
  }) =>
      FeedRankingSignals(
        userId: profile.id,
        skills: profile.skills.map((s) => s.name).toList(),
        professions: profile.professions,
        trustedUserIds: trustedUserIds,
        contactUserIds: contactUserIds,
        categoryAffinity: Map.from(categoryAffinity),
        proximityEnabled: proximityEnabled,
        centerLat: centerLat,
        centerLng: centerLng,
        radiusKm: radiusKm,
      );
}

class FeedRankingSignals {
  const FeedRankingSignals({
    required this.userId,
    this.skills = const [],
    this.professions = const [],
    this.trustedUserIds = const {},
    this.contactUserIds = const {},
    this.categoryAffinity = const {},
    this.proximityEnabled = false,
    this.centerLat = 19.4326,
    this.centerLng = -99.1332,
    this.radiusKm = 15,
  });

  final int userId;
  final List<String> skills;
  final List<String> professions;
  final Set<int> trustedUserIds;
  final Set<int> contactUserIds;
  final Map<String, int> categoryAffinity;
  final bool proximityEnabled;
  final double centerLat;
  final double centerLng;
  final double radiusKm;
}

extension FeedPostCoords on FeedPost {
  bool get hasCoords => lat != null && lng != null;
}
