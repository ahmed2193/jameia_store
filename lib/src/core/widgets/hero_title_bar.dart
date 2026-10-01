import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../motion/collapse_reveal.dart';
import '../motion/flip_value.dart';
import '../motion/motion.dart';
import '../responsive/app_size.dart';
import 'round_back_button.dart';

/// The white title bar of every pushed screen (docs/design_system.md): the
/// outlined round back button, a start-aligned title, optional actions and a
/// hairline shadow. Use as `Scaffold.appBar`.
///
/// An optional [subtitle] stacks a grey second line under the title (the
/// Hero "Checkout / Hero" header); the title then steps down to 16 bold
/// so both lines sit in the same bar height. Null or empty → one line. A
/// subtitle that arrives late (a name read after the page opened) opens
/// under the title while the title eases to its smaller size, instead of
/// snapping the bar's content (docs/motion B2-05). A title or subtitle that
/// changes while shown (the order number arriving, a chat starting to type)
/// flips to its new words ([FlipValue]).
///
/// [titleLeading] sits before the words (a chat's avatar). [bottom] is
/// pinned under the bar, inside the same white surface and shadow (a
/// category tab strip). Icon actions are [HeroBarAction]s.
class HeroTitleBar extends StatelessWidget implements PreferredSizeWidget {
  const HeroTitleBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.showBack = true,
    this.leading,
    this.titleLeading,
    this.bottom,
  });

  static const double height = AppSize.s64;

  final String title;

  /// A grey line under the title (a store and branch name). Hidden when null
  /// or empty.
  final String? subtitle;
  final List<Widget> actions;
  final bool showBack;

  /// Replaces the back button (e.g. a [HeroCloseButton]).
  final Widget? leading;

  /// Drawn before the title (an avatar).
  final Widget? titleLeading;

  /// Pinned under the bar (a tab strip).
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    // A root route (a deep link, a `go`) has nothing to pop back to.
    final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    final lead =
        leading ?? (showBack && canPop ? const RoundBackButton() : null);
    final second = subtitle;
    final hasSubtitle = second != null && second.isNotEmpty;
    final avatar = titleLeading;
    final heading = Semantics(
      header: true,
      child: AnimatedDefaultTextStyle(
        duration: MotionGuard.duration(context, AppMotion.medium),
        curve: AppMotion.signature,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: hasSubtitle
            ? AppTextStyles.headingMedium.copyWith(
                fontWeight: AppTextStyles.bold,
              )
            : AppTextStyles.barTitle,
        child: FlipValue(
          flipKey: title,
          child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
    final bar = SizedBox(
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
            if (avatar != null) ...[
              avatar,
              const SizedBox(width: AppSpacing.s8),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heading,
                  CollapseReveal(
                    visible: hasSubtitle,
                    child: hasSubtitle
                        ? FlipValue(
                            flipKey: second,
                            child: Text(
                              second,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.meta,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
    final under = bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.white,
          boxShadow: AppShadows.barBottom,
        ),
        child: SafeArea(
          bottom: false,
          child: under == null
              ? bar
              : Column(mainAxisSize: MainAxisSize.min, children: [bar, under]),
        ),
      ),
    );
  }
}
