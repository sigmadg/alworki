import 'dart:math' as math;

/// Cuadrado que contiene el círculo de búsqueda — filtro rápido sin haversine.
class ProximityBounds {
  const ProximityBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  /// Y2 / Y1 (sur / norte), X2 / X1 (oeste / este).
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  static const double kmPerDegreeLat = 111.0;

  factory ProximityBounds.fromCircle({
    required double centerLat,
    required double centerLng,
    required double radiusKm,
  }) {
    final dLat = radiusKm / kmPerDegreeLat;
    final cosLat = math.cos(centerLat * math.pi / 180).abs().clamp(0.01, 1.0);
    final dLng = radiusKm / (kmPerDegreeLat * cosLat);
    return ProximityBounds(
      minLat: centerLat - dLat,
      maxLat: centerLat + dLat,
      minLng: centerLng - dLng,
      maxLng: centerLng + dLng,
    );
  }

  /// lat ∈ [minLat, maxLat] y lng ∈ [minLng, maxLng]
  bool contains(double lat, double lng) =>
      lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;

  /// Distancia aproximada en km (suficiente para ordenar dentro del cuadrado).
  static double approximateKm({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    final dLat = (toLat - fromLat) * kmPerDegreeLat;
    final dLng = (toLng - fromLng) * kmPerDegreeLat * math.cos(fromLat * math.pi / 180);
    return math.sqrt(dLat * dLat + dLng * dLng);
  }
}

/// Filtra y ordena ítems con coordenadas por cercanía (bounding box + orden simple).
List<T> filterByProximity<T>({
  required List<T> items,
  required double centerLat,
  required double centerLng,
  required double radiusKm,
  required double? Function(T item) readLat,
  required double? Function(T item) readLng,
}) {
  final bounds = ProximityBounds.fromCircle(
    centerLat: centerLat,
    centerLng: centerLng,
    radiusKm: radiusKm,
  );

  final matched = <({T item, double km})>[];
  for (final item in items) {
    final lat = readLat(item);
    final lng = readLng(item);
    if (lat == null || lng == null) continue;
    if (!bounds.contains(lat, lng)) continue;
    final km = ProximityBounds.approximateKm(
      fromLat: centerLat,
      fromLng: centerLng,
      toLat: lat,
      toLng: lng,
    );
    matched.add((item: item, km: km));
  }
  matched.sort((a, b) => a.km.compareTo(b.km));
  return matched.map((e) => e.item).toList();
}
