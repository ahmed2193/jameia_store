import 'package:flutter/widgets.dart';

/// Global root navigator key — wired to `GoRouter(navigatorKey:)` in
/// `config/routes/app_router.dart`.
///
/// Lets non-widget orchestration (e.g. the post language-switch refresh in
/// `SettingCubit`) reach a `BuildContext` that survives the locale-driven
/// rebuild, instead of a screen context that may unmount mid-refresh.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
