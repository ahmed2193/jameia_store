import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion.dart';

/// The empty composer's placeholder: it cycles through example questions
/// ("Try: eggs and milk for breakfast") so the customer sees what to ask.
/// Screen readers get the plain hint; reduced motion shows one example,
/// still.
class AssistantComposerHint extends StatefulWidget {
  const AssistantComposerHint({super.key});

  static const List<String> examples = [
    'assistant.composer_try_breakfast',
    'assistant.composer_try_offers',
    'assistant.composer_try_dinner',
    'assistant.composer_try_delivery',
  ];

  static const Duration every = Duration(seconds: 4);

  @override
  State<AssistantComposerHint> createState() => _AssistantComposerHintState();
}

class _AssistantComposerHintState extends State<AssistantComposerHint> {
  static const Offset _rise = Offset(0, 0.4);

  Timer? _timer;
  int _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    _timer = MotionGuard.reduced(context)
        ? null
        : Timer.periodic(AssistantComposerHint.every, (_) {
            if (mounted) setState(() => _index++);
          });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const examples = AssistantComposerHint.examples;
    final key = examples[_index % examples.length];
    return Semantics(
      label: 'assistant.composer_hint'.tr(),
      excludeSemantics: true,
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: MotionGuard.duration(context, AppMotion.medium),
          switchInCurve: AppMotion.signature,
          switchOutCurve: AppMotion.exit,
          layoutBuilder: (current, previous) => Stack(
            alignment: AlignmentDirectional.centerStart,
            children: [...previous, ?current],
          ),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: _rise,
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Text(
            key.tr(),
            key: ValueKey<String>(key),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.tertiaryText,
            ),
          ),
        ),
      ),
    );
  }
}
