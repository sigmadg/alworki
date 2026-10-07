import 'api_client.dart';

class ProfileActionsService {
  ProfileActionsService(this._api, this._tokenProvider);

  final ApiClient _api;
  final String? Function() _tokenProvider;

  Future<Map<String, dynamic>> createQuote({
    required int providerId,
    required List<String> services,
    required List<String> materials,
    required String date,
    required String timeSlot,
    String? payWith,
    int coinCost = 5,
    String? contactFirstName,
    String? contactLastName,
    String? contactEmail,
    String? providerName,
  }) async {
    final data = await _api.post(
      '/api/quotes',
      token: _tokenProvider(),
      body: {
        'provider_id': providerId,
        'services': services,
        'materials': materials,
        'quote_date': date,
        'time_slot': timeSlot,
        if (payWith != null) 'pay_with': payWith,
        'coin_cost': coinCost,
        if (contactFirstName != null) 'contact_first_name': contactFirstName,
        if (contactLastName != null) 'contact_last_name': contactLastName,
        if (contactEmail != null) 'contact_email': contactEmail,
        if (providerName != null) 'provider_name': providerName,
      },
    );
    return data as Map<String, dynamic>;
  }

  Future<void> createReport({
    required String trackingNumber,
    required String action,
    int? providerId,
  }) async {
    await _api.post(
      '/api/reports',
      token: _tokenProvider(),
      body: {
        'tracking_number': trackingNumber,
        'action': action,
        if (providerId != null) 'provider_id': providerId,
      },
    );
  }

  Future<void> createReview({
    required int providerId,
    required String trackingNumber,
    required String text,
    int rating = 5,
    String? serviceTitle,
  }) async {
    await _api.post(
      '/api/users/$providerId/reviews',
      token: _tokenProvider(),
      body: {
        'text': text,
        'rating': rating,
        'service_title': serviceTitle ?? trackingNumber,
      },
    );
  }

  Future<String> shareProfile(int userId) async {
    final data = await _api.post('/api/users/$userId/profile/share') as Map<String, dynamic>;
    return data['share_url'] as String? ?? 'https://alworki.com/profile/$userId';
  }
}
