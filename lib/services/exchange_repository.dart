import 'package:flutter/foundation.dart';

import '../models/exchange_request.dart';
import 'api_client.dart';

/// Solicitudes de intercambio contra `POST/GET /api/exchange` (requiere JWT).
class ExchangeRepository extends ChangeNotifier {
  ExchangeRepository(this._api, this._tokenProvider);

  final ApiClient _api;
  final String? Function() _tokenProvider;

  final List<ExchangeRequest> _items = [];
  bool isLoading = false;
  String? error;

  List<ExchangeRequest> get items => List.unmodifiable(_items);

  Future<void> load() async {
    final token = _tokenProvider();
    if (token == null || token.isEmpty) {
      _items.clear();
      error = 'Inicia sesión para ver tus intercambios';
      notifyListeners();
      return;
    }

    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _api.get('/api/exchange', token: token) as List<dynamic>;
      _items
        ..clear()
        ..addAll(data.map((e) => ExchangeRequest.fromJson(e as Map<String, dynamic>)));
    } catch (e) {
      error = e.toString();
      _items.clear();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<ExchangeRequest?> create({
    required String title,
    required String description,
    int? postId,
    int? cardId,
    String? offerTitle,
    int? targetUserId,
  }) async {
    final token = _tokenProvider();
    if (token == null || token.isEmpty) {
      error = 'Inicia sesión para crear intercambios';
      notifyListeners();
      return null;
    }

    try {
      final data = await _api.post(
        '/api/exchange',
        token: token,
        body: {
          'title': title,
          'description': description,
          if (postId != null) 'postId': postId,
          if (cardId != null) 'cardId': cardId,
          if (offerTitle != null) 'offerTitle': offerTitle,
          if (targetUserId != null) 'targetUserId': targetUserId,
        },
      ) as Map<String, dynamic>;
      final req = ExchangeRequest.fromJson(data);
      _items.insert(0, req);
      notifyListeners();
      return req;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<ExchangeRequest?> createFromPost({
    required int postId,
    required String cardTitle,
    required String authorName,
    required int cardId,
    int? targetUserId,
  }) =>
      create(
        title: 'Coincidencia con $authorName',
        description: 'Intercambio propuesto por la publicación «$cardTitle».',
        postId: postId,
        cardId: cardId,
        offerTitle: cardTitle,
        targetUserId: targetUserId,
      );

  Future<ExchangeRequest?> updateStatus(int id, ExchangeStatus status) async {
    final token = _tokenProvider();
    if (token == null || token.isEmpty) {
      error = 'Inicia sesión para gestionar intercambios';
      notifyListeners();
      return null;
    }
    try {
      final data = await _api.patch(
        '/api/exchange/$id',
        token: token,
        body: {'status': status.name},
      ) as Map<String, dynamic>;
      final updated = ExchangeRequest.fromJson(data);
      final i = _items.indexWhere((e) => e.id == id);
      if (i >= 0) {
        _items[i] = updated;
      } else {
        _items.insert(0, updated);
      }
      notifyListeners();
      return updated;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
