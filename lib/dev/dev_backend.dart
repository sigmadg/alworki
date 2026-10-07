import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// En desarrollo (escritorio), intenta levantar la API si no responde.
Future<void> ensureDevBackendRunning() async {
  const autoStart = bool.fromEnvironment('AUTO_START_BACKEND', defaultValue: true);
  if (!kDebugMode || kIsWeb || !autoStart) return;
  if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) return;

  final base = resolveApiBaseUrl();
  if (!_isLocalhost(base)) return;

  if (await _healthOk(base)) return;

  final root = Directory.current.path;
  final script = '$root/scripts/start_backend.sh';
  if (!File(script).existsSync()) return;

  debugPrint('Alworki: iniciando API de desarrollo...');
  final result = await Process.run('bash', [script], runInShell: true);
  if (result.exitCode != 0) {
    debugPrint('Alworki: no se pudo iniciar la API (${result.stderr})');
    return;
  }

  for (var i = 0; i < 40; i++) {
    if (await _healthOk(base)) {
      debugPrint('Alworki: API lista en $base');
      return;
    }
    await Future.delayed(const Duration(milliseconds: 250));
  }
}

bool _isLocalhost(String url) =>
    url.contains('127.0.0.1') || url.contains('localhost');

Future<bool> _healthOk(String base) async {
  try {
    final res = await http
        .get(Uri.parse('$base/health'))
        .timeout(const Duration(seconds: 2));
    return res.statusCode == 200;
  } catch (_) {
    return false;
  }
}
