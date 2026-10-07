import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({String? baseUrl, Duration? timeout})
      : _base = baseUrl ?? resolveApiBaseUrl(),
        _timeout = timeout ?? const Duration(seconds: 10);

  final String _base;
  final Duration _timeout;

  Map<String, String> _headers({String? token}) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path, [Map<String, String>? query]) {
    final u = Uri.parse('$_base$path');
    if (query == null || query.isEmpty) return u;
    return u.replace(queryParameters: query);
  }

  Future<dynamic> get(String path, {String? token, Map<String, String>? query}) async {
    final res = await http.get(_uri(path, query), headers: _headers(token: token)).timeout(_timeout);
    return _decode(res);
  }

  Future<dynamic> post(String path, {String? token, Object? body}) async {
    final res = await http
        .post(
          _uri(path),
          headers: _headers(token: token),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(_timeout);
    return _decode(res);
  }

  Future<dynamic> patch(String path, {String? token, Object? body}) async {
    final res = await http
        .patch(
          _uri(path),
          headers: _headers(token: token),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(_timeout);
    return _decode(res);
  }

  Future<dynamic> put(String path, {String? token, Object? body}) async {
    final res = await http
        .put(
          _uri(path),
          headers: _headers(token: token),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(_timeout);
    return _decode(res);
  }

  Future<dynamic> delete(String path, {String? token}) async {
    final res = await http.delete(_uri(path), headers: _headers(token: token)).timeout(_timeout);
    return _decode(res);
  }

  /// Subida multipart (verificación de identidad, etc.).
  Future<dynamic> postMultipart(
    String path, {
    required String token,
    required Map<String, String> fields,
    required Map<String, http.MultipartFile> files,
    Duration? timeout,
  }) async {
    final req = http.MultipartRequest('POST', _uri(path));
    req.headers['Accept'] = 'application/json';
    req.headers['Authorization'] = 'Bearer $token';
    req.fields.addAll(fields);
    req.files.addAll(files.values);
    final streamed = await req.send().timeout(timeout ?? const Duration(seconds: 90));
    final res = await http.Response.fromStream(streamed);
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    dynamic parsed;
    if (res.body.isNotEmpty) {
      parsed = jsonDecode(res.body);
    }
    if (res.statusCode >= 400) {
      final err = parsed is Map ? (parsed['error'] ?? parsed['message']) : null;
      throw ApiException(err?.toString() ?? 'Error ${res.statusCode}', statusCode: res.statusCode);
    }
    return parsed;
  }
}
