import 'package:flutter/foundation.dart';

import '../../data/service_categories.dart';
import '../../models/feed_post.dart';
import '../models/home_feed_entry.dart';
import '../models/project_item.dart';
import '../models/service_card.dart';
import '../models/social_user.dart';
import '../models/story_item.dart';
import '../models/user_profile.dart';
import '../utils/feed_ranking.dart';
import '../utils/job_matcher.dart';
import '../utils/proximity_bounds.dart';
import 'api_client.dart';

/// Catálogo cargado desde `Backend/app_unified.py` (`/api/cards`, `/api/feed`, etc.).
class CatalogService extends ChangeNotifier {
  CatalogService(this._api, this._tokenProvider);

  final ApiClient _api;
  final String? Function() _tokenProvider;

  List<ServiceCard> _cards = [];
  List<FeedPost> _posts = [];
  List<StoryItem> _stories = [];
  UserProfile? _profile;
  List<ProjectItem> _projects = [];
  final Set<int> _trustedUserIds = {};
  final Set<int> _contactUserIds = {};
  final Map<String, int> _categoryAffinity = {};

  bool isLoading = false;
  String? error;

  /// Filtro por cercanía (bounding box sobre CDMX por defecto).
  bool proximityEnabled = false;
  double? userLat;
  double? userLng;
  static const double defaultRadiusKm = 15.0;
  static const double defaultLat = 19.4326;
  static const double defaultLng = -99.1332;

  double get searchLat => userLat ?? defaultLat;
  double get searchLng => userLng ?? defaultLng;

  void setProximityEnabled(bool value) {
    if (proximityEnabled == value) return;
    proximityEnabled = value;
    notifyListeners();
  }

  void setUserLocation(double? lat, double? lng) {
    userLat = lat;
    userLng = lng;
    notifyListeners();
  }

  List<ServiceCard> get cards => List.unmodifiable(_cards);
  List<FeedPost> get posts => List.unmodifiable(_posts);
  List<StoryItem> get stories => List.unmodifiable(_stories);
  UserProfile get profile => _profile ?? _emptyProfile();
  List<ProjectItem> get projects => List.unmodifiable(_projects);
  Set<int> get trustedUserIds => Set.unmodifiable(_trustedUserIds);

  FeedRankingSignals get _rankingSignals => FeedRanking.signalsFromProfile(
        profile: profile,
        trustedUserIds: _trustedUserIds,
        contactUserIds: _contactUserIds,
        categoryAffinity: _categoryAffinity,
        proximityEnabled: proximityEnabled,
        centerLat: searchLat,
        centerLng: searchLng,
        radiusKm: defaultRadiusKm,
      );

  /// Publicaciones ordenadas por relevancia (algoritmo estilo Instagram).
  List<FeedPost> get rankedPosts => FeedRanking.rankPosts(_posts, _rankingSignals);

  /// Feed de inicio: proyectos intercalados entre publicaciones.
  List<HomeFeedEntry> get homeFeed {
    final entries = rankedPosts.map(HomeFeedEntry.post).toList();
    for (var i = 0; i < _projects.length; i++) {
      final insertAt = (i + 1) * 2;
      final entry = HomeFeedEntry.project(_projects[i]);
      if (insertAt <= entries.length) {
        entries.insert(insertAt, entry);
      } else {
        entries.add(entry);
      }
    }
    return entries;
  }

  List<ServiceCard> _remoteSearch = [];
  String _lastRemoteQuery = '';
  bool isSearching = false;

  List<ServiceCard> get remoteSearchResults => List.unmodifiable(_remoteSearch);

  Future<List<ServiceCard>> searchCardsRemote(
    String query, {
    List<String> requirements = const [],
    bool nearest = true,
    bool requireAll = false,
  }) async {
    final q = query.trim();
    final reqKey = requirements.join(',');
    if (q.isEmpty && reqKey.isEmpty) {
      _remoteSearch = [];
      _lastRemoteQuery = '';
      notifyListeners();
      return const [];
    }
    final cacheKey = '$q|$reqKey|$nearest|$requireAll';
    if (cacheKey == _lastRemoteQuery && _remoteSearch.isNotEmpty) {
      return _remoteSearch;
    }
    isSearching = true;
    notifyListeners();
    try {
      final params = <String, String>{
        'q': q,
        if (reqKey.isNotEmpty) 'requirements': reqKey,
        if (requireAll) 'require_all': '1',
      };
      if (nearest || proximityEnabled) {
        params['lat'] = searchLat.toString();
        params['lng'] = searchLng.toString();
        params['radius_km'] = defaultRadiusKm.toString();
      }
      final data = await _api.get('/api/cards/search', query: params) as List<dynamic>;
      _remoteSearch = data.map((e) => ServiceCard.fromJson(e as Map<String, dynamic>)).toList();
      _lastRemoteQuery = cacheKey;
      error = null;
    } catch (e) {
      error = e.toString();
      final local = matchJobs(
        cards: searchCards(q),
        query: q,
        requirements: requirements,
        lat: nearest || proximityEnabled ? searchLat : null,
        lng: nearest || proximityEnabled ? searchLng : null,
      );
      _remoteSearch = local.map((m) => m.card).toList();
    } finally {
      isSearching = false;
      notifyListeners();
    }
    return _remoteSearch;
  }

  /// Perfiles sugeridos para la fila horizontal del home.
  List<StoryItem> get suggestedStories {
    if (_suggestedProfilesFromApi.isNotEmpty) {
      return _suggestedProfilesFromApi;
    }
    return FeedRanking.rankStories(_stories, _rankingSignals);
  }

  List<StoryItem> _suggestedProfilesFromApi = [];

  UserProfile _emptyProfile() => UserProfile(
        id: 0,
        name: 'Invitado',
        verified: false,
        avatar: 'users/user.jpg',
        contacts: 0,
        professions: const [],
        localContacts: 0,
        remoteContacts: 0,
        localAvailable: true,
        remoteAvailable: true,
        skills: const [],
        materials: const [],
        portfolio: const [],
        reviews: const [],
      );

  Future<void> loadProjects() async {
    final token = _tokenProvider();
    if (token == null || token.isEmpty) return;
    try {
      final projectsData = await _api.get('/api/projects', token: token) as List<dynamic>;
      _projects = projectsData.map((e) => ProjectItem.fromJson(e as Map<String, dynamic>)).toList();
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final token = _tokenProvider();
      final feedQuery = <String, String>{'personalized': '1'};
      if (proximityEnabled) {
        feedQuery['proximity'] = '1';
        feedQuery['lat'] = searchLat.toString();
        feedQuery['lng'] = searchLng.toString();
        feedQuery['radius_km'] = defaultRadiusKm.toString();
      }

      final cardsData = await _api.get('/api/cards') as List<dynamic>;
      final feedData = await _api.get(
        '/api/feed',
        token: token,
        query: token != null && token.isNotEmpty ? feedQuery : null,
      ) as List<dynamic>;
      final storiesData = await _api.get('/api/stories') as List<dynamic>;

      _cards = cardsData.map((e) => ServiceCard.fromJson(e as Map<String, dynamic>)).toList();
      _posts = feedData.map((e) => FeedPost.fromJson(e as Map<String, dynamic>)).toList();
      _stories = storiesData.map((e) => StoryItem.fromJson(e as Map<String, dynamic>)).toList();
      _suggestedProfilesFromApi = [];

      if (token != null && token.isNotEmpty) {
        final profileData = await _api.get('/api/users/me/profile', token: token) as Map<String, dynamic>;
        _profile = UserProfile.fromJson(profileData);
        _loadFeedSignals(profileData);
        try {
          final contactsData = await _api.get('/api/contacts', token: token) as List<dynamic>;
          _contactUserIds
            ..clear()
            ..addAll(
              contactsData
                  .map((c) => (c as Map<String, dynamic>)['peerId'] as num?)
                  .whereType<num>()
                  .map((id) => id.toInt()),
            );
        } catch (_) {}
        try {
          final suggestions = await _api.get('/api/suggestions/profiles', token: token) as List<dynamic>;
          _suggestedProfilesFromApi = suggestions.map((item) {
            final m = item as Map<String, dynamic>;
            final user = m['user'] as Map<String, dynamic>;
            return StoryItem(
              id: (m['story_id'] as num?)?.toInt() ?? user['id'] as int,
              user: SocialUser.fromJson(user),
              caption: m['caption'] as String? ?? '',
              imageKey: m['image_url'] as String? ?? 'background1.png',
              cardId: 0,
              cardTitle: m['card_title'] as String? ?? '',
              timestamp: DateTime.tryParse(m['timestamp'] as String? ?? '') ?? DateTime.now(),
              duration: 5,
            );
          }).toList();
        } catch (_) {}
        final projectsData = await _api.get('/api/projects', token: token) as List<dynamic>;
        _projects = projectsData.map((e) => ProjectItem.fromJson(e as Map<String, dynamic>)).toList();
        _followedProjectIds
          ..clear()
          ..addAll(_projects.where((p) => p.followed).map((p) => p.id));
        try {
          final following = await _api.get('/api/users/me/following', token: token) as Map<String, dynamic>;
          _followingUserIds
            ..clear()
            ..addAll((following['ids'] as List<dynamic>? ?? []).map((e) => (e as num).toInt()));
        } catch (_) {}
        _followedProjectIds
          ..clear()
          ..addAll(_projects.where((p) => p.followed).map((p) => p.id));
        try {
          final following = await _api.get('/api/users/me/following', token: token) as Map<String, dynamic>;
          _followingUserIds
            ..clear()
            ..addAll((following['ids'] as List<dynamic>? ?? []).map((e) => (e as num).toInt()));
        } catch (_) {}
      } else {
        _projects = [];
        try {
          final demo = await _api.get('/api/users/1/profile') as Map<String, dynamic>;
          _profile = UserProfile.fromJson(demo);
        } catch (_) {
          _profile = _emptyProfile();
        }
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<ServiceCard> searchCards(String query, {bool? proximityOnly}) {
    final q = query.trim().toLowerCase();
    var list = cards;

    if (q.isNotEmpty) {
      final matchedCategories = categoriesMatchingQuery(q);
      final categoryLabels = matchedCategories.map((c) => c.label.toLowerCase()).toSet();
      final categoryGroups = matchedCategories.map((c) => c.group.toLowerCase()).toSet();

      list = cards.where((c) {
        final title = c.title.toLowerCase();
        final desc = c.description.toLowerCase();
        final cat = c.category.toLowerCase();
        if (title.contains(q) || desc.contains(q) || cat.contains(q)) return true;
        if (categoryLabels.any((label) => title.contains(label) || desc.contains(label) || cat.contains(label))) {
          return true;
        }
        if (categoryGroups.any((g) => cat.contains(g) || title.contains(g))) return true;
        for (final mc in matchedCategories) {
          if (mc.searchTerms.any((t) => title.contains(t) || desc.contains(t) || cat.contains(t))) {
            return true;
          }
        }
        return false;
      }).toList();
    }

    final useProximity = proximityOnly ?? proximityEnabled;
    if (useProximity) {
      list = filterByProximity<ServiceCard>(
        items: list,
        centerLat: searchLat,
        centerLng: searchLng,
        radiusKm: defaultRadiusKm,
        readLat: (c) => c.lat,
        readLng: (c) => c.lng,
      );
    }
    return list;
  }

  List<FeedPost> postsNearby({bool? proximityOnly}) {
    final useProximity = proximityOnly ?? proximityEnabled;
    if (!useProximity) return posts;
    return filterByProximity<FeedPost>(
      items: posts,
      centerLat: searchLat,
      centerLng: searchLng,
      radiusKm: defaultRadiusKm,
      readLat: (p) => p.lat,
      readLng: (p) => p.lng,
    );
  }

  double? distanceKmTo(ServiceCard card) {
    if (!card.hasCoords) return null;
    return ProximityBounds.approximateKm(
      fromLat: searchLat,
      fromLng: searchLng,
      toLat: card.lat!,
      toLng: card.lng!,
    );
  }

  ServiceCard? cardById(int id) {
    try {
      return cards.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> toggleLike(int postId) async {
    try {
      final token = _tokenProvider();
      final data = await _api.post('/api/feed/$postId/like', token: token) as Map<String, dynamic>;
      final updated = FeedPost.fromJson(data);
      _recordEngagement(updated);
      _updatePost(updated);
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleSave(int postId) async {
    try {
      final token = _tokenProvider();
      final data = await _api.post('/api/feed/$postId/save', token: token) as Map<String, dynamic>;
      final updated = FeedPost.fromJson(data);
      _recordEngagement(updated);
      _updatePost(updated);
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  final Set<int> _followingUserIds = {};
  final Set<int> _followedProjectIds = {};

  bool isFollowingUser(int userId) => _followingUserIds.contains(userId);
  bool isFollowingProject(int projectId) => _followedProjectIds.contains(projectId);

  void toggleFollow(int postId) {
    final i = _posts.indexWhere((p) => p.id == postId);
    if (i < 0) return;
    final userId = _posts[i].user.id;
    toggleFollowUser(userId);
  }

  Future<void> toggleFollowUser(int userId) async {
    final token = _tokenProvider();
    if (token == null || token.isEmpty) {
      error = 'Inicia sesión para seguir personas';
      notifyListeners();
      return;
    }
    try {
      final data = await _api.post('/api/users/$userId/follow', token: token) as Map<String, dynamic>;
      final following = data['following'] as bool? ?? !_followingUserIds.contains(userId);
      if (following) {
        _followingUserIds.add(userId);
      } else {
        _followingUserIds.remove(userId);
      }
      for (var i = 0; i < _posts.length; i++) {
        if (_posts[i].user.id == userId) {
          _posts[i] = _posts[i].copyWith(user: _posts[i].user.copyWith(following: following));
        }
      }
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleFollowProject(int projectId) async {
    final token = _tokenProvider();
    if (token == null || token.isEmpty) {
      error = 'Inicia sesión para seguir proyectos';
      notifyListeners();
      return;
    }
    try {
      final data = await _api.post('/api/projects/$projectId/follow', token: token) as Map<String, dynamic>;
      final followed = data['followed'] as bool? ?? !_followedProjectIds.contains(projectId);
      if (followed) {
        _followedProjectIds.add(projectId);
      } else {
        _followedProjectIds.remove(projectId);
      }
      final i = _projects.indexWhere((p) => p.id == projectId);
      if (i >= 0) {
        _projects[i] = _projects[i].copyWith(followed: followed);
      }
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<ProjectItem> createProject({
    required String name,
    required String description,
    String partnerName = '',
    bool publishToFeed = true,
    List<String> requirements = const [],
  }) async {
    final token = _tokenProvider();
    if (token == null || token.isEmpty) {
      throw Exception('Inicia sesión para crear un proyecto');
    }
    final data = await _api.post(
      '/api/projects',
      token: token,
      body: {
        'name': name,
        'description': description,
        'partnerName': partnerName,
        'publishToFeed': publishToFeed,
        'requirements': requirements,
      },
    ) as Map<String, dynamic>;
    final project = ProjectItem.fromJson(data);
    _projects.insert(0, project);
    if (publishToFeed) {
      await refresh();
    } else {
      notifyListeners();
    }
    return project;
  }

  void _replaceProject(ProjectItem project) {
    final i = _projects.indexWhere((p) => p.id == project.id);
    if (i >= 0) {
      _projects[i] = project;
    } else {
      _projects.insert(0, project);
    }
    notifyListeners();
  }

  Future<ProjectItem?> fetchProject(int projectId) async {
    final token = _tokenProvider();
    if (token == null || token.isEmpty) return null;
    try {
      final data = await _api.get('/api/projects/$projectId', token: token) as Map<String, dynamic>;
      final project = ProjectItem.fromJson(data);
      _replaceProject(project);
      return project;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<ProjectItem?> updateProjectDelivery(int projectId, String status) async {
    final token = _tokenProvider();
    if (token == null || token.isEmpty) {
      throw Exception('Inicia sesión para actualizar el proyecto');
    }
    final data = await _api.patch(
      '/api/projects/$projectId',
      token: token,
      body: {'status': status},
    ) as Map<String, dynamic>;
    final project = ProjectItem.fromJson(data);
    _replaceProject(project);
    return project;
  }

  Future<ProjectItem?> submitProjectDelivery({
    required int projectId,
    required String message,
    String image = 'background4.png',
  }) async {
    final token = _tokenProvider();
    if (token == null || token.isEmpty) {
      throw Exception('Inicia sesión para registrar la entrega');
    }
    final data = await _api.post(
      '/api/projects/$projectId/delivery',
      token: token,
      body: {'message': message, 'image': image},
    ) as Map<String, dynamic>;
    final project = ProjectItem.fromJson(data);
    _replaceProject(project);
    return project;
  }

  Future<StoryItem> createStory({
    required String caption,
    String imageKey = 'background1.png',
    String cardTitle = '',
  }) async {
    final token = _tokenProvider();
    if (token == null || token.isEmpty) {
      throw Exception('Inicia sesión para publicar una historia');
    }
    final data = await _api.post(
      '/api/stories',
      token: token,
      body: {
        'caption': caption,
        'image_url': imageKey,
        'card_title': cardTitle,
      },
    ) as Map<String, dynamic>;
    final story = StoryItem.fromJson(data);
    _stories.insert(0, story);
    notifyListeners();
    return story;
  }

  bool isTrusted(int userId) => _trustedUserIds.contains(userId);

  Future<void> toggleTrust(int userId) async {
    if (_trustedUserIds.contains(userId)) {
      _trustedUserIds.remove(userId);
    } else {
      _trustedUserIds.add(userId);
    }
    notifyListeners();
    await _persistFeedSignals();
  }

  void _loadFeedSignals(Map<String, dynamic> profileJson) {
    final fs = profileJson['feedSignals'];
    if (fs is! Map<String, dynamic>) return;
    _trustedUserIds
      ..clear()
      ..addAll(
        (fs['trustedUserIds'] as List<dynamic>? ?? []).map((e) => (e as num).toInt()),
      );
    _categoryAffinity
      ..clear()
      ..addAll(
        (fs['categoryAffinity'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        ),
      );
  }

  void _recordEngagement(FeedPost post) {
    if (post.liked || post.saved) {
      _bumpCategoryAffinity('${post.cardTitle} ${post.category} ${post.description}');
      _persistFeedSignals();
    }
  }

  void _bumpCategoryAffinity(String text) {
    final tokens = text.toLowerCase().split(RegExp(r'[^a-záéíóúñ]+')).where((t) => t.length > 3);
    for (final token in tokens.take(6)) {
      _categoryAffinity[token] = (_categoryAffinity[token] ?? 0) + 1;
    }
  }

  Future<void> _persistFeedSignals() async {
    final token = _tokenProvider();
    if (token == null || token.isEmpty || profile.id == 0) return;
    try {
      await _api.put(
        '/api/users/me/profile',
        token: token,
        body: {
          'feedSignals': {
            'trustedUserIds': _trustedUserIds.toList(),
            'categoryAffinity': _categoryAffinity,
          },
        },
      );
    } catch (_) {}
  }

  Future<void> markStoryViewed(int storyId) async {
    final i = _stories.indexWhere((s) => s.id == storyId);
    if (i < 0) return;
    _stories[i] = _stories[i].copyWith(viewed: true);
    notifyListeners();
    try {
      await _api.post('/api/stories/$storyId/view');
    } catch (_) {}
  }

  Future<void> setLocalAvailable(bool value) async {
    final p = profile;
    if (p.id == 0) return;
    if (!p.verified && value) {
      error = 'Verifica tu cuenta para trabajos presenciales';
      notifyListeners();
      return;
    }
    _profile = p.copyWith(localAvailable: value);
    notifyListeners();
    try {
      final data = await _api.put(
        '/api/users/${p.id}/profile/availability',
        body: {'localAvailable': value, 'remoteAvailable': p.remoteAvailable},
      ) as Map<String, dynamic>;
      _profile = UserProfile.fromJson(data);
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> setRemoteAvailable(bool value) async {
    final p = profile;
    if (p.id == 0) return;
    _profile = p.copyWith(remoteAvailable: value);
    notifyListeners();
    try {
      final data = await _api.put(
        '/api/users/${p.id}/profile/availability',
        body: {'localAvailable': p.localAvailable, 'remoteAvailable': value},
      ) as Map<String, dynamic>;
      _profile = UserProfile.fromJson(data);
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<FeedPost> createPost({
    required String description,
    String? location,
    int cost = 1,
    String costType = 'favor',
    int? cardId,
    String? cardTitle,
    String? category,
    String imageKey = 'background1.png',
  }) async {
    final token = _tokenProvider();
    final data = await _api.post(
      '/api/feed',
      token: token,
      body: {
        'description': description,
        'image_url': imageKey,
        'cost': cost,
        'cost_type': costType,
        if (cardId != null) 'card_id': cardId,
        if (cardTitle != null) 'card_title': cardTitle,
        if (location != null && location.isNotEmpty) 'location': location,
        if (category != null && category.isNotEmpty) 'category': category,
      },
    ) as Map<String, dynamic>;
    final post = FeedPost.fromJson(data);
    _posts.insert(0, post);
    notifyListeners();
    return post;
  }

  Future<void> addPortfolioItem({
    required String imageKey,
    required String description,
    required String tag,
    required int priceMxn,
    String location = 'México',
    String? category,
    String? profession,
  }) async {
    final token = _tokenProvider();
    if (token == null || token.isEmpty) throw Exception('Inicia sesión para publicar');
    final data = await _api.post(
      '/api/users/me/portfolio',
      token: token,
      body: {
        'image_url': imageKey,
        'description': description,
        'tag': tag,
        'price_mxn': priceMxn,
        'location': location,
        if (category != null && category.isNotEmpty) 'category': category,
        if (profession != null && profession.isNotEmpty) 'profession': profession,
      },
    ) as Map<String, dynamic>;
    _profile = UserProfile.fromJson(data);
    notifyListeners();
  }

  Future<void> updateProfessions(List<String> professions) async {
    final token = _tokenProvider();
    if (token == null || token.isEmpty) return;
    final data = await _api.put(
      '/api/users/me/profile',
      token: token,
      body: {'professions': professions},
    ) as Map<String, dynamic>;
    _profile = UserProfile.fromJson(data);
    notifyListeners();
  }

  Future<void> _reloadProfile() async {
    final token = _tokenProvider();
    if (token == null) return;
    final data = await _api.get('/api/users/me/profile', token: token) as Map<String, dynamic>;
    _profile = UserProfile.fromJson(data);
    notifyListeners();
  }

  Future<void> addSkill(String name) async {
    final p = profile;
    final token = _tokenProvider();
    if (token == null || p.id == 0) return;
    await _api.post('/api/users/${p.id}/profile/skills', token: token, body: {'name': name});
    await _reloadProfile();
  }

  Future<void> updateSkill(int id, String name) async {
    final p = profile;
    final token = _tokenProvider();
    if (token == null || p.id == 0) return;
    await _api.put('/api/users/${p.id}/profile/skills/$id', token: token, body: {'name': name});
    await _reloadProfile();
  }

  Future<void> addMaterial(String name) async {
    final p = profile;
    final token = _tokenProvider();
    if (token == null || p.id == 0) return;
    await _api.post('/api/users/${p.id}/profile/materials', token: token, body: {'name': name});
    await _reloadProfile();
  }

  Future<void> updateMaterial(int id, String name) async {
    final p = profile;
    final token = _tokenProvider();
    if (token == null || p.id == 0) return;
    await _api.put('/api/users/${p.id}/profile/materials/$id', token: token, body: {'name': name});
    await _reloadProfile();
  }

  void _updatePost(FeedPost updated) {
    final i = _posts.indexWhere((p) => p.id == updated.id);
    if (i >= 0) {
      _posts[i] = updated;
      notifyListeners();
    }
  }
}
