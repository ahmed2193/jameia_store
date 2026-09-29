import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';

/// "Copy code" pill under the saved code. A tap copies the code, gives a
/// selection tick and flips the label to "Copied" (green check) for a
/// moment, then back.
class DeliveryCodeCopyButton extends StatefulWidget {
  const DeliveryCodeCopyButton({super.key, required this.code});

  final String code;

  @override
  State<DeliveryCodeCopyButton> createState() => _DeliveryCodeCopyButtonState();
}

class _DeliveryCodeCopyButtonState extends State<DeliveryCodeCopyButton> {
  static const Duration _copiedHold = Duration(milliseconds: 1800);

  bool _copied = false;
  Timer? _reset;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(_copiedHold, () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.code.isNotEmpty;
    final ink = _copied ? AppColors.primaryDark : AppColors.primaryText;
    final label = (_copied ? 'settings.copied' : 'settings.code_copy').tr();
    return Semantics(
      button: true,
      enabled: enabled,
      liveRegion: true,
      label: label,
      excludeSemantics: true,
      child: PressScale(
        haptic: HapticKind.selection,
        enabled: enabled,
        onTap: enabled ? _copy : null,
        child: AnimatedContainer(
          duration: MotionGuard.duration(context, AppMotion.fast),
          curve: AppMotion.signature,
          constraints: const BoxConstraints(minHeight: AppSize.s44),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s16,
          ),
          decoration: BoxDecoration(
            color: _copied ? AppColors.brandLightBg : AppColors.smallBackground,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(
                child: FlipValue(
                  flipKey: _copied,
                  alignment: AlignmentDirectional.center,
                  child: Icon(
                    _copied ? Icons.check_rounded : Icons.copy_rounded,
                    size: AppSize.s18,
                    color: ink,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s6),
              RepaintBoundary(
                child: FlipValue(
                  flipKey: _copied,
                  child: Text(
                    label,
                    style: AppTextStyles.headingSmall.copyWith(
                      fontWeight: AppTextStyles.bold,
                      color: ink,
                    ),
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
