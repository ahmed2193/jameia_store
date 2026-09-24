import 'package:go_router/go_router.dart';

import '../../../core/domain/entities/jameia_address_entity.dart';
import '../../../core/navigation/navigation.dart';
import '../../../features/address/presentation/pages/address_edit_page.dart';
import '../../../features/address/presentation/pages/address_list_page.dart';
import '../../../features/address/presentation/pages/choose_location_page.dart';
import '../routes.dart';

/// Saved addresses, the address editor and the region picker.
final List<RouteBase> addressRoutes = <RouteBase>[
  // Pops with the tapped JameiaAddressEntity (select), or nothing on back.
  GoRoute(
    path: Routes.addressList,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const AddressListPage(),
    ),
  ),
  // extra: JameiaAddressEntity to edit (default: null = new address). Pops
  // with the saved JameiaAddressEntity.
  GoRoute(
    path: Routes.addressEdit,
    pageBuilder: (_, state) {
      final address = state.extra;
      return JameiaTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: AddressEditPage(
          address: address is JameiaAddressEntity ? address : null,
        ),
      );
    },
  ),
  // Pops with the chosen service region.
  GoRoute(
    path: Routes.chooseLocation,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const ChooseLocationPage(),
    ),
  ),
];
