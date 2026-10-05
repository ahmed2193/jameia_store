import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/hero_money_text.dart';

/// "Delivery fee  KD 0.500  [Free]" in the first-order dialog: the zone's
/// fee ([feeKd], from the launch snapshot) gets struck through — the line
/// draws across it — and the "Free" tag springs in after it. One
/// controller, played once as the card lands; reduced motion shows the end
/// state at once. Read out as one line.
class HomeFirstOrderFeeLine extends StatefulWidget {
  const HomeFirstOrderFeeLine({super.key, required this.feeKd});

  final double feeKd;

  /// The strike draws over [AppMotion.drawOn], then the tag pops.
  static final Duration _length = AppMotion.drawOn + AppMotion.medium;
  static const Interval _strikeAt = Interval(
    0.2,
    0.65,
    curve: AppMotion.signature,
  );
  static final Interval _tagAt = Interval(0.6, 1, curve: AppSprings.snappy);
  static const double _strikeWeight = AppSize.s1_5;

  @override
  State<HomeFirstOrderFeeLine> createState() => _HomeFirstOrderFeeLineState();
}

class _HomeFirstOrderFeeLineState extends State<HomeFirstOrderFeeLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _play = AnimationController(
    vsync: this,
    duration: HomeFirstOrderFeeLine._length,
  );
  late final CurvedAnimation _strike = CurvedAnimation(
    parent: _play,
    curve: HomeFirstOrderFeeLine._strikeAt,
  );
  late final CurvedAnimation _tag = CurvedAnimation(
    parent: _play,
    curve: HomeFirstOrderFeeLine._tagAt,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MotionGuard.reduced(context)) {
      _play.value = 1;
    } else {
      _play.forward();
    }
  }

  @override
  void dispose() {
    _strike.dispose();
    _tag.dispose();
    _play.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final muted = AppTextStyles.bodyLarge.copyWith(
      color: AppColors.secondaryText,
    );
    return Semantics(
      label: 'home.first_order_fee_semantics'.tr(
        namedArgs: {'amount': Formatters.price(widget.feeKd)},
      ),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('home.first_order_fee_label'.tr(), style: muted),
          const SizedBox(width: AppSpacing.s8),
          Stack(
            children: [
              HeroMoneyText(kd: widget.feeKd, style: muted),
              // Money is one left-to-right run in both languages: the line
              // draws from its left edge.
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedBuilder(
                    animation: _strike,
                    builder: (context, _) => FractionallySizedBox(
                      widthFactor: _strike.value,
                      child: const SizedBox(
                        height: HomeFirstOrderFeeLine._strikeWeight,
                        child: ColoredBox(color: AppColors.secondaryText),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.s8),
          ScaleTransition(
            scale: _tag,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.freeDeliveryBg,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s10,
                  vertical: AppSpacing.s2,
                ),
                child: Text(
                  'home.first_order_fee_free'.tr(),
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.freeDeliveryFgOnLight,
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
