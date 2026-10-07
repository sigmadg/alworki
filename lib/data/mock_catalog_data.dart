import '../models/feed_post.dart';
import '../models/project_item.dart';
import '../models/service_card.dart';
import '../models/social_user.dart';
import '../models/story_item.dart';
import '../models/user_profile.dart';

/// Datos portados de `Ejemplo/AlworkiAuto/Backend/app_unified.py`, adaptados a
/// intercambio de favores (Instagram + tarjetas tipo Fiverr).
class MockCatalogData {
  MockCatalogData._();

  static final cards = <ServiceCard>[
    const ServiceCard(
      id: 1,
      title: 'Clases de inglés conversacional',
      description: 'Práctica oral y corrección de pronunciación. Ideal para intercambiar por otro favor.',
      imageKey: 'english',
      category: 'Educación',
      price: 2,
      rating: 4.9,
      reviewsCount: 31,
      lastUpdated: '2024-01-15',
    ),
    const ServiceCard(
      id: 2,
      title: 'Paseo de mascotas',
      description: 'Paseos de 45–60 min, reporte con fotos. Acepto favores de cocina o clases.',
      imageKey: 'pets',
      category: 'Cuidado animal',
      price: 1,
      rating: 4.8,
      reviewsCount: 24,
      lastUpdated: '2024-01-14',
    ),
    const ServiceCard(
      id: 3,
      title: 'Clases de guitarra básica',
      description: 'Acordes, ritmo y canciones sencillas. Modalidad presencial u online.',
      imageKey: 'music',
      category: 'Música',
      price: 2,
      rating: 4.7,
      reviewsCount: 18,
      lastUpdated: '2024-01-13',
    ),
    const ServiceCard(
      id: 4,
      title: 'Reparaciones menores del hogar',
      description: 'Enchufes, bisagras, estanterías. Intercambio por clases o paseos.',
      imageKey: 'home',
      category: 'Hogar',
      price: 3,
      rating: 4.6,
      reviewsCount: 15,
      lastUpdated: '2024-01-12',
    ),
    const ServiceCard(
      id: 5,
      title: 'Comida casera / meal prep',
      description: '2–3 raciones saludables. Busco favores de idiomas o cuidado de mascotas.',
      imageKey: 'food',
      category: 'Gastronomía',
      price: 2,
      rating: 4.5,
      reviewsCount: 22,
      lastUpdated: '2024-01-11',
    ),
  ];

  static List<FeedPost> feedPosts() => [
        FeedPost(
          id: 1,
          user: const SocialUser(id: 1, name: 'Laura M.', avatar: 'u1', verified: true),
          imageKey: 'english',
          description:
              'Ofrezco 2h de inglés a la semana. Busco alguien que pasee a mi perro los martes. #intercambio #ingles',
          likes: 342,
          comments: 28,
          cost: 2,
          costType: 'horas favor',
          cardId: 1,
          cardTitle: 'Clases de inglés conversacional',
          location: 'Ciudad de México',
          timestamp: DateTime.parse('2024-01-15T10:30:00Z'),
        ),
        FeedPost(
          id: 2,
          user: const SocialUser(id: 2, name: 'Diego R.', avatar: 'u2'),
          imageKey: 'pets',
          description: 'Paseo responsable con experiencia en perros grandes. Intercambio por clases de guitarra.',
          likes: 198,
          comments: 12,
          cost: 1,
          costType: 'paseo',
          cardId: 2,
          cardTitle: 'Paseo de mascotas',
          location: 'Guadalajara',
          timestamp: DateTime.parse('2024-01-14T15:45:00Z'),
        ),
        FeedPost(
          id: 3,
          user: const SocialUser(id: 3, name: 'Sofía K.', avatar: 'u3', verified: true),
          imageKey: 'music',
          description: 'Primera clase gratis para probar. A cambio me ayudas con meal prep del fin de semana.',
          likes: 521,
          comments: 45,
          cost: 2,
          costType: 'horas favor',
          cardId: 3,
          cardTitle: 'Clases de guitarra básica',
          location: 'Monterrey',
          timestamp: DateTime.parse('2024-01-13T09:15:00Z'),
        ),
        FeedPost(
          id: 4,
          user: const SocialUser(id: 4, name: 'Andrés V.', avatar: 'u4'),
          imageKey: 'home',
          description: 'Arreglo estantería o enchufes. Busco práctica de inglés para entrevistas.',
          likes: 267,
          comments: 19,
          cost: 3,
          costType: 'horas favor',
          cardId: 4,
          cardTitle: 'Reparaciones menores del hogar',
          location: 'Puebla',
          timestamp: DateTime.parse('2024-01-12T14:20:00Z'),
        ),
        FeedPost(
          id: 5,
          user: const SocialUser(id: 5, name: 'Elena P.', avatar: 'u5', verified: true),
          imageKey: 'food',
          description: 'Cocino vegetariano los domingos. Intercambio por paseos o clases.',
          likes: 410,
          comments: 33,
          cost: 2,
          costType: 'raciones',
          cardId: 5,
          cardTitle: 'Comida casera / meal prep',
          location: 'Querétaro',
          timestamp: DateTime.parse('2024-01-11T11:30:00Z'),
        ),
      ];

  static List<StoryItem> stories() => [
        StoryItem(
          id: 1,
          user: const SocialUser(id: 1, name: 'Laura', avatar: 'u1', verified: true),
          caption: 'Nueva oferta: inglés ↔ paseos',
          imageKey: 'english',
          cardId: 1,
          cardTitle: 'Clases de inglés',
          timestamp: DateTime.parse('2024-01-15T10:30:00Z'),
          duration: 5,
        ),
        StoryItem(
          id: 2,
          user: const SocialUser(id: 2, name: 'Diego', avatar: 'u2'),
          caption: 'Disponible fines de semana',
          imageKey: 'pets',
          cardId: 2,
          cardTitle: 'Paseo de mascotas',
          timestamp: DateTime.parse('2024-01-15T09:15:00Z'),
          duration: 5,
        ),
        StoryItem(
          id: 3,
          user: const SocialUser(id: 3, name: 'Sofía', avatar: 'u3', verified: true),
          caption: 'Clase demo de guitarra',
          imageKey: 'music',
          cardId: 3,
          cardTitle: 'Guitarra',
          timestamp: DateTime.parse('2024-01-15T08:45:00Z'),
          duration: 5,
          viewed: true,
        ),
        StoryItem(
          id: 4,
          user: const SocialUser(id: 4, name: 'Andrés', avatar: 'u4'),
          caption: 'Antes / después reparación',
          imageKey: 'home',
          cardId: 4,
          cardTitle: 'Hogar',
          timestamp: DateTime.parse('2024-01-15T07:30:00Z'),
          duration: 5,
        ),
        StoryItem(
          id: 5,
          user: const SocialUser(id: 5, name: 'Elena', avatar: 'u5', verified: true),
          caption: 'Menú del domingo',
          imageKey: 'food',
          cardId: 5,
          cardTitle: 'Cocina',
          timestamp: DateTime.parse('2024-01-15T06:20:00Z'),
          duration: 5,
        ),
      ];

  static UserProfile defaultProfile() => UserProfile(
        id: 1,
        name: 'Tu perfil Alworki',
        verified: false,
        avatar: 'me',
        contacts: 12,
        professions: ['Ofrezco favores', 'Busco intercambios'],
        localContacts: 8,
        remoteContacts: 4,
        localAvailable: true,
        remoteAvailable: true,
        skills: const [
          ProfileSkill(id: 1, name: 'Inglés B2'),
          ProfileSkill(id: 2, name: 'Paseo de perros'),
          ProfileSkill(id: 3, name: 'Cocina básica'),
        ],
        materials: const [],
        portfolio: const [
          PortfolioItem(
            id: 1,
            title: 'Intercambio inglés ↔ paseos',
            description: '3 semanas con Laura',
            imageKey: 'english',
          ),
          PortfolioItem(
            id: 2,
            title: 'Meal prep dominical',
            description: 'Intercambio con Elena',
            imageKey: 'food',
          ),
        ],
        reviews: const [
          ProfileReview(
            id: 1,
            user: SocialUser(id: 2, name: 'Diego R.', avatar: 'u2'),
            rating: 5,
            date: '2024-01-10',
            text: 'Muy puntual con las clases de inglés, recomendado.',
          ),
        ],
      );

  static const sampleProjects = <ProjectItem>[
    ProjectItem(
      id: 1,
      name: 'Inglés ↔ Paseos',
      description: '2h inglés semanal a cambio de paseos martes/jueves',
      status: ProjectStatus.enCurso,
      partnerName: 'Laura M.',
    ),
    ProjectItem(
      id: 2,
      name: 'Guitarra + meal prep',
      description: 'Clases quincenales por raciones del domingo',
      status: ProjectStatus.planificacion,
      partnerName: 'Sofía K.',
    ),
  ];
}
