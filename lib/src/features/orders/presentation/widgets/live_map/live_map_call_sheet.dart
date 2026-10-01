import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/phone_dialer.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/hero_sheet_header.dart';
import '../../../domain/entities/courier_trip.dart';
import 'live_map_rider_identity.dart';

/// Before a call to the rider: who is called ([LiveMapRiderIdentity]), that
/// the call goes through Hero's private line (ending in the digits the
/// customer will see ring) so neither side's own number shows, "Call now" —
/// which hands the line to the phone app, the customer presses call there —
/// and "Message instead", which answers `true` (the caller opens the chat).
class LiveMapCallSheet extends StatelessWidget {
  const LiveMapCallSheet({super.key, required this.trip, required this.rider});

  final CourierTrip trip;

  /// The rider's name as the customer reads it.
  final String rider;

  static const double _glyph = AppSize.s20;

  Future<void> _call(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    context.pop();
    if (await PhoneDialer.dial(trip.riderPhone)) return;
    showHeroSnackBarOn(
      messenger,
      'orders.live_call_failed'.tr(),
      tone: HeroSnackTone.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ending = trip.lineEnding;
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeroSheetHeader(
            title: 'orders.live_call_title'.tr(namedArgs: {'rider': rider}),
          ),
          // Scrolls under the header when a small phone at a large text
          // size caps the sheet below its content, so both buttons stay
          // reachable.
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.gutter,
                  AppSpacing.s8,
                  AppSpacing.gutter,
                  AppSpacing.s16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LiveMapRiderIdentity(trip: trip),
                    const SizedBox(height: AppSpacing.s16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ExcludeSemantics(
                          child: Icon(
                            HeroIcons.lockClock,
                            size: _glyph,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: Text(
                            ending.isEmpty
                                ? 'orders.live_call_note'.tr()
                                : 'orders.live_call_note_line'.tr(
                                    namedArgs: {'digits': ending},
                                  ),
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s20),
                    AppButton(
                      label: 'orders.live_call_button'.tr(),
                      onPressed: () => _call(context),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    AppButton(
                      label: 'orders.live_call_message_instead'.tr(),
                      color: AppColors.brandLightBg,
                      foreground: AppColors.primaryDark,
                      onPressed: () => context.pop(true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
