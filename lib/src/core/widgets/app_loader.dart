import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '../responsive/app_size.dart';
import 'branded_dot_loader.dart';
import 'delayed_loader_disc.dart';

/// The app's loader, centred in the space it is given.
///
/// * [AppLoader.new] — a page or a block still loading: the white loader disc
///   with the Hero dots ([DelayedLoaderDisc]), which waits a beat before it
///   pops in so a fast load never flashes it. A screen reader hears
///   "Loading".
/// * [AppLoader.inline] — the bare dots for a list footer, a row or a small
///   spot ([size] is their width).
class AppLoader extends StatelessWidget {
  const AppLoader({super.key}) : size = null;

  const AppLoader.inline({super.key, double this.size = AppSize.s32});

  final double? size;

  @override
  Widget build(BuildContext context) {
    final inline = size;
    if (inline != null) {
      return Center(child: BrandedDotLoader(size: inline));
    }
    return Center(
      child: Semantics(
        label: 'core.loading'.tr(),
        child: const DelayedLoaderDisc(),
      ),
    );
  }
}
