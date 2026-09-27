import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/haptics.dart';
import '../cubit/connectivity_banner_mode.dart';
import '../cubit/connectivity_cubit.dart';
import 'connectivity_bar_icon.dart';
import 'connectivity_bar_label.dart';

/// The banner's row: the icon slot at the start, the text block after it.
/// While offline the whole row is one button — "check now". Screen readers
/// hear "You're offline" / "Back online" once per change (a live region
/// whose label does not change while a check runs).
class ConnectivityBarContent extends StatelessWidget {
  const ConnectivityBarContent({super.key, required this.mode});

  final ConnectivityBannerMode mode;

  bool get _backOnline => mode == ConnectivityBannerMode.backOnline;

  void _retry(BuildContext context) {
    Haptics.tap();
    context.read<ConnectivityCubit>().retry();
  }

  @override
  Widget build(BuildContext context) {
    final canRetry = mode == ConnectivityBannerMode.offline;
    return Semantics(
      container: true,
      liveRegion: true,
      button: canRetry,
      label: _backOnline
          ? 'connectivity.back_online'.tr()
          : 'connectivity.offline_title'.tr(),
      hint: canRetry ? 'connectivity.tap_to_retry'.tr() : null,
      onTap: canRetry ? () => _retry(context) : null,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: canRetry ? () => _retry(context) : null,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s10,
          ),
          child: Row(
            children: [
              ConnectivityBarIcon(mode: mode),
              const SizedBox(width: AppSpacing.s12),
              Expanded(child: ConnectivityBarLabel(mode: mode)),
            ],
          ),
        ),
      ),
    );
  }
}
