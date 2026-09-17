# jameia_mart

JameiaMart Flutter app (clean architecture, Cubit, GoRouter, Dio).

## Running against the jm3eia API

The backend host is build-time config (`AppEnv.apiBaseUrl`); nothing is hardcoded.
Default is the live host `https://api.jm3eia.store` (OpenAPI: https://api.jm3eia.store/docs).
Debug builds print every request/response under the `api` log name; add
`--dart-define=API_LOG_SECRETS=true` to see tokens unmasked.

```sh
# Android emulator (host localhost = 10.0.2.2)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000
# Physical device on the same network
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:5000
# Release
flutter build apk --dart-define=API_BASE_URL=https://api.jm3eia.com --dart-define=MAPS_API_KEY=<key>
```

Shared networking (headers, auth refresh, envelope, error mapping) is documented in
[docs/api_integration.md](docs/api_integration.md). Architecture rules live in `CLAUDE.md`.

How-to guides for integrating an endpoint (used by AI agents, readable by humans) live in
`.claude/skills/jameia-api-*`: build recipe + code templates, session/auth, SSE streams,
testing, and on-device verification. Handy tools from there:

```sh
# one route's params / body / results from the live OpenAPI spec
node .claude/skills/jameia-api-integration/scripts/openapi_route.js orders
# local mock API (OTP 1234, failure knobs under /__admin/*) → run the app with API_BASE_URL=http://10.0.2.2:5055
node .claude/skills/jameia-api-verify/scripts/mock_api/server.js
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
