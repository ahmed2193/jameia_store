import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/paging_dots.dart';
import '../../../domain/entities/assistant_onboarding_step.dart';
import '../../../domain/entities/assistant_starter.dart';
import '../mascot/assistant_mascot_mood.dart';
import 'assistant_onboarding_cue.dart';
import 'assistant_onboarding_footer.dart';
import 'assistant_onboarding_page.dart';
import 'assistant_onboarding_perch.dart';
import 'assistant_onboarding_result.dart';

/// The assistant's tour: a sheet with the mascot perched on its edge and
/// five short steps — who it is, asking in your own words, a cart it fills
/// and you confirm, deals / orders / delivery, and where to find it — each
/// with a little demo the mascot reacts to. Each demo plays once per
/// opening: a step swiped back to shows how it ended (docs/motion §9.6
/// §2.12). Swipe or tap Next — a swipe ticks like a pick, Next is the
/// button's own tap. Skip, Maybe later, Start chatting or a question on the
/// last step close it with an [AssistantOnboardingResult] (`null` when
/// swiped / backed away).
class AssistantOnboardingSheet extends StatefulWidget {
  const AssistantOnboardingSheet({super.key});

  static Future<AssistantOnboardingResult?> show(BuildContext context) =>
      showHeroBottomSheet<AssistantOnboardingResult>(
        context,
        large: true,
        isScrollControlled: true,
        backgroundColor: AppColors.scrimTransparent,
        elevation: 0,
        builder: (_) => const AssistantOnboardingSheet(),
      );

  @override
  State<AssistantOnboardingSheet> createState() =>
      _AssistantOnboardingSheetState();
}

class _AssistantOnboardingSheetState extends State<AssistantOnboardingSheet> {
  static const double _perch = AssistantOnboardingPerch.size;

  /// How deep the mascot sits into the card.
  static const double _sink = AppSize.s44;
  static const double _underPerch = AppSpacing.s12;
  static const double _dotsGap = AppSpacing.s12;
  static const double _dots = AppSize.s4;
  static const double _footerGap = AppSpacing.s16;
  static const double _footer = AppSize.s48;
  static const double _bottomGap = AppSpacing.s12;

  /// Everything around the pages.
  static const double _chrome =
      _perch +
      _underPerch +
      _dotsGap +
      _dots +
      _footerGap +
      _footer +
      _bottomGap;
  static const double _pageShare = 0.52;
  static const double _minPage = AppSize.s300;
  static const double _maxPage = AppSize.s480;

  /// Finger travel before the mascot's eyes follow it again.
  static const double _moveStep = AppSize.s24;
  static const BoxDecoration _card = BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.r1)),
  );
  static final int _count = AssistantOnboardingStep.values.length;

  final PageController _pages = PageController();
  final ValueNotifier<Offset?> _touches = ValueNotifier<Offset?>(null);
  int _step = 0;
  AssistantMascotMood _mood = AssistantMascotMood.happy;
  int _cheers = 0;
  int _waves = 0;

  /// Steps left behind in this opening: their demos do not play again.
  final Set<int> _played = <int>{};

  /// The page is changing because Next was tapped (its button already
  /// ticked): no second haptic for the same gesture.
  bool _paging = false;

  AssistantOnboardingStep get _current => AssistantOnboardingStep.values[_step];

  String _stepLabel(int index) => 'assistant.onboarding_step'.tr(
    namedArgs: {'current': '${index + 1}', 'total': '$_count'},
  );

  void _onPage(int index) {
    if (!_paging) Haptics.pick();
    _paging = false;
    setState(() {
      _played.add(_step);
      _step = index;
    });
    final step = AssistantOnboardingStep.values[index];
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        '${_stepLabel(index)}. ${step.titleKey.tr()}',
        Directionality.of(context),
      ),
    );
  }

  void _onCue(AssistantOnboardingCue cue) {
    setState(() {
      _mood = cue.mood;
      if (cue.hops) _cheers++;
      if (cue.waves) _waves++;
    });
  }

  void _next() {
    final next = _step + 1;
    if (next >= _count) return;
    _paging = true;
    MotionGuard.pageTo(context, _pages, next, duration: AppMotion.slow);
  }

  void _close(AssistantOnboardingExit exit, [AssistantStarter? starter]) =>
      context.pop(AssistantOnboardingResult(exit, starter: starter));

  void _onPointer(PointerEvent event) {
    final last = _touches.value;
    if (event is PointerMoveEvent &&
        last != null &&
        (event.position - last).distance < _moveStep) {
      return;
    }
    _touches.value = event.position;
  }

  @override
  void dispose() {
    _pages.dispose();
    _touches.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final insets = MediaQuery.paddingOf(context);
    final room = size.height - insets.top - insets.bottom - _chrome;
    final wanted = (size.height * _pageShare).clamp(_minPage, _maxPage);
    final pageHeight = math.max(0.0, math.min(room, wanted));
    return Semantics(
      namesRoute: true,
      explicitChildNodes: true,
      label: 'assistant.onboarding_title'.tr(),
      child: Listener(
        onPointerDown: _onPointer,
        onPointerMove: _onPointer,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: _perch - _sink),
              child: DecoratedBox(
                decoration: _card,
                child: Padding(
                  padding: EdgeInsets.only(bottom: insets.bottom + _bottomGap),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: _sink + _underPerch),
                      SizedBox(
                        height: pageHeight,
                        child: PageView(
                          controller: _pages,
                          onPageChanged: _onPage,
                          children: [
                            for (final (index, step)
                                in AssistantOnboardingStep.values.indexed)
                              AssistantOnboardingPage(
                                step: step,
                                active: index == _step,
                                played: _played.contains(index),
                                onCue: _onCue,
                                onStarter: (starter) => _close(
                                  AssistantOnboardingExit.chat,
                                  starter,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: _dotsGap),
                      Semantics(
                        label: _stepLabel(_step),
                        child: ExcludeSemantics(
                          child: PagingDots(controller: _pages, count: _count),
                        ),
                      ),
                      const SizedBox(height: _footerGap),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s20,
                        ),
                        child: AssistantOnboardingFooter(
                          last: _current.isLast,
                          onNext: _next,
                          onSkip: () => _close(AssistantOnboardingExit.skipped),
                          onStart: () => _close(AssistantOnboardingExit.chat),
                          onLater: () => _close(AssistantOnboardingExit.later),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: 0,
              start: 0,
              end: 0,
              child: Center(
                child: AssistantOnboardingPerch(
                  mood: _mood,
                  cheer: _cheers,
                  wave: _waves,
                  pages: _pages,
                  touches: _touches,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
