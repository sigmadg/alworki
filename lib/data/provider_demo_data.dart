import '../models/social_user.dart';
import '../models/user_profile.dart';

class BookableItem {
  const BookableItem({required this.id, required this.name, this.rating = 5});
  final int id;
  final String name;
  final int rating;
}

/// Datos demo al estilo Figma (Tina Shah — usuario no verificado en vista pública).
class ProviderDemoData {
  ProviderDemoData._();

  static const tinaName = 'Tina Shah';
  static const tinaAvatar = 'users/4.jpg';
  static const tinaProfessions = ['Pintor', 'Carpintero', 'Escultor'];

  static const services = [
    BookableItem(id: 1, name: 'Pintura al óleo', rating: 4),
    BookableItem(id: 2, name: 'Escultura', rating: 5),
    BookableItem(id: 3, name: 'Mesa', rating: 5),
  ];

  static const materials = [
    BookableItem(id: 1, name: 'Madera', rating: 5),
    BookableItem(id: 2, name: 'Mármol', rating: 4),
    BookableItem(id: 3, name: 'Cedro', rating: 5),
    BookableItem(id: 4, name: 'Acero', rating: 4),
  ];

  static const portfolioImages = [
    'background1.png',
    'background2.png',
    'background3.png',
    'background4.png',
    'background5.png',
    'background2.png',
  ];

  static const defaultSkillNames = ['Pintura al óleo', 'Escultura', 'Mesa'];
  static const defaultMaterialNames = ['Madera', 'Mármol', 'Acero'];

  static List<ProfileSkill> demoSkills(List<ProfileSkill> base) {
    if (base.isNotEmpty) return base;
    return [
      for (var i = 0; i < defaultSkillNames.length; i++)
        ProfileSkill(id: i + 1, name: defaultSkillNames[i]),
    ];
  }

  static List<ProfileSkill> demoMaterials(List<ProfileSkill> base) {
    if (base.isNotEmpty) return base;
    return [
      for (var i = 0; i < defaultMaterialNames.length; i++)
        ProfileSkill(id: i + 1, name: defaultMaterialNames[i]),
    ];
  }

  static UserProfile enrichedProfile(UserProfile base, {bool? forceVerified}) {
    final verified = forceVerified ?? (base.verified || base.name == tinaName);
    final hasRichData = base.portfolio.isNotEmpty && base.reviews.isNotEmpty;

    if (hasRichData && base.name.isNotEmpty && base.name != 'Invitado' && forceVerified != true) {
      return base;
    }

    return UserProfile(
      id: base.id,
      name: base.name.isNotEmpty && base.name != 'Invitado' ? base.name : tinaName,
      verified: verified,
      avatar: base.avatar != 'users/user.jpg' ? base.avatar : tinaAvatar,
      contacts: base.contacts,
      professions: base.professions.length > 1 ? base.professions : tinaProfessions,
      localContacts: base.localContacts,
      remoteContacts: base.remoteContacts,
      localAvailable: base.localAvailable,
      remoteAvailable: base.remoteAvailable,
      skills: demoSkills(base.skills),
      materials: demoMaterials(base.materials),
      portfolio: base.portfolio.isNotEmpty
          ? base.portfolio
          : [
              for (var i = 0; i < portfolioImages.length; i++)
                PortfolioItem(
                  id: i + 1,
                  title: 'Trabajo ${i + 1}',
                  description: '',
                  imageKey: portfolioImages[i],
                ),
            ],
      reviews: base.reviews.isNotEmpty
          ? base.reviews
          : [
              ProfileReview(
                id: 1,
                user: const SocialUser(id: 10, name: 'Nathan', avatar: 'users/2.jpg'),
                rating: 5,
                date: '2024-12-01',
                serviceTitle: 'Pintura al óleo',
                text: 'Excelente trabajo',
              ),
              ProfileReview(
                id: 2,
                user: const SocialUser(id: 11, name: 'María L.', avatar: 'users/3.jpg', verified: true),
                rating: 5,
                date: '2024-11-20',
                serviceTitle: 'Pintura al óleo',
                text: 'Impecable. Cumplió plazos y presupuesto.',
              ),
            ],
    );
  }
}
