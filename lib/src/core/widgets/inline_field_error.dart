import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../motion/collapse_reveal.dart';
import '../motion/motion.dart';
import '../responsive/app_size.dart';

/// The reason a field or code was refused, next to it (docs/motion §9.4 #18):
/// an error icon and the words in the error colour. It opens (height, then
/// the words fade in) when [message] arrives and folds away when it is
/// cleared ([CollapseReveal], [AppMotion.fast] both ways); a new message
/// while open simply replaces the words. Reduced motion → at once.
///
/// [announce] makes it a live region (screen readers hear it as it comes);
/// leave it off when a page listener already speaks the refusal once.
class InlineFieldError extends StatelessWidget {
  const InlineFieldError({
    super.key,
    required this.message,
    this.announce = true,
    this.centered = false,
    this.padding = const EdgeInsetsDirectional.only(
      top: AppSpacing.s8,
      start: AppSpacing.s4,
    ),
    this.iconSize = AppSize.s16,
    this.gap = AppSpacing.s6,
    this.style,
  });

  /// `null` → nothing (closed).
  final String? message;
  final bool announce;

  /// Centred under a centred control (the OTP digits); else start-aligned
  /// and wrapping beside the icon.
  final bool centered;
  final EdgeInsetsGeometry padding;
  final double iconSize;
  final double gap;

  /// Defaults to the small caption in the error colour.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final text = message;
    return CollapseReveal(
      visible: text != null,
      duration: AppMotion.fast,
      child: text == null
          ? const SizedBox.shrink()
          : Padding(
              padding: padding,
              child: Semantics(
                liveRegion: announce,
                child: Row(
                  mainAxisAlignment: centered
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  crossAxisAlignment: centered
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: iconSize,
                      color: AppColors.error,
                    ),
                    SizedBox(width: gap),
                    Flexible(
                      fit: centered ? FlexFit.loose : FlexFit.tight,
                      child: Text(
                        text,
                        textAlign: centered ? TextAlign.center : null,
                        style:
                            style ??
                            AppTextStyles.captionLarge.copyWith(
                              color: AppColors.error,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
