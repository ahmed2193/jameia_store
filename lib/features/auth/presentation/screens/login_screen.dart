import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/design/keeta_assets.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/login_cubit.dart';

/// KeeTa `passport_login` — faithful clone of the Mach Pro login/signup page.
///
/// Layout (top → bottom): brand-yellow hero with the KeeTa wordmark, a phone
/// field with a `+965` country-code prefix, the primary Continue CTA, an "or"
/// divider, the three social sign-in buttons (Google / Apple / Facebook) and the
/// terms/privacy fine print pinned to the bottom.
///
/// The page cubit is resolved from the service locator (`sl<LoginCubit>()`),
/// which wires it to the `AuthRepository` over the offline auth chain.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LoginCubit>(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _phone = TextEditingController();

  @override
  void initState() {
    super.initState();
    _phone.addListener(
      () => context.read<LoginCubit>().phoneChanged(_phone.text),
    );
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  // Forward both the phone-submit and social-button taps through one path.
  void _continue() {
    context.read<LoginCubit>().continueWithSocial();
    Navigator.pushReplacementNamed(context, Routes.shell);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ContentClamp(
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: _BrandHero()),
              SliverPadding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.s24,
                ),
                sliver: SliverList.list(
                  children: [
                    const SizedBox(height: AppSpacing.s32),
                    StaggerEntrance(
                      index: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'auth.log_in_or_sign_up'.tr(),
                            style: AppTextStyles.displaySmall.copyWith(
                              fontWeight: AppTextStyles.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s6),
                          Text(
                            'auth.enter_phone_to_continue'.tr(),
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    StaggerEntrance(
                      index: 1,
                      child: _PhoneField(controller: _phone),
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    const StaggerEntrance(index: 2, child: _ContinueButton()),
                    const SizedBox(height: AppSpacing.s24),
                    const StaggerEntrance(index: 3, child: _OrDivider()),
                    const SizedBox(height: AppSpacing.s24),
                    StaggerEntrance(
                      index: 4,
                      child: _SocialButton(
                        icon: KeetaAssets.loginGoogle,
                        label: 'auth.continue_with'.tr(
                          namedArgs: {'provider': 'Google'},
                        ),
                        onTap: _continue,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    StaggerEntrance(
                      index: 5,
                      child: _SocialButton(
                        icon: KeetaAssets.loginApple,
                        label: 'auth.continue_with'.tr(
                          namedArgs: {'provider': 'Apple'},
                        ),
                        onTap: _continue,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    StaggerEntrance(
                      index: 6,
                      child: _SocialButton(
                        icon: KeetaAssets.loginFacebook,
                        label: 'auth.continue_with'.tr(
                          namedArgs: {'provider': 'Facebook'},
                        ),
                        onTap: _continue,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s24),
                  ],
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: AppSpacing.s24,
                      end: AppSpacing.s24,
                      top: AppSpacing.s16,
                      bottom: AppSpacing.s16 + bottomInset,
                    ),
                    child: const _TermsText(),
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

/// Brand-yellow top hero with the KeeTa logo + wordmark.
class _BrandHero extends StatelessWidget {
  const _BrandHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s24,
        vertical: AppSpacing.s40,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.brandDarkBg],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.s24),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.r4),
            child: Image.asset(
              KeetaAssets.logo,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            'JameiaMart',
            style: AppTextStyles.displayLarge.copyWith(
              fontWeight: AppTextStyles.bold,
              color: AppColors.brandForeground,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'auth.food_delivery_fast'.tr(),
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.brandForeground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Phone field: a separate `+965` country-code box and the number input box
/// sit side-by-side (matching the real bundle's two 45dp / 6dp-radius blocks),
/// with an inline validation error line below.
class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Country-code selector box (flag + dial code + caret).
            Container(
              height: 45,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s12,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.r6),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🇰🇼', style: AppTextStyles.headingSmall),
                  const SizedBox(width: AppSpacing.s6),
                  Text(
                    '+965',
                    style: AppTextStyles.headingSmall.copyWith(
                      fontWeight: AppTextStyles.bold,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s4),
                  Image.asset(
                    KeetaAssets.loginArrowDown,
                    width: 12,
                    height: 12,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            // Number input box.
            Expanded(
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.r6),
                  border: Border.all(color: AppColors.divider),
                ),
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  maxLength: 8,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppTextStyles.headingSmall,
                  decoration: InputDecoration(
                    counterText: '',
                    isCollapsed: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.s12,
                      vertical: 14,
                    ),
                    hintText: 'auth.phone_number_hint'.tr(),
                    hintStyle: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.tertiaryText,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Inline validation error (#E51728, 12dp, 6dp top margin in bundle).
        BlocBuilder<LoginCubit, LoginState>(
          buildWhen: (a, b) => a.phone != b.phone,
          builder: (context, state) {
            final showError = state.phone.isNotEmpty && state.phone.length != 8;
            // Slide/fade the validation line in as it appears, gated so the
            // OS reduced-motion flag collapses it to an instant cut.
            return AnimatedSwitcher(
              duration: MotionGuard.duration(context, AppMotion.fast),
              switchInCurve: MotionGuard.curve(context, AppMotion.signature),
              switchOutCurve: MotionGuard.curve(context, AppMotion.exit),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1,
                  child: child,
                ),
              ),
              child: showError
                  ? Padding(
                      key: const ValueKey('phone-error'),
                      padding: const EdgeInsetsDirectional.only(
                        top: AppSpacing.s6,
                      ),
                      child: Text(
                        'auth.phone_invalid'.tr(),
                        style: AppTextStyles.captionLarge.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            );
          },
        ),
      ],
    );
  }
}

/// Primary Continue CTA — only enabled once the phone field is valid.
class _ContinueButton extends StatelessWidget {
  const _ContinueButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (a, b) => a.canContinue != b.canContinue,
      builder: (context, state) {
        return AppButton(
          label: 'auth.continue_btn'.tr(),
          enabled: state.canContinue,
          onPressed: () {
            context.read<LoginCubit>().submit();
            Navigator.pushReplacementNamed(context, Routes.shell);
          },
        );
      },
    );
  }
}

/// Centered "or" divider between phone and social sign-in.
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: ThinDivider()),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s12,
          ),
          child: Text(
            'auth.or'.tr(),
            style: AppTextStyles.captionLarge.copyWith(
              color: AppColors.tertiaryText,
            ),
          ),
        ),
        const Expanded(child: ThinDivider()),
      ],
    );
  }
}

/// Outlined social sign-in button with a leading brand icon.
class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Passive press-scale (no onTap) so the InkWell keeps owning the gesture +
    // ripple while the whole button still gives KeeTa's subtle press feel.
    return PressScale(
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r4),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.r4),
          onTap: onTap,
          child: Container(
            height: 50,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s16,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.r4),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Image.asset(icon, width: 22, height: 22, fit: BoxFit.contain),
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: AppTextStyles.headingSmall.copyWith(
                        fontWeight: AppTextStyles.medium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Terms-of-service / privacy-policy fine print with tappable links.
class _TermsText extends StatefulWidget {
  const _TermsText();

  @override
  State<_TermsText> createState() => _TermsTextState();
}

class _TermsTextState extends State<_TermsText> {
  late final TapGestureRecognizer _terms;
  late final TapGestureRecognizer _privacy;

  @override
  void initState() {
    super.initState();
    _terms = TapGestureRecognizer()
      ..onTap = () => _open('auth.terms_of_service'.tr());
    _privacy = TapGestureRecognizer()
      ..onTap = () => _open('auth.privacy_policy'.tr());
  }

  void _open(String label) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('auth.opening_x'.tr(namedArgs: {'label': label})),
        ),
      );
  }

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = AppTextStyles.captionLarge.copyWith(
      color: AppColors.tertiaryText,
      height: 1.4,
    );
    final link = base.copyWith(
      color: AppColors.link,
      fontWeight: AppTextStyles.medium,
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: 'auth.terms_prefix'.tr()),
          TextSpan(
            text: 'auth.terms_of_service'.tr(),
            style: link,
            recognizer: _terms,
          ),
          TextSpan(text: 'auth.and_conjunction'.tr()),
          TextSpan(
            text: 'auth.privacy_policy'.tr(),
            style: link,
            recognizer: _privacy,
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
