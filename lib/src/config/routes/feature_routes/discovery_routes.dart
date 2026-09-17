import 'package:go_router/go_router.dart';

import '../../../core/data/models/models.dart';
import '../../../core/navigation/navigation.dart';
import '../../../features/discovery/presentation/pages/channel_list_page.dart';
import '../../../features/discovery/presentation/pages/fixed_price_page.dart';
import '../../../features/discovery/presentation/pages/kingkong_landing_page.dart';
import '../../../features/discovery/presentation/pages/meal_for_one_page.dart';
import '../../../features/discovery/presentation/pages/pick_up_page.dart';
import '../routes.dart';

const String _fallbackChannelTitle = 'Discover';
const String _fallbackMealForOneTitle = 'Meal for One';

/// Home discovery landings: channel list, meal-for-one, pick-up, fixed price
/// and the kingkong (category tile) landing.
final List<RouteBase> discoveryRoutes = <RouteBase>[
  // extra: String channel title (default: 'Discover').
  GoRoute(
    path: Routes.channelList,
    pageBuilder: (_, state) {
      final title = state.extra;
      return JameiaTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: ChannelListPage(
          title: title is String ? title : _fallbackChannelTitle,
        ),
      );
    },
  ),
  // extra: String title (default: 'Meal for One').
  GoRoute(
    path: Routes.mealForOne,
    pageBuilder: (_, state) {
      final title = state.extra;
      return JameiaTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: MealForOnePage(
          title: title is String ? title : _fallbackMealForOneTitle,
        ),
      );
    },
  ),
  GoRoute(
    path: Routes.pickUp,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const PickUpPage(),
    ),
  ),
  // extra: String shop id (default: null).
  GoRoute(
    path: Routes.fixedPrice,
    pageBuilder: (_, state) {
      final shopId = state.extra;
      return JameiaTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: FixedPricePage(shopId: shopId is String ? shopId : null),
      );
    },
  ),
  // extra: the tapped KingKongItem (carries id + title); otherwise the page's
  // own defaults.
  GoRoute(
    path: Routes.kingkongLanding,
    pageBuilder: (_, state) {
      final item = state.extra;
      return JameiaTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: item is KingKongItem
            ? KingKongLandingPage(categoryId: item.id, title: item.title)
            : const KingKongLandingPage(),
      );
    },
  ),
];
