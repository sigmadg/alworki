import 'package:alworki_auto/models/project_item.dart';
import 'package:alworki_auto/models/service_card.dart';
import 'package:alworki_auto/utils/job_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

ServiceCard _card({
  required int id,
  required String title,
  required String description,
  required double lat,
  required double lng,
  String category = 'Hogar y reparaciones',
  double rating = 4.5,
}) {
  return ServiceCard(
    id: id,
    title: title,
    description: description,
    imageKey: 'background4.png',
    category: category,
    price: 3,
    rating: rating,
    reviewsCount: 10,
    lastUpdated: '2026-01-01',
    lat: lat,
    lng: lng,
  );
}

void main() {
  test('el carpintero más cercano que cumple requisitos queda primero', () {
    const centerLat = 19.4326;
    const centerLng = -99.1332;
    final cards = [
      _card(
        id: 18,
        title: 'Carpintero de obra',
        description: 'Puertas y marcos. No hace muebles a medida.',
        lat: 19.39,
        lng: -99.18,
      ),
      _card(
        id: 17,
        title: 'Carpintería lejana',
        description: 'Muebles a medida en madera con herramientas propias.',
        lat: 19.41,
        lng: -99.16,
      ),
      _card(
        id: 16,
        title: 'Carpintero a domicilio',
        description: 'Muebles a medida, closets y reparación en madera. Herramientas propias.',
        lat: 19.433,
        lng: -99.1335,
      ),
    ];

    final ranked = matchJobs(
      cards: cards,
      query: 'carpintero',
      requirements: parseRequirements('muebles, madera, herramientas'),
      lat: centerLat,
      lng: centerLng,
    );

    expect(ranked, isNotEmpty);
    expect(ranked.first.card.id, 16);
    expect(ranked.first.meetsRequirements, isTrue);
    expect(ranked.first.distanceKm, lessThan(ranked[1].distanceKm!));
  });

  test('el seguimiento de entrega avanza solicitado → trabajo → entregado → confirmado', () {
    const project = ProjectItem(
      id: 1,
      name: 'Closet',
      description: 'Instalación',
      status: ProjectStatus.enCurso,
      partnerName: 'Luis',
      deliveryStatus: DeliveryStatus.enTrabajo,
      trackingNumber: 'AW-P-2026-0001',
    );
    expect(project.deliveryStepIndex, 1);
    expect(
      const ProjectItem(
        id: 1,
        name: 'Closet',
        description: 'Instalación',
        status: ProjectStatus.completado,
        partnerName: 'Luis',
        deliveryStatus: DeliveryStatus.confirmado,
      ).deliveryStepIndex,
      3,
    );
    expect(ProjectItem.deliverySteps.length, 4);
  });
}
