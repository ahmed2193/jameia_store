import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../../config/theme/app_spacing.dart';
import '../../../../../../core/motion/spring_curve.dart';
import '../../../../../../core/responsive/app_size.dart';
import '../assistant_onboarding_cue.dart';
import '../assistant_onboarding_timeline.dart';
import 'assistant_onboarding_item.dart';
import 'assistant_onboarding_product_tile.dart';
import 'assistant_onboarding_reply_bubble.dart';
import 'assistant_onboarding_typed_bubble.dart';

/// Asking in your own words: "Just moved in, help me stock up!" types
/// itself out (the mascot listens), the assistant thinks and answers (it
/// talks), and a cleaner, bulbs and coffee — three aisles, one answer —
/// pop up one after another (it smiles).
class AssistantOnboardingAskScene extends StatelessWidget {
  const AssistantOnboardingAskScene({
    super.key,
    required this.active,
    required this.onCue,
  });

  final bool active;
  final ValueChanged<AssistantOnboardingCue> onCue;

  static const Duration _length = Duration(milliseconds: 3600);
  static const List<AssistantOnboardingBeat> _beats = [
    (0.02, AssistantOnboardingCue.listen),
    (0.42, AssistantOnboardingCue.talk),
    (0.72, AssistantOnboardingCue.smile),
  ];
  static const double _askIn = 0.08;
  static const double _typeFrom = 0.06;
  static const double _typeTo = 0.38;
  static const double _replyFrom = 0.4;
  static const double _replyIn = 0.5;
  static const double _answerAt = 0.62;
  static const double _tilesFrom = 0.64;
  static const double _tileStep = 0.08;
  static const double _tileLength = 0.22;
  static const double _edge = AppSpacing.s12;
  static const double _replyTop = AppSize.s60;
  static const double _tileGap = AppSpacing.s10;

  @override
  Widget build(BuildContext context) {
    final question = 'assistant.onboarding_demo_ask'.tr();
    return AssistantOnboardingTimeline(
      active: active,
      length: _length,
      beats: _beats,
      onCue: onCue,
      builder: (context, t) => Stack(
        children: [
          PositionedDirectional(
            top: _edge,
            end: _edge,
            child: AssistantOnboardingTypedBubble(
              text: question,
              typed: t.span(_typeFrom, _typeTo, Curves.linear),
              appear: t.span(0, _askIn, AppSprings.snappy),
            ),
          ),
          if (t >= _replyFrom)
            PositionedDirectional(
              top: _replyTop,
              start: _edge,
              child: AssistantOnboardingReplyBubble(
                appear: t.span(_replyFrom, _replyIn, AppSprings.snappy),
                answered: t >= _answerAt,
              ),
            ),
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: _edge,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final (index, item)
                    in AssistantOnboardingItem.values.indexed) ...[
                  if (index > 0) const SizedBox(width: _tileGap),
                  AssistantOnboardingProductTile(
                    item: item,
                    appear: t.span(
                      _tilesFrom + _tileStep * index,
                      _tilesFrom + _tileStep * index + _tileLength,
                      AppSprings.snappy,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
