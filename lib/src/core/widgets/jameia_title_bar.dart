import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../responsive/app_size.dart';
import 'round_back_button.dart';

/// The white title bar of every pushed screen (docs/design_system.md): the
/// outlined round back button, a start-aligned title, optional actions and a
/// hairline shadow. Use as `Scaffold.appBar`.
///
/// An optional [subtitle] stacks a grey second line under the title (the
/// Keeta "Checkout / Keemart" header); the title then steps down to 16 bold
/// so both lines sit in the same bar height. Null or empty → one line.
class JameiaTitleBar extends StatelessWidget implements PreferredSizeWidget {
  const JameiaTitleBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.showBack = true,
    this.leading,
  });

  static const double height = AppSize.s64;

  final String title;

  /// A grey line under the title (a store and branch name). Hidden when null
  /// or empty.
  final String? subtitle;
  final List<Widget> actions;
  final bool showBack;

  /// Replaces the back button (e.g. a [JameiaCloseButton]).
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    // A root route (a deep link, a `go`) has nothing to pop back to.
    final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    final lead =
        leading ?? (showBack && canPop ? const RoundBackButton() : null);
    final second = subtitle;
    final hasSubtitle = second != null && second.isNotEmpty;
    final heading = Semantics(
      header: true,
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: hasSubtitle
            ? AppTextStyles.headingMedium.copyWith(
                fontWeight: AppTextStyles.bold,
              )
            : AppTextStyles.barTitle,
      ),
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.white,
          boxShadow: AppShadows.barBottom,
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s12,
              ),
              child: Row(
                children: [
                  if (lead != null) ...[
                    lead,
                    const SizedBox(width: AppSpacing.s12),
                  ] else
                    const SizedBox(width: AppSpacing.s4),
                  Expanded(
                    child: hasSubtitle
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              heading,
                              Text(
                                second,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.meta,
                              ),
                            ],
                          )
                        : heading,
                  ),
                  ...actions,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
