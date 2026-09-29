import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/success_beat.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/widgets/connectivity_scope.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../domain/entities/profile_field.dart';
import '../../cubit/profile_cubit.dart';
import '../../cubit/profile_state.dart';

/// What the edit-profile screen does besides drawing the form:
/// - every customer record the server hands back updates the app session;
/// - a save: success haptic, the button's check held for a beat, then the
///   "updated" (or "you earned N points") message and back;
/// - a backend rejection: warning haptic + the message (a failed first load
///   is rendered inline by the body instead);
/// - a save refused for an invalid field: warning haptic + the error read
///   out to screen readers (the field shakes and takes the focus itself);
/// - the draft reaching 100 %: one success haptic with the ring's check.
class ProfileEditListener extends StatelessWidget {
  const ProfileEditListener({super.key, required this.child});

  final Widget child;

  Future<void> _onSaved(BuildContext context, ProfileState state) async {
    Haptics.done();
    final bonus = state.bonusEarned;
    final message = bonus > 0
        ? 'profile.profile_bonus_earned'.tr(namedArgs: {'pts': '$bonus'})
        : 'profile.saved'.tr();
    await SuccessBeat.hold(context);
    if (!context.mounted) return;
    showHeroSnackBar(context, message, tone: HeroSnackTone.success);
    context.pop();
  }

  void _onRefused(BuildContext context, ProfileState state) {
    Haptics.refuse();
    final message = switch (state.firstInvalidField) {
      ProfileField.name => 'profile.name_required'.tr(),
      ProfileField.email => 'profile.email_invalid'.tr(),
      _ => null,
    };
    if (message == null) return;
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ProfileCubit, ProfileState>(
          listenWhen: (previous, current) =>
              previous.customer != current.customer && current.customer != null,
          listener: (context, state) =>
              context.read<AuthSessionCubit>().updateCustomer(state.customer!),
        ),
        BlocListener<ProfileCubit, ProfileState>(
          listenWhen: (previous, current) =>
              !previous.isSaved && current.isSaved,
          listener: (context, state) => unawaited(_onSaved(context, state)),
        ),
        BlocListener<ProfileCubit, ProfileState>(
          // A failed first load is rendered inline by the body, not toasted.
          listenWhen: (previous, current) =>
              current.failure != null &&
              previous.failure != current.failure &&
              current.customer != null,
          listener: (context, state) {
            // Offline, the banner's nudge is the haptic.
            if (!ConnectivityScope.readIsOffline(context)) Haptics.refuse();
            // A failed save keeps every field as typed; a reload is a read.
            showFailureSnackBar(
              context,
              state.failure!,
              action: state.status == ProfileStatus.error,
            );
          },
        ),
        BlocListener<ProfileCubit, ProfileState>(
          listenWhen: (previous, current) =>
              previous.rejectedSubmits != current.rejectedSubmits,
          listener: _onRefused,
        ),
        BlocListener<ProfileCubit, ProfileState>(
          // Only a completion the customer typed / picked (a reload that
          // lands complete stays quiet).
          listenWhen: (previous, current) =>
              current.isDirty &&
              !previous.completion.isComplete &&
              current.completion.isComplete,
          listener: (_, _) => Haptics.done(),
        ),
      ],
      child: child,
    );
  }
}
