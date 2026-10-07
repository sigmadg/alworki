import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// Compatible con [Werkzeug 2.3](https://github.com/pallets/werkzeug/blob/2.3.7/src/werkzeug/security.py)
/// (`pbkdf2:sha256:600000$…$…`).
class WerkzeugPassword {
  WerkzeugPassword._();

  static const _saltChars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static const _defaultIterations = 600000;
  static final _pbkdf2 = Pbkdf2.hmacSha256(
    iterations: _defaultIterations,
    bits: 256,
  );

  static String _genSalt(int length) {
    final r = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => _saltChars.codeUnitAt(r.nextInt(_saltChars.length)),
      ),
    );
  }

  static Future<String> hash(String password) async {
    final salt = _genSalt(16);
    final hex = await _pbkdf2Hex(password, salt);
    return 'pbkdf2:sha256:$_defaultIterations\$$salt\$$hex';
  }

  static Future<bool> verify(String pwhash, String password) async {
    final parts = pwhash.split(r'$');
    if (parts.length != 3) return false;
    final method = parts[0];
    final salt = parts[1];
    final hashval = parts[2];
    final computed = await _hashInternal(method, salt, password);
    if (computed == null) return false;
    return _constantTimeEquals(computed, hashval);
  }

  static Future<String?> _hashInternal(
    String method,
    String saltStr,
    String password,
  ) async {
    if (method.startsWith('pbkdf2:')) {
      final segs = method.split(':');
      if (segs.length < 2 || segs[1] != 'sha256') return null;
      final iterations = segs.length >= 3 ? int.tryParse(segs[2]) : null;
      if (iterations == null) return null;
      final algo = Pbkdf2.hmacSha256(iterations: iterations, bits: 256);
      final key = await algo.deriveKeyFromPassword(
        password: password,
        nonce: utf8.encode(saltStr),
      );
      final bytes = await key.extractBytes();
      return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    }
    return null;
  }

  static Future<String> _pbkdf2Hex(String password, String saltStr) async {
    final key = await _pbkdf2.deriveKeyFromPassword(
      password: password,
      nonce: utf8.encode(saltStr),
    );
    final bytes = await key.extractBytes();
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var r = 0;
    for (var i = 0; i < a.length; i++) {
      r |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return r == 0;
  }
}
