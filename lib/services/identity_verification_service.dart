import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_client.dart';

class IdentityVerificationResult {
  const IdentityVerificationResult({
    required this.status,
    required this.approved,
    required this.messages,
    this.curp,
    this.faceMatch = false,
    this.disclaimer = '',
  });

  final String status;
  final bool approved;
  final List<String> messages;
  final String? curp;
  final bool faceMatch;
  final String disclaimer;

  factory IdentityVerificationResult.fromJson(Map<String, dynamic> json) => IdentityVerificationResult(
        status: json['status'] as String? ?? 'pending',
        approved: json['approved'] as bool? ?? false,
        messages: (json['messages'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        curp: json['curp'] as String?,
        faceMatch: (json['face'] as Map?)?['match'] as bool? ?? false,
        disclaimer: json['disclaimer'] as String? ?? '',
      );
}

class IdentityVerificationService {
  IdentityVerificationService(this._api, this._tokenProvider);

  final ApiClient _api;
  final String? Function() _tokenProvider;

  Future<Map<String, dynamic>> getStatus() async {
    final token = _tokenProvider();
    if (token == null || token.isEmpty) throw Exception('Inicia sesión');
    return await _api.get('/api/users/me/identity/status', token: token) as Map<String, dynamic>;
  }

  Future<IdentityVerificationResult> submit({
    required Uint8List ineFront,
    required Uint8List selfie,
    Uint8List? ineBack,
    String? curp,
  }) async {
    final token = _tokenProvider();
    if (token == null || token.isEmpty) throw Exception('Inicia sesión');

    final files = <String, http.MultipartFile>{
      'ine_front': http.MultipartFile.fromBytes('ine_front', ineFront, filename: 'ine_front.jpg'),
      'selfie': http.MultipartFile.fromBytes('selfie', selfie, filename: 'selfie.jpg'),
    };
    if (ineBack != null) {
      files['ine_back'] = http.MultipartFile.fromBytes('ine_back', ineBack, filename: 'ine_back.jpg');
    }

    final fields = <String, String>{};
    if (curp != null && curp.trim().isNotEmpty) {
      fields['curp'] = curp.trim().toUpperCase();
    }

    final data = await _api.postMultipart(
      '/api/users/me/identity/verify',
      token: token,
      fields: fields,
      files: files,
    ) as Map<String, dynamic>;

    return IdentityVerificationResult.fromJson(data);
  }
}
