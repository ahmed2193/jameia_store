import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../config/theme/app_spacing.dart';
import '../design/hero_icons.dart';
import '../motion/fade_through_switcher.dart';
import '../responsive/app_size.dart';
import 'app_loader.dart';
import 'hero_secondary_button.dart';

/// The end of a paged list, one look for every list: the inline dots while
/// the next page is on its way, a compact "Try again" pill after it failed
/// (online — offline, `NextPageSentinel` / the list shows
/// `LoadMoreOfflineNote` instead). The two swap in place.
class LoadMoreFooter extends StatelessWidget {
  const LoadMoreFooter({
    super.key,
    required this.failed,
    required this.onRetry,
    this.padding = const EdgeInsetsDirectional.symmetric(
      horizontal: AppSpacing.gutter,
      vertical: AppSpacing.s12,
    ),
  });

  final bool failed;
  final VoidCallback onRetry;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: SizedBox(
        height: AppSize.s44,
        child: FadeThroughSwitcher(
          stateKey: failed,
          child: failed
              ? Center(
                  child: HeroSecondaryButton(
                    label: 'retry'.tr(),
                    icon: HeroIcons.refresh,
                    compact: true,
                    height: AppSize.s44,
                    onPressed: onRetry,
                  ),
                )
              : const AppLoader.inline(),
        ),
      ),
    );
  }
}
