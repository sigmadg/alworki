import 'dart:io' show Platform;

String resolveApiBaseUrlImpl(String fromEnvironment) {
  final t = fromEnvironment.trim();
  if (t.isNotEmpty) return t.replaceAll(RegExp(r'/$'), '');
  if (Platform.isAndroid) return 'http://10.0.2.2:5002';
  return 'http://127.0.0.1:5002';
}
