import 'dart:async';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_svg_glyph.dart';
import '../assistant_motion.dart';
import 'assistant_tool_glyphs.dart';
import 'assistant_tool_labels.dart';

/// What the assistant is doing while no word is out yet (docs/motion §9.6
/// §2.7): a static glyph for the step, then its name — "Thinking", the tool
/// it runs, "Taking longer…" after [AssistantMotion.slowAfter]. A new step
/// rises in through [FlipValue]; each one stays at least
/// [AppMotion.successHold] (tools last milliseconds), after which the line
/// jumps straight to the newest — no queue, no step list. Nothing loops
/// here: the dots beside it are the loader. Not a live region (the page
/// announces the reply once).
class AssistantStepLine extends StatefulWidget {
  const AssistantStepLine({super.key, this.toolName});

  final String? toolName;

  @override
  State<AssistantStepLine> createState() => _AssistantStepLineState();
}

class _AssistantStepLineState extends State<AssistantStepLine> {
  late String? _shown = widget.toolName;
  bool _slow = false;
  Timer? _slowTimer;

  /// Running while the step shown has not had its minimum time yet.
  Timer? _hold;

  @override
  void initState() {
    super.initState();
    _slowTimer = Timer(AssistantMotion.slowAfter, () {
      if (mounted) setState(() => _slow = true);
    });
    _hold = Timer(AppMotion.successHold, _onHeld);
  }

  @override
  void didUpdateWidget(AssistantStepLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    // While held, the newest step waits for the hold to end.
    if (widget.toolName != _shown && _hold == null) _show();
  }

  void _show() {
    _shown = widget.toolName;
    _hold = Timer(AppMotion.successHold, _onHeld);
  }

  void _onHeld() {
    _hold = null;
    if (mounted && widget.toolName != _shown) setState(_show);
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    _hold?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tool = _shown;
    final label =
        (_slow
                ? 'assistant.taking_longer'
                : tool == null
                ? 'assistant.thinking'
                : AssistantToolLabels.keyOf(tool))
            .tr();
    final glyph = _slow
        ? AssistantToolGlyphs.slow
        : AssistantToolGlyphs.of(tool);
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: FlipValue(
          flipKey: label,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (glyph.asset case final String asset)
                HeroSvgGlyph.mono(
                  asset,
                  size: AppSize.s16,
                  color: AppColors.primaryDark,
                )
              else
                Icon(
                  glyph.icon,
                  size: AppSize.s16,
                  color: AppColors.primaryDark,
                ),
              const SizedBox(width: AppSpacing.s6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.labelGrey,
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
