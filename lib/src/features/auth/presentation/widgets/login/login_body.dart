import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/routes/route_args/login_args.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/entrance_cascade.dart';
import '../../../../../core/motion/entrance_cascade_item.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/widgets/brand_sheet_fold.dart';
import '../../cubit/login_cubit.dart';
import 'login_continue_button.dart';
import 'login_expired_banner.dart';
import 'login_guest_button.dart';
import 'login_offer_card.dart';
import 'login_or_divider.dart';
import 'login_phone_row.dart';
import 'login_social_section.dart';
import 'login_terms_text.dart';
import 'login_welcome_heading.dart';

/// What the sign-in sheet holds, top to bottom: the offer card (or, after
/// an expired session, why the customer is here) — it folds away with the
/// header while the keyboard is up — "Welcome", the phone unit with
/// Continue right under it (so it sits just above the keyboard) and a plain
/// "Continue as guest" link, then "or with" the other ways in, and the fine
/// print at the foot. Everything cascades in as the sheet rises.
///
/// Owns the phone controller and focus, forwards edits to [LoginCubit], and
/// decides when an invalid number is pointed out.
class LoginBody extends StatefulWidget {
  const LoginBody({super.key, this.args = const LoginArgs()});

  /// Why sign-in opened, and the way back the guest link takes.
  final LoginArgs args;

  @override
  State<LoginBody> createState() => _LoginBodyState();
}

class _LoginBodyState extends State<LoginBody> {
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
    Haptics.refuse();
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
    // The route (and the sheet rising in it) is the entrance: the cascade
    // only plays when this page is already in place.
    return EntranceCascade(
      child: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.s24,
                AppSpacing.s24,
                AppSpacing.s24,
                0,
              ),
              sliver: SliverList.list(
                children: [
                  BrandSheetFold(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        bottom: AppSpacing.s24,
                      ),
                      child: EntranceCascadeItem(
                        index: 0,
                        child: widget.args.sessionExpired
                            ? const LoginExpiredBanner()
                            : const LoginOfferCard(),
                      ),
                    ),
                  ),
                  const EntranceCascadeItem(
                    index: 1,
                    child: LoginWelcomeHeading(),
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  EntranceCascadeItem(
                    index: 2,
                    child: LoginPhoneRow(
                      controller: _phone,
                      focusNode: _phoneFocus,
                      errorRevealed: _errorRevealed,
                      nudges: _nudges,
                      onSubmitted: _submit,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s20),
                  EntranceCascadeItem(
                    index: 3,
                    child: LoginContinueButton(onBlocked: _nudge),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  EntranceCascadeItem(
                    index: 4,
                    child: LoginGuestButton(args: widget.args),
                  ),
                ],
              ),
            ),
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.s24,
                  AppSpacing.s12,
                  AppSpacing.s24,
                  AppSpacing.s16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EntranceCascadeItem(index: 5, child: LoginOrDivider()),
                    SizedBox(height: AppSpacing.s16),
                    LoginSocialSection(firstCascadeIndex: 6),
                    Spacer(),
                    SizedBox(height: AppSpacing.s24),
                    EntranceCascadeItem(index: 8, child: LoginTermsText()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
