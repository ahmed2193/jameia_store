import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../cubit/login_cubit.dart';
import '../auth_back_button.dart';
import 'login_brand_hero.dart';
import 'login_continue_button.dart';
import 'login_expired_banner.dart';
import 'login_heading.dart';
import 'login_hero_collapse.dart';
import 'login_or_divider.dart';
import 'login_phone_field.dart';
import 'login_social_section.dart';
import 'login_terms_text.dart';

/// Scrollable login layout: the brand card (folds away with the keyboard),
/// heading, phone unit and Continue right under it — so the CTA sits just
/// above the keyboard — then the social buttons and the fine print pinned
/// to the bottom. Owns the phone controller + focus, forwards edits to
/// [LoginCubit], and decides when an invalid number is pointed out.
class LoginBody extends StatefulWidget {
  const LoginBody({super.key, this.sessionExpired = false});

  final bool sessionExpired;

  @override
  State<LoginBody> createState() => _LoginBodyState();
}

class _LoginBodyState extends State<LoginBody> {
  /// Heading → phone → CTA cascade (60 ms apart, a short rise).
  static const Duration _stagger = Duration(milliseconds: 60);
  static const Offset _rise = Offset(0, 0.15);

  final TextEditingController _phone = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();

  /// The validation line is shown once the user was told (blur with a
  /// partial number, or a tap on the disabled CTA) — never mid-typing.
  final ValueNotifier<bool> _errorRevealed = ValueNotifier<bool>(false);

  /// Taps on the disabled CTA; each one shakes the phone unit.
  final ValueNotifier<int> _nudges = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _phone.addListener(_onPhoneChanged);
    _phoneFocus.addListener(_onFocusChanged);
  }

  void _onPhoneChanged() =>
      context.read<LoginCubit>().phoneChanged(_phone.text);

  void _onFocusChanged() {
    if (_phoneFocus.hasFocus) return;
    if (context.read<LoginCubit>().state.showPhoneError) {
      _errorRevealed.value = true;
    }
  }

  /// Continue was refused: say why, shake the number, keep the keyboard up.
  void _nudge() {
    Haptics.warning();
    _errorRevealed.value = true;
    _nudges.value++;
    _phoneFocus.requestFocus();
  }

  /// The keyboard's done key: continue when possible, otherwise nudge.
  void _submit() {
    final cubit = context.read<LoginCubit>();
    cubit.state.canContinue ? cubit.submit() : _nudge();
  }

  @override
  void dispose() {
    _phoneFocus
      ..removeListener(_onFocusChanged)
      ..dispose();
    _phone
      ..removeListener(_onPhoneChanged)
      ..dispose();
    _errorRevealed.dispose();
    _nudges.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The Scaffold already resizes for the keyboard, so no inset math here.
    return CustomScrollView(
      slivers: [
        const SliverPadding(
          padding: EdgeInsetsDirectional.fromSTEB(
            AppSpacing.s16,
            AppSpacing.s8,
            AppSpacing.s16,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuthBackButton(),
                LoginHeroCollapse(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(top: AppSpacing.s8),
                    child: LoginBrandHero(),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s24,
          ),
          sliver: SliverList.list(
            children: [
              const SizedBox(height: AppSpacing.s28),
              if (widget.sessionExpired) ...[
                const LoginExpiredBanner(),
                const SizedBox(height: AppSpacing.s20),
              ],
              const StaggerEntrance(
                index: 0,
                stagger: _stagger,
                beginOffset: _rise,
                child: LoginHeading(),
              ),
              const SizedBox(height: AppSpacing.s20),
              StaggerEntrance(
                index: 1,
                stagger: _stagger,
                beginOffset: _rise,
                child: LoginPhoneField(
                  controller: _phone,
                  focusNode: _phoneFocus,
                  errorRevealed: _errorRevealed,
                  nudges: _nudges,
                  onSubmitted: _submit,
                ),
              ),
              const SizedBox(height: AppSpacing.s20),
              StaggerEntrance(
                index: 2,
                stagger: _stagger,
                beginOffset: _rise,
                child: LoginContinueButton(onBlocked: _nudge),
              ),
            ],
          ),
        ),
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              AppSpacing.s24,
              AppSpacing.s28,
              AppSpacing.s24,
              AppSpacing.s16,
            ),
            child: Column(
              children: [
                StaggerEntrance(
                  index: 3,
                  stagger: _stagger,
                  child: LoginOrDivider(),
                ),
                SizedBox(height: AppSpacing.s20),
                LoginSocialSection(firstStaggerIndex: 4, stagger: _stagger),
                Spacer(),
                SizedBox(height: AppSpacing.s24),
                LoginTermsText(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
