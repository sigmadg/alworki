import 'package:alworki_auto/models/feed_post.dart';
import 'package:alworki_auto/models/home_feed_entry.dart';
import 'package:alworki_auto/models/project_item.dart';
import 'package:alworki_auto/models/social_user.dart';
import 'package:alworki_auto/utils/feed_ranking.dart';
import 'package:flutter_test/flutter_test.dart';

FeedPost _post({
  required int id,
  required String desc,
  required String title,
  String category = 'oficios',
  int likes = 10,
  DateTime? timestamp,
}) {
  return FeedPost(
    id: id,
    user: SocialUser(id: id, name: 'User $id', avatar: 'users/1.jpg', verified: true, following: false),
    imageKey: 'background1.png',
    description: desc,
    likes: likes,
    comments: 2,
    cost: 1,
    costType: 'favor',
    cardId: id,
    cardTitle: title,
    location: 'CDMX',
    timestamp: timestamp ?? DateTime.now(),
    category: category,
  );
}

void main() {
  test('el ranking prioriza intereses del perfil', () {
    final posts = [
      _post(id: 1, desc: 'Limpieza profunda de oficinas', title: 'Limpieza', category: 'hogar', likes: 12),
      _post(id: 2, desc: 'Clases de inglés conversacional a cambio de paseo', title: 'Inglés', category: 'educación', likes: 12),
    ];
    const signals = FeedRankingSignals(userId: 9, skills: ['inglés'], professions: ['profesor']);
    expect(FeedRanking.scorePost(posts[1], signals), greaterThan(FeedRanking.scorePost(posts[0], signals)));
    final ranked = FeedRanking.rankPosts(posts, signals);
    expect(ranked.map((p) => p.id).toSet(), {1, 2});
  });

  test('el feed mezcla proyectos con publicaciones', () {
    final feed = <HomeFeedEntry>[
      HomeFeedEntry.post(_post(id: 1, desc: 'Favor de plomería', title: 'Plomería')),
      HomeFeedEntry.project(
        const ProjectItem(
          id: 4,
          name: 'Inglés ↔ Paseos',
          description: '2h inglés semanal',
          status: ProjectStatus.enCurso,
          partnerName: 'Laura M.',
        ),
      ),
    ];
    expect(feed.first.isProject, isFalse);
    expect(feed.last.isProject, isTrue);
    expect(feed.last.project!.statusLabel, 'En curso');
  });
}
