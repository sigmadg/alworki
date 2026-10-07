import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alworki_auto/services/werkzeug_password.dart';

void main() {
  test('verifies werkzeug 2.3 pbkdf2 hash from Python', () async {
    const pwhash =
        'pbkdf2:sha256:600000\$OGwZj4pSXbakucM6\$814182bd6b610768d509457f86b895e6eeb2b967c3d92ff77f75d382c245eb1c';
    expect(await WerkzeugPassword.verify(pwhash, 'secret'), isTrue);
    expect(await WerkzeugPassword.verify(pwhash, 'wrong'), isFalse);
  });

  test('generate + verify roundtrip', () async {
    final h = await WerkzeugPassword.hash('miClave123');
    expect(h.startsWith('pbkdf2:sha256:600000\$'), isTrue);
    expect(await WerkzeugPassword.verify(h, 'miClave123'), isTrue);
  });

  test('raw pbkdf2 matches Python sample', () async {
    final algo = Pbkdf2.hmacSha256(iterations: 600000, bits: 256);
    final key = await algo.deriveKeyFromPassword(
      password: 'secret',
      nonce: utf8.encode('OGwZj4pSXbakucM6'),
    );
    final bytes = await key.extractBytes();
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    expect(
      hex,
      '814182bd6b610768d509457f86b895e6eeb2b967c3d92ff77f75d382c245eb1c',
    );
  });
}
