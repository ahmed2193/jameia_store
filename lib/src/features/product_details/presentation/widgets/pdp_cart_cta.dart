import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/sticker_text.dart';
import 'pdp_added_label.dart';
import 'pdp_cta_stepper.dart';

/// What the buy bar's block shows.
enum _CtaMode { add, added, stepper, disabled }

/// The buy bar's big green block. "Add to cart" (white sticker letters)
/// reports [onAdd] and says "Added ✓" for a moment, then morphs into a
/// filled "−  qty  +" stepper
/// bound to the selection's cart line ([quantity]); when that line drops to
/// nothing it morphs back into "Add to cart". Disabled, it is a grey block
/// that says why ([disabledLabel]: choose an option, out of stock) and does
/// not react.
class PdpCartCta extends StatefulWidget {
  const PdpCartCta({
    super.key,
    required this.enabled,
    required this.disabledLabel,
    required this.quantity,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
    this.canIncrement = true,
  });

  final bool enabled;
  final String disabledLabel;

  /// Pieces of the selection in the cart; `0` = not in it.
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool canIncrement;

  static const double height = AppSize.s56;

  /// How long "Added ✓" stays before the stepper takes over.
  static const Duration addedHold = Duration(milliseconds: 1200);

  @override
  State<PdpCartCta> createState() => _PdpCartCtaState();
}

class _PdpCartCtaState extends State<PdpCartCta> {
  bool _added = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  void _add() {
    widget.onAdd();
    _reset?.cancel();
    setState(() => _added = true);
    _reset = Timer(PdpCartCta.addedHold, () {
      if (mounted) setState(() => _added = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mode = !widget.enabled
        ? _CtaMode.disabled
        : _added
        ? _CtaMode.added
        : widget.quantity > 0
        ? _CtaMode.stepper
        : _CtaMode.add;
    final active = mode != _CtaMode.disabled;
    final style = AppTextStyles.sectionTitle.copyWith(
      color: active ? AppColors.brandForeground : AppColors.tertiaryText,
    );
    final Widget content = switch (mode) {
      _CtaMode.add => Center(
        key: const ValueKey<String>('add'),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: StickerText('product.add_to_cart'.tr(), style: style),
        ),
      ),
      _CtaMode.added => Center(
        key: const ValueKey<String>('added'),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: PdpAddedLabel(style: style),
        ),
      ),
      _CtaMode.stepper => PdpCtaStepper(
        key: const ValueKey<String>('stepper'),
        quantity: widget.quantity,
        canIncrement: widget.canIncrement,
        onIncrement: widget.onIncrement,
        onDecrement: widget.onDecrement,
      ),
      _CtaMode.disabled => Center(
        key: ValueKey<String>(widget.disabledLabel),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(widget.disabledLabel, maxLines: 1, style: style),
        ),
      ),
    };
    final tappable = mode == _CtaMode.add;
    return Semantics(
      container: true,
      button: mode != _CtaMode.stepper,
      enabled: mode == _CtaMode.disabled ? false : null,
      liveRegion: mode == _CtaMode.added,
      onTap: tappable ? _add : null,
      // Always handed the tap and gated by `enabled`: a null tap would swap
      // PressScale's root widget (GestureDetector ⇄ Listener) and remount
      // the pill, cutting every morph between its modes short.
      child: PressScale(
        onTap: _add,
        enabled: tappable,
        child: AnimatedContainer(
          duration: MotionGuard.duration(context, AppMotion.fast),
          curve: AppMotion.signature,
          height: PdpCartCta.height,
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: mode == _CtaMode.stepper
                ? AppSpacing.s8
                : AppSpacing.s16,
          ),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.divider,
            borderRadius: BorderRadius.circular(AppRadius.r3),
          ),
          // The one add → stepper swap of every add surface (docs/motion
          // BX-09): the new content pops in place on the snappy spring.
          child: PopSwitcher(
            stateKey: switch (mode) {
              _CtaMode.disabled => widget.disabledLabel,
              _ => mode,
            },
            from: PopSwitcher.cartFrom,
            child: content,
          ),
        ),
      ),
    );
  }
}
