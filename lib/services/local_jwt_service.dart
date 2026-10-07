import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// Misma idea que `Ejemplo/AlworkiAuto/Backend/auth/jwt_manager.py` (HS256, access + refresh).
class LocalJwtService {
  LocalJwtService._();

  static const String _secret = String.fromEnvironment(
    'JWT_SECRET',
    defaultValue: 'alworki-auto-secret-key-2024',
  );

  static const Duration accessExpires = Duration(hours: 24);
  static const Duration refreshExpires = Duration(days: 30);

  static SecretKey get _key => SecretKey(_secret);

  static Map<String, dynamic> generateTokens(
    int userId, {
    required String email,
    required String name,
    String role = 'user',
  }) {
    final ts = DateTime.now().toUtc().millisecondsSinceEpoch;
    final accessPayload = <String, dynamic>{
      'user_id': userId,
      'type': 'access',
      'jti': 'access_${userId}_$ts',
      'email': email,
      'name': name,
      'role': role,
    };
    final refreshPayload = <String, dynamic>{
      'user_id': userId,
      'type': 'refresh',
      'jti': 'refresh_${userId}_$ts',
      'email': email,
      'name': name,
      'role': role,
    };

    final accessToken = JWT(accessPayload).sign(
      _key,
      algorithm: JWTAlgorithm.HS256,
      expiresIn: accessExpires,
    );
    final refreshToken = JWT(refreshPayload).sign(
      _key,
      algorithm: JWTAlgorithm.HS256,
      expiresIn: refreshExpires,
    );

    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': accessExpires.inSeconds,
      'token_type': 'Bearer',
    };
  }

  static bool verifyAccessToken(String token) {
    try {
      final jwt = JWT.verify(token, _key);
      final p = jwt.payload;
      if (p is! Map) return false;
      return p['type'] == 'access';
    } catch (_) {
      return false;
    }
  }

  /// Devuelve solo `access_token` + metadatos, como el Flask `refresh-token`.
  static Map<String, dynamic>? refreshAccessToken(String refreshToken) {
    try {
      final jwt = JWT.verify(refreshToken, _key);
      final p = jwt.payload;
      if (p is! Map<String, dynamic>) return null;
      if (p['type'] != 'refresh') return null;

      final rawId = p['user_id'];
      if (rawId == null) return null;
      final id = rawId is int ? rawId : (rawId as num).toInt();

      final accessPayload = <String, dynamic>{
        'user_id': id,
        'type': 'access',
        'jti': 'access_${id}_${DateTime.now().toUtc().millisecondsSinceEpoch}',
        if (p['email'] != null) 'email': p['email'],
        if (p['name'] != null) 'name': p['name'],
        if (p['role'] != null) 'role': p['role'],
      };

      final accessToken = JWT(accessPayload).sign(
        _key,
        algorithm: JWTAlgorithm.HS256,
        expiresIn: accessExpires,
      );

      return {
        'access_token': accessToken,
        'expires_in': accessExpires.inSeconds,
        'token_type': 'Bearer',
      };
    } catch (_) {
      return null;
    }
  }
}
