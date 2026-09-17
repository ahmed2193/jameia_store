import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/app_size.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/entities/home_popup_entity.dart';
import '../util/home_popup_display.dart';
import 'jameia_popup_scaffold.dart';

/// Priority order for the home popup queue (`popup_list_main` + gundam):
/// newborn → coupon → image-text → vertical banner.
const _priority = ['newborn', 'coupon', 'imageText', 'verticalBanner'];

/// Show the home popup queue sequentially — each popup is fully shown AND
/// dismissed before the next appears (one queue per session; the caller guards
/// re-entry).
///
/// A short settle delay is inserted between popups: `showGeneralDialog`'s future
/// resolves as the previous route is being removed, and pushing the next dialog
/// mid-transition can drop it silently. The delay lets the exit transition
/// finish so every queued popup reliably chains.
Future<void> showHomePopups(
  BuildContext context,
  List<HomePopupEntity> popups,
) async {
  final ordered = [...popups]
    ..sort((a, b) {
      final ia = _priority.indexOf(a.type);
      final ib = _priority.indexOf(b.type);
      return (ia < 0 ? 99 : ia).compareTo(ib < 0 ? 99 : ib);
    });
  for (var i = 0; i < ordered.length; i++) {
    if (!context.mounted) return;
    // showGeneralDialog already pushes on the root navigator (useRootNavigator).
    await showJameiaPopup<void>(
      context,
      (ctx) => _PopupRouter(popup: ordered[i]),
    );
    if (i < ordered.length - 1) {
      // Let the just-dismissed dialog's exit transition fully settle before the
      // next is pushed, otherwise pushing mid-transition drops it silently.
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
  }
}

class _PopupRouter extends StatelessWidget {
  const _PopupRouter({required this.popup});
  final HomePopupEntity popup;

  void _close(BuildContext context) => Navigator.of(context).maybePop();

  /// With a scheme the CTA only opens the shop: the popup stays open UNDER the
  /// shop page and the queue stays paused until the user returns to Home and
  /// closes it. This keeps the legacy `maybePop()` + synchronous
  /// `Navigator.pushNamed` result (the deferred pop found a new top route and
  /// was dropped). GoRouter applies a push on the next frame, so popping here
  /// would really close the dialog and let [showHomePopups] draw the next
  /// popup on top of the shop page.
  void _cta(BuildContext context) {
    if (popup.scheme.isEmpty) {
      Navigator.of(context).maybePop();
      return;
    }
    context.push(Routes.shop, extra: popup.scheme);
  }

  @override
  Widget build(BuildContext context) {
    return JameiaPopupScaffold(
      onClose: () => _close(context),
      child: switch (popup.type) {
        'coupon' => _CouponPopup(popup: popup, onCta: () => _cta(context)),
        'verticalBanner' => _ImagePopup(
          popup: popup,
          tall: true,
          onCta: () => _cta(context),
        ),
        _ => _ImagePopup(popup: popup, onCta: () => _cta(context)),
      },
    );
  }
}

/// Pill CTA — 50dp h, r25, brand yellow, Jameia-Bold 16dp (popup digest).
class _PopupCta extends StatelessWidget {
  const _PopupCta({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSize.r25),
        ),
        child: Text(
          text.isEmpty ? 'home.continue_label'.tr() : text,
          style: AppTextStyles.headingMedium.copyWith(
            fontWeight: AppTextStyles.bold,
            color: AppColors.brandForeground,
          ),
        ),
      ),
    );
  }
}

/// Coupon popup (`home_new_coupon_pop_main`): header banner + a voucher ticket
/// + claim CTA on a white card. The ticket matches the digest atoms — a 94dp
/// amount panel (`c559ec`/`g95e5f`) and a 177dp info panel (`i5bf13`) on cream
/// `#fffef5`, brown `#6a2f00` amount/title, tan `#a77d5b` condition text.
class _CouponPopup extends StatelessWidget {
  const _CouponPopup({required this.popup, required this.onCta});
  final HomePopupEntity popup;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: ColoredBox(
        color: AppColors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header banner (`e4c4d4` 327×81 → kept a touch taller for photos).
            if (popup.image.isNotEmpty)
              AspectRatio(
                aspectRatio: 327 / 120,
                child: JameiaImage(url: popup.image, fit: BoxFit.cover),
              ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (popup.displayTitle.isNotEmpty) ...[
                    Text(
                      popup.displayTitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headingMedium.copyWith(
                        fontWeight: AppTextStyles.bold,
                        color: AppColors.voucherBrown,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                  ],
                  _VoucherTicket(popup: popup),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 16),
              child: _PopupCta(
                text: popup.displayCta.isEmpty
                    ? 'home.claim_now'.tr()
                    : popup.displayCta,
                onTap: onCta,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A horizontal voucher ticket: cream amount panel + perforated tear line +
/// info panel, with punched (white) notches on the tear line.
class _VoucherTicket extends StatelessWidget {
  const _VoucherTicket({required this.popup});
  final HomePopupEntity popup;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.voucherCream,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.overlayDivider),
            ),
            child: Row(
              children: [
                // Left amount panel — 94dp (c559ec).
                SizedBox(
                  width: 94,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          popup.amount.isNotEmpty ? popup.amount : '—',
                          style: const TextStyle(
                            fontSize: AppSize.font20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.voucherBrown,
                          ),
                        ),
                      ),
                      if (popup.displayAmountUnit.isNotEmpty)
                        Text(
                          popup.displayAmountUnit,
                          style: const TextStyle(
                            fontSize: AppSize.font12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.voucherBrown,
                          ),
                        ),
                    ],
                  ),
                ),
                const _Perforation(),
                // Right info panel — 177dp (i5bf13).
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 2, end: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          popup.displayTitle.isNotEmpty
                              ? popup.displayTitle
                              : 'home.coupon'.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: AppSize.font14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.voucherBrown,
                          ),
                        ),
                        if (popup.displayBody.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            popup.displayBody,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: AppSize.font11,
                              height: 1.2,
                              color: AppColors.voucherTan,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Punched notches (white = card bg) on the tear line (x ≈ 95).
          const PositionedDirectional(start: 90, top: -5, child: _Notch()),
          const PositionedDirectional(start: 90, bottom: -5, child: _Notch()),
        ],
      ),
    );
  }
}

/// Dashed vertical tear line between the voucher panels.
class _Perforation extends StatelessWidget {
  const _Perforation();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          7,
          (_) => Container(
            width: 1.5,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.voucherTanFaint,
              borderRadius: BorderRadius.circular(AppSize.r1),
            ),
          ),
        ),
      ),
    );
  }
}

/// A punched-out hole on the voucher tear line (white circle = card background).
class _Notch extends StatelessWidget {
  const _Notch();
  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: const BoxDecoration(
      color: AppColors.white,
      shape: BoxShape.circle,
    ),
  );
}

/// Image-text / vertical-banner popup (`imagetextmodal*` / `*_vertical_banner`):
/// a full image card with an optional bottom CTA pill.
class _ImagePopup extends StatelessWidget {
  const _ImagePopup({
    required this.popup,
    this.tall = false,
    required this.onCta,
  });
  final HomePopupEntity popup;
  final bool tall;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: tall ? 3 / 5 : 3 / 4,
            child: JameiaImage(url: popup.image, fit: BoxFit.cover),
          ),
          if (popup.displayCta.isNotEmpty)
            PositionedDirectional(
              start: 16,
              end: 16,
              bottom: 16,
              child: _PopupCta(text: popup.displayCta, onTap: onCta),
            )
          else
            // Whole card tappable when there's no explicit CTA.
            Positioned.fill(
              child: GestureDetector(
                onTap: onCta,
                behavior: HitTestBehavior.opaque,
              ),
            ),
        ],
      ),
    );
  }
}
