import 'package:go_router/go_router.dart';

import '../../../core/domain/entities/hero_address_entity.dart';
import '../../../core/navigation/navigation.dart';
import '../../../features/address/presentation/pages/address_edit_page.dart';
import '../../../features/address/presentation/pages/address_list_page.dart';
import '../routes.dart';

/// Saved addresses and the address editor.
final List<RouteBase> addressRoutes = <RouteBase>[
  // Pops with the tapped HeroAddressEntity (select), or nothing on back.
  GoRoute(
    path: Routes.addressList,
    pageBuilder: (_, state) => HeroTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const AddressListPage(),
    ),
  ),
  // extra: HeroAddressEntity to edit (default: null = new address). Pops
  // with the saved HeroAddressEntity.
  GoRoute(
    path: Routes.addressEdit,
    pageBuilder: (_, state) {
      final address = state.extra;
      return HeroTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: AddressEditPage(
          address: address is HeroAddressEntity ? address : null,
        ),
      );
    },
  ),
];
