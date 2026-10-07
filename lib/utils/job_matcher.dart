import '../data/service_categories.dart';
import '../models/service_card.dart';
import 'proximity_bounds.dart';

class JobMatch {
  const JobMatch({
    required this.card,
    required this.matchedRequirements,
    required this.meetsRequirements,
    required this.score,
    this.distanceKm,
  });

  final ServiceCard card;
  final List<String> matchedRequirements;
  final bool meetsRequirements;
  final double score;
  final double? distanceKm;
}

List<String> parseRequirements(String raw) {
  return raw
      .split(RegExp(r'[,;]+'))
      .map((e) => e.trim().toLowerCase())
      .where((e) => e.length >= 2)
      .toSet()
      .take(12)
      .toList();
}

/// Ordena profesionales: primero quienes cumplen requisitos, luego el más cercano.
List<JobMatch> matchJobs({
  required List<ServiceCard> cards,
  required String query,
  List<String> requirements = const [],
  double? lat,
  double? lng,
}) {
  final q = query.trim().toLowerCase();
  final trades = q.isEmpty ? const <ServiceCategory>[] : categoriesMatchingQuery(q);
  final tradeTerms = {
    if (q.isNotEmpty) q,
    for (final t in trades) ...t.searchTerms,
  };

  final matches = <JobMatch>[];
  for (final card in cards) {
    final blob = '${card.title} ${card.description} ${card.category}'.toLowerCase();
    final tradeHit = tradeTerms.isEmpty || tradeTerms.any((t) => blob.contains(t));
    if (q.isNotEmpty && !tradeHit) continue;
    final matched = [for (final r in requirements) if (blob.contains(r)) r];
    final meets = requirements.isEmpty || matched.length == requirements.length;
    final distance = (lat != null && lng != null && card.hasCoords)
        ? ProximityBounds.approximateKm(
            fromLat: lat,
            fromLng: lng,
            toLat: card.lat!,
            toLng: card.lng!,
          )
        : card.distanceKm;
    final reqRatio = requirements.isEmpty ? 0.5 : matched.length / requirements.length;
    final score = (tradeHit ? 40.0 : 8.0) + reqRatio * 35 + card.rating * 3 - (distance ?? 8) * 1.6;
    matches.add(
      JobMatch(
        card: card,
        matchedRequirements: matched,
        meetsRequirements: meets,
        score: score,
        distanceKm: distance,
      ),
    );
  }

  matches.sort((a, b) {
    final req = (a.meetsRequirements ? 0 : 1).compareTo(b.meetsRequirements ? 0 : 1);
    if (req != 0) return req;
    final da = a.distanceKm ?? 999;
    final db = b.distanceKm ?? 999;
    final dist = da.compareTo(db);
    if (dist != 0) return dist;
    return b.score.compareTo(a.score);
  });
  return matches;
}
