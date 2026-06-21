import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/data/keeta_repository.dart';
import '../../../../core/design/keeta_assets.dart';
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
/// The page cubit is constructed INLINE (not registered in the service locator)
/// per the project's page-scoped cubit convention.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginCubit(sl<KeetaRepository>()),
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
        () => context.read<LoginCubit>().phoneChanged(_phone.text));
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
                    horizontal: AppSpacing.s24),
                sliver: SliverList.list(
                  children: [
                    const SizedBox(height: AppSpacing.s32),
                    Text(
                      'Log in or sign up',
                      style: AppTextStyles.displaySmall
                          .copyWith(fontWeight: AppTextStyles.bold),
                    ),
                    const SizedBox(height: AppSpacing.s6),
                    Text(
                      'Enter your phone number to continue',
                      style: AppTextStyles.bodyLarge
                          .copyWith(color: AppColors.secondaryText),
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    _PhoneField(controller: _phone),
                    const SizedBox(height: AppSpacing.s24),
                    const _ContinueButton(),
                    const SizedBox(height: AppSpacing.s24),
                    const _OrDivider(),
                    const SizedBox(height: AppSpacing.s24),
                    _SocialButton(
                      icon: KeetaAssets.loginGoogle,
                      label: 'Continue with Google',
                      onTap: _continue,
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    _SocialButton(
                      icon: KeetaAssets.loginApple,
                      label: 'Continue with Apple',
                      onTap: _continue,
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    _SocialButton(
                      icon: KeetaAssets.loginFacebook,
                      label: 'Continue with Facebook',
                      onTap: _continue,
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
          horizontal: AppSpacing.s24, vertical: AppSpacing.s40),
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
            'KeeTa',
            style: AppTextStyles.displayLarge.copyWith(
              fontWeight: AppTextStyles.bold,
              color: AppColors.brandForeground,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Food delivery, fast',
            style: AppTextStyles.bodyLarge
                .copyWith(color: AppColors.brandForeground),
          ),
        ],
      ),
    );
  }
}

/// Phone field with the `+965` country-code prefix block.
class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.mediumBackground,
        borderRadius: BorderRadius.circular(AppRadius.r4),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🇰🇼', style: AppTextStyles.headingMedium),
                const SizedBox(width: AppSpacing.s6),
                Text(
                  '+965',
                  style: AppTextStyles.headingMedium
                      .copyWith(fontWeight: AppTextStyles.bold),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 24, color: AppColors.divider),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              maxLength: 8,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTextStyles.headingMedium,
              decoration: InputDecoration(
                counterText: '',
                isCollapsed: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.s12),
                hintText: 'Phone number',
                hintStyle: AppTextStyles.headingMedium
                    .copyWith(color: AppColors.tertiaryText),
              ),
            ),
          ),
        ],
      ),
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
          label: 'Continue',
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
          padding:
              const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.s12),
          child: Text('or',
              style: AppTextStyles.captionLarge
                  .copyWith(color: AppColors.tertiaryText)),
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
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.r4),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r4),
        onTap: onTap,
        child: Container(
          height: 50,
          padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s16),
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
                    style: AppTextStyles.headingSmall
                        .copyWith(fontWeight: AppTextStyles.medium),
                  ),
                ),
              ),
              const SizedBox(width: 22),
            ],
          ),
        ),
      ),
    );
  }
}

/// Terms-of-service / privacy-policy fine print.
class _TermsText extends StatelessWidget {
  const _TermsText();

  @override
  Widget build(BuildContext context) {
    final base = AppTextStyles.captionLarge
        .copyWith(color: AppColors.tertiaryText, height: 1.4);
    final link = base.copyWith(
        color: AppColors.link, fontWeight: AppTextStyles.medium);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'By continuing, you agree to KeeTa’s '),
          TextSpan(text: 'Terms of Service', style: link),
          const TextSpan(text: ' and '),
          TextSpan(text: 'Privacy Policy', style: link),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
