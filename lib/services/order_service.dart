import 'package:flutter/foundation.dart';

import '../models/service_order.dart';
import 'api_client.dart';

class OrderService extends ChangeNotifier {
  OrderService(this._api, this._tokenProvider);

  final ApiClient _api;
  final String? Function() _tokenProvider;

  List<ServiceOrder> _orders = [];
  bool isLoading = false;
  String? error;

  List<ServiceOrder> get orders => _orders;

  Future<void> loadOrders() async {
    final token = _tokenProvider();
    if (token == null) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _api.get('/api/orders', token: token) as List<dynamic>;
      _orders = data.map((e) => ServiceOrder.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<ServiceOrder?> fetchOrder(String tracking) async {
    final token = _tokenProvider();
    if (token == null) return null;
    try {
      final data = await _api.get('/api/orders/$tracking', token: token) as Map<String, dynamic>;
      final order = ServiceOrder.fromJson(data);
      final idx = _orders.indexWhere((o) => o.trackingNumber == tracking);
      if (idx >= 0) {
        _orders[idx] = order;
      } else {
        _orders.insert(0, order);
      }
      notifyListeners();
      return order;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<ServiceOrder?> submitDelivery({
    required String tracking,
    required String message,
    String image = 'background4.png',
  }) async {
    final token = _tokenProvider();
    if (token == null) return null;
    try {
      final data = await _api.post(
        '/api/orders/$tracking/delivery',
        token: token,
        body: {'message': message, 'image': image},
      ) as Map<String, dynamic>;
      final order = ServiceOrder.fromJson(data);
      final idx = _orders.indexWhere((o) => o.trackingNumber == tracking);
      if (idx >= 0) {
        _orders[idx] = order;
      }
      notifyListeners();
      return order;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
