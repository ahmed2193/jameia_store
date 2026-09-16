import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Post language-switch refresh hook — the offline, route-scoped counterpart to
/// khayool's `DataRefreshCoordinator`.
///
/// khayool re-fetches every app-level content cubit from the server in the new
/// language. This app is offline and its content cubits are route-scoped (created
/// per screen via `BlocProvider(create: ...)`), so re-localization is already
/// handled reactively without a global fan-out:
///   • static `.tr()` text + the RTL flip → easy_localization rebuilds the tree;
///   • GoogleMap marker/InfoWindow titles → each map screen reloads its markers
///     on locale change (see `didChangeDependencies` in the map screens).
///
/// This coordinator therefore only re-syncs `Intl.defaultLocale` and exists as
/// the documented seam for future data-driven re-localization. It deliberately
/// does NOT clear the cart or other user state: khayool clears server-derived
/// product names, but here cart lines are user selections and must survive a
/// language switch.
class DataRefreshCoordinator {
  DataRefreshCoordinator._();
  static final DataRefreshCoordinator instance = DataRefreshCoordinator._();

  /// Called after a successful language change, on the global navigator context.
  void refreshForLanguageChange(BuildContext? context) {
    if (context == null) return;
    Intl.defaultLocale = context.locale.languageCode;
    // Future data-driven refreshes (server-backed catalogs, etc.) hook in here.
  }
}
