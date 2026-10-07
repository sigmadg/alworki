import 'api_config_stub.dart'
    if (dart.library.io) 'api_config_io.dart' as platform_impl;

String resolveApiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  return platform_impl.resolveApiBaseUrlImpl(fromEnv);
}

String authPath(String segment) => '${resolveApiBaseUrl()}/api/auth$segment';
