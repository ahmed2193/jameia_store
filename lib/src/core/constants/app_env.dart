/// Build-time environment, injected with `--dart-define` so no host / stage
/// literal ever lives in feature code.
///
/// ```sh
/// # Android emulator → the host machine's localhost
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000
/// # Release build
/// flutter build apk --dart-define=API_BASE_URL=https://api.jm3eia.com
/// ```
///
/// Backend reference: https://docs.jm3eia.store/developers/getting-started.html
abstract final class AppEnv {
  /// Public (customer) API origin — scheme + host + port, no trailing slash and
  /// no version prefix. Defaults to the documented local dev server.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.jm3eia.store',
  );

  /// Every customer route lives under this prefix (`GET /v1/products`).
  static const String apiVersion = '/v1';

  /// `--dart-define=API_LOG_SECRETS=true` prints `Authorization` / token values
  /// in full inside the debug API trace (`NetworkLogInterceptor`); they are
  /// masked by default. Debug builds only — release carries no trace.
  static const bool apiLogSecrets = bool.fromEnvironment('API_LOG_SECRETS');

  /// `true` when the base URL came from `--dart-define`. A release built
  /// without one would silently point at localhost — assert on this in CI.
  static const bool hasExplicitApiBaseUrl = bool.hasEnvironment('API_BASE_URL');
}
