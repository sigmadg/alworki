class ServiceCard {
  const ServiceCard({
    required this.id,
    required this.title,
    required this.description,
    required this.imageKey,
    required this.category,
    required this.price,
    required this.rating,
    required this.reviewsCount,
    required this.lastUpdated,
    this.lat,
    this.lng,
    this.ownerUserId,
    this.distanceKm,
    this.matchScore,
    this.matchedRequirements = const [],
    this.meetsRequirements = true,
    this.trade,
  });

  final int id;
  final String title;
  final String description;
  final String imageKey;
  final String category;
  final int price;
  final double rating;
  final int reviewsCount;
  final String lastUpdated;
  final double? lat;
  final double? lng;
  final int? ownerUserId;
  final double? distanceKm;
  final double? matchScore;
  final List<String> matchedRequirements;
  final bool meetsRequirements;
  final String? trade;

  bool get hasCoords => lat != null && lng != null;

  factory ServiceCard.fromJson(Map<String, dynamic> json) => ServiceCard(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String,
        description: json['description'] as String,
        imageKey: json['image_url'] as String? ?? json['imageKey'] as String? ?? '',
        category: json['category'] as String,
        price: (json['price'] as num).toInt(),
        rating: (json['rating'] as num).toDouble(),
        reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
        lastUpdated: json['last_updated'] as String? ?? '',
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        ownerUserId: (json['ownerUserId'] as num?)?.toInt() ?? (json['owner_user_id'] as num?)?.toInt(),
        distanceKm: (json['distanceKm'] as num?)?.toDouble(),
        matchScore: (json['matchScore'] as num?)?.toDouble(),
        matchedRequirements:
            (json['matchedRequirements'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        meetsRequirements: json['meetsRequirements'] as bool? ?? true,
        trade: json['trade'] as String?,
      );
}
