import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class AuthApiException implements Exception {
  AuthApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Cliente HTTP contra `Backend/app_unified.py` (`/api/auth/*`).
class AuthApi {
  AuthApi();

  Uri _u(String path) => Uri.parse(authPath(path));

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      _u('/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );
    final body = _decodeJson(res);
    if (res.statusCode >= 400) {
      throw AuthApiException(body['error']?.toString() ?? 'Error de login');
    }
    return body;
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstname,
    required String lastname,
  }) async {
    final res = await http.post(
      _u('/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        'firstname': firstname.trim(),
        'lastname': lastname.trim(),
      }),
    );
    final body = _decodeJson(res);
    if (res.statusCode >= 400) {
      throw AuthApiException(
        body['error']?.toString() ?? body['message']?.toString() ?? 'Error al registrarse',
      );
    }
  }

  Future<bool> verifyToken(String accessToken) async {
    try {
      final res = await http
          .get(
            _u('/verify-token'),
            headers: {'Authorization': 'Bearer $accessToken'},
          )
          .timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout(String accessToken) async {
    try {
      await http.post(
        _u('/logout'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> refreshAccessToken(String refreshToken) async {
    try {
      final res = await http
          .post(
            _u('/refresh-token'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode >= 400) return null;
      return _decodeJson(res);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _decodeJson(http.Response res) {
    try {
      if (res.body.isEmpty) return {};
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
