import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/hero_assets.dart';
import '../../core/widgets/hero_state_view.dart';
import '../../core/widgets/hero_title_bar.dart';
import '../theme/app_colors.dart';
import 'route_args/shell_arrival.dart';
import 'routes.dart';

/// Where a location with no screen lands: the GoRouter error page for an
/// unknown path, and the fallback of a route opened without the `extra` it
/// needs. The customer sees the designed "Page not found" state with a way
/// home (and the back button when there is somewhere to go back to); [title]
/// names the path it stands in for, for logs and tests only.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});

  final String title;

  static const String _fallbackTitle = 'Screen';

  /// Derives the placeholder title from a route path: `'/invite-friends'` ->
  /// `'invite friends'` (null -> `'Screen'`).
  static String titleFor(String? location) =>
      (location ?? _fallbackTitle).replaceFirst('/', '').replaceAll('-', ' ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const HeroTitleBar(title: ''),
      body: HeroStateView(
        art: HeroAssets.stateNotFound,
        title: 'core.not_found_title'.tr(),
        message: 'core.not_found_message'.tr(),
        actionLabel: 'core.go_home'.tr(),
        onAction: () => context.go(Routes.shell, extra: ShellArrival()),
      ),
    );
  }
}
