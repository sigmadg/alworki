import 'package:flutter/foundation.dart';

import 'api_client.dart';

class WalletBalance {
  const WalletBalance({required this.redCoins, required this.blueCoins, required this.quoteCost});

  final int redCoins;
  final int blueCoins;
  final int quoteCost;

  factory WalletBalance.fromJson(Map<String, dynamic> json) => WalletBalance(
        redCoins: (json['redCoins'] as num?)?.toInt() ?? 0,
        blueCoins: (json['blueCoins'] as num?)?.toInt() ?? 0,
        quoteCost: (json['quoteCost'] as num?)?.toInt() ?? 5,
      );

  bool hasEnoughRed(int cost) => redCoins >= cost;
  bool hasEnoughBlue(int cost) => blueCoins >= cost;
}

class WalletService extends ChangeNotifier {
  WalletService(this._api, this._tokenProvider);

  final ApiClient _api;
  final String? Function() _tokenProvider;

  WalletBalance _balance = const WalletBalance(redCoins: 2, blueCoins: 1, quoteCost: 5);
  bool isLoading = false;
  String? error;

  WalletBalance get balance => _balance;

  Future<void> load() async {
    final token = _tokenProvider();
    if (token == null || token.isEmpty) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _api.get('/api/users/me/wallet', token: token) as Map<String, dynamic>;
      _balance = WalletBalance.fromJson(data);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> purchaseBlueCoins({int amount = 10, int? amountMxn}) async {
    final token = _tokenProvider();
    if (token == null) return false;
    try {
      final body = amountMxn != null ? {'amount_mxn': amountMxn} : {'amount': amount};
      final data = await _api.post(
        '/api/wallet/purchase-blue',
        token: token,
        body: body,
      ) as Map<String, dynamic>;
      _balance = WalletBalance.fromJson(data);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void applyBalance(WalletBalance b) {
    _balance = b;
    notifyListeners();
  }
}
