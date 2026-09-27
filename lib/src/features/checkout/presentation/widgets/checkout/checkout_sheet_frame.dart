import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/jameia_close_button.dart';
import '../../cubit/checkout_cubit.dart';
import 'checkout_ink_theme.dart';

/// The Keeta sheet shell every checkout sheet shares: a white card with a
/// 12 dp top radius, a floating 30 dp white close disc 16 dp above it (at
/// the start), an optional bold [title], the [child], and an optional
/// [footer] (a sticker button) under a hairline. The strip around the disc
/// is part of the sheet, not the scrim, so a tap on it closes the sheet too.
///
/// Never taller than [maxHeightFactor] of the screen; it moves up with the
/// keyboard. [child] should scroll when it can be long (it gets the space
/// left).
///
/// Open it with [show], which passes the page-scoped `CheckoutCubit` down:
/// a sheet is a new route, so it cannot see the page's providers.
class CheckoutSheetFrame extends StatelessWidget {
  const CheckoutSheetFrame({
    super.key,
    required this.child,
    this.title,
    this.footer,
    this.maxHeightFactor = defaultMaxHeightFactor,
  });

  /// The floating close disc.
  static const double discSize = AppSize.s30;

  /// The transparent strip above the card: the disc plus 16 dp of air.
  static const double stripHeight = AppSize.s46;

  static const double defaultMaxHeightFactor = 0.85;

  static const Radius _radius = Radius.circular(AppRadius.card);

  /// The shared ✕ is a 24 dp glyph in a 48 dp target; drawn at 18 dp in
  /// the disc.
  static const double _crossScale = AppSize.s18 / AppSize.s24;

  final Widget child;
  final String? title;
  final Widget? footer;
  final double maxHeightFactor;

  /// Shows [builder] as a checkout sheet. Pass [checkout] whenever the
  /// sheet reads the page's `CheckoutCubit`; [large] uses the slower slide
  /// of a tall sheet. The sheet answers touches with the checkout's flat
  /// press tint ([CheckoutInkTheme]).
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    CheckoutCubit? checkout,
    bool large = false,
  }) => showJameiaBottomSheet<T>(
    context,
    large: large,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    shape: const RoundedRectangleBorder(),
    builder: (_) => CheckoutInkTheme(
      child: checkout == null
          ? Builder(builder: builder)
          : BlocProvider<CheckoutCubit>.value(
              value: checkout,
              child: Builder(builder: builder),
            ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final heading = title;
    final bottom = footer;
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: media.size.height * maxHeightFactor + stripHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The strip: a tap anywhere on it closes the sheet, like the
            // disc does (the disc's ✕ is the one announced control).
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.pop(),
              child: SizedBox(
                height: stripHeight,
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: AppSpacing.s16,
                    ),
                    child: SizedBox.square(
                      dimension: discSize,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                        // The shared ✕ (pops the route), scaled into
                        // the disc; its target overhangs the disc a little.
                        child: OverflowBox(
                          maxWidth: AppSize.s48,
                          maxHeight: AppSize.s48,
                          child: Transform.scale(
                            scale: _crossScale,
                            child: const JameiaCloseButton(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Flexible(
              child: Material(
                color: AppColors.white,
                borderRadius: const BorderRadius.vertical(top: _radius),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (heading != null)
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          AppSpacing.s12,
                          AppSpacing.s20,
                          AppSpacing.s12,
                          AppSpacing.s12,
                        ),
                        child: Semantics(
                          header: true,
                          child: Text(
                            heading,
                            style: AppTextStyles.sectionTitle,
                          ),
                        ),
                      ),
                    Flexible(child: child),
                    if (bottom != null) ...[
                      const Divider(
                        height: AppSize.s1,
                        thickness: AppSize.s1,
                        color: AppColors.divider,
                        indent: AppSize.s3,
                        endIndent: AppSize.s3,
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          AppSpacing.s12,
                          AppSpacing.s12,
                          AppSpacing.s12,
                          AppSpacing.s12,
                        ),
                        child: bottom,
                      ),
                    ],
                    SizedBox(
                      height: media.viewInsets.bottom > 0
                          ? 0
                          : media.padding.bottom,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
