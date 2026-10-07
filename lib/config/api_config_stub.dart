String resolveApiBaseUrlImpl(String fromEnvironment) {
  final t = fromEnvironment.trim();
  if (t.isNotEmpty) return t.replaceAll(RegExp(r'/$'), '');
  return 'http://localhost:5002';
}
