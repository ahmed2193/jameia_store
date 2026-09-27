import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../cubit/pro_membership_cubit.dart';
import '../cubit/pro_membership_state.dart';
import 'pro_success_sheet.dart';

/// Answers what the customer just did on the Pro page, once per outcome:
/// a new subscription bursts confetti over [child] and, as the burst peaks,
/// opens the welcome sheet; a cancelled renewal is toasted. Either way the
/// session is re-read so `isPro` (member prices everywhere) follows. A
/// failure on the loaded page is answered too — offline, a failed reload
/// only nudges the banner and a failed subscribe / cancel says it needs the
/// internet (a failed first load is the body's error view instead).
class ProOutcomeListener extends StatefulWidget {
  const ProOutcomeListener({super.key, required this.child});

  final Widget child;

  @override
  State<ProOutcomeListener> createState() => _ProOutcomeListenerState();
}

class _ProOutcomeListenerState extends State<ProOutcomeListener> {
  static const List<Color> _confetti = [
    ...AppColors.proGradient,
    AppColors.proLime,
    AppColors.proAmber,
  ];

  /// Bumped per new subscription; each new value plays the burst once.
  int _celebrations = 0;

  Future<void> _celebrate() async {
    setState(() => _celebrations++);
    Haptics.success();
    // The sheet's scrim would dim the burst: let it peak first.
    await Future<void>.delayed(
      MotionGuard.duration(context, AppMotion.confetti ~/ 2),
    );
    if (!mounted) return;
    // Scroll-controlled: the sheet takes the height its content needs
    // instead of being capped at 9/16 of the screen (a small phone at large
    // text cut its button off).
    await showJameiaBottomSheet<void>(
      context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (_) => const ProSuccessSheet(),
    );
  }

  void _onState(BuildContext context, ProMembershipState state) {
    final outcome = state.outcome;
    if (outcome != null) {
      switch (outcome) {
        case ProMembershipOutcome.subscribed:
          unawaited(_celebrate());
        case ProMembershipOutcome.cancelled:
          showJameiaSnackBar(context, 'pro.cancelled_toast'.tr());
      }
      // The reply carries no customer object: re-read the session so
      // `isPro` (member prices everywhere) follows.
      context.read<AuthSessionCubit>().restore();
      return;
    }
    final failure = state.failure;
    // A failed first load is rendered inline by the body, not toasted.
    if (failure == null || state.status == ProMembershipStatus.error) return;
    showFailureSnackBar(context, failure, action: state.actionFailed);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProMembershipCubit, ProMembershipState>(
      listenWhen: (previous, current) =>
          current.outcome != null ||
          (current.failure != null && previous.failure != current.failure),
      listener: _onState,
      child: ConfettiBurst(
        playKey: _celebrations == 0 ? null : _celebrations,
        colors: _confetti,
        child: widget.child,
      ),
    );
  }
}
