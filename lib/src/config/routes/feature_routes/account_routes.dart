import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation.dart';
import '../../../features/account/presentation/pages/loyalty_page.dart';
import '../../../features/account/presentation/pages/mine_about_page.dart';
import '../../../features/account/presentation/pages/mine_delivery_code_page.dart';
import '../../../features/account/presentation/pages/mine_settings_page.dart';
import '../../../features/account/presentation/pages/profile_edit_page.dart';
import '../../../features/account/presentation/pages/wallet_page.dart';
import '../routes.dart';

/// Account sub-pages (the Mine tab itself is registered in `shell_routes.dart`).
final List<RouteBase> accountRoutes = <RouteBase>[
  GoRoute(
    path: Routes.profileEdit,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const ProfileEditPage(),
    ),
  ),
  GoRoute(
    path: Routes.mineSettings,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const MineSettingsPage(),
    ),
  ),
  GoRoute(
    path: Routes.mineAbout,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const MineAboutPage(),
    ),
  ),
  GoRoute(
    path: Routes.mineDeliveryCode,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const MineDeliveryCodePage(),
    ),
  ),
  GoRoute(
    path: Routes.wallet,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const WalletPage(),
    ),
  ),
  GoRoute(
    path: Routes.loyalty,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const LoyaltyPage(),
    ),
  ),
];
