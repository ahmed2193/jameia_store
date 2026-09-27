import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/second_clock_scope.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/countdown_digits.dart';

/// When an offer ends: the red-box countdown ("Ends in 06:36:36") when it
/// ends within a day, otherwise "Valid until {date}"; "Ended" once it is
/// over. Nothing without an end. The countdown ticks on the page's shared
/// clock and turns into "Ended" by itself; it never refetches.
class CheckoutOfferExpiry extends StatefulWidget {
  const CheckoutOfferExpiry({super.key, required this.endsAt});

  final DateTime? endsAt;

  @override
  State<CheckoutOfferExpiry> createState() => _CheckoutOfferExpiryState();
}

class _CheckoutOfferExpiryState extends State<CheckoutOfferExpiry> {
  bool _ended = false;

  @override
  void didUpdateWidget(CheckoutOfferExpiry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.endsAt != oldWidget.endsAt) _ended = false;
  }

  @override
  Widget build(BuildContext context) {
    final endsAt = widget.endsAt;
    if (endsAt == null) return const SizedBox.shrink();
    final now = SecondClockScope.maybeOf(context)?.now ?? DateTime.now();
    final style = AppTextStyles.bodySmall.copyWith(
      color: AppColors.secondaryText,
    );
    if (_ended || !endsAt.isAfter(now)) {
      return Text('checkout.offer_ended'.tr(), style: style);
    }
    if (!CountdownDigits.countsDown(endsAt, now)) {
      return Text(
        'checkout.offer_valid_until'.tr(
          namedArgs: {
            'date': Formatters.date(context.locale.languageCode, endsAt),
          },
        ),
        style: style,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('checkout.offer_ends_in'.tr(), style: style),
        const SizedBox(width: AppSpacing.s6),
        CountdownDigits(
          endsAt: endsAt,
          onEnded: () => setState(() => _ended = true),
        ),
      ],
    );
  }
}
