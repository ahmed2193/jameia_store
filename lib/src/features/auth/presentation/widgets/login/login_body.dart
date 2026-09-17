import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../cubit/login_cubit.dart';
import 'login_brand_hero.dart';
import 'login_continue_button.dart';
import 'login_expired_banner.dart';
import 'login_heading.dart';
import 'login_or_divider.dart';
import 'login_phone_field.dart';
import 'login_social_section.dart';
import 'login_terms_text.dart';

/// Scrollable login layout: hero, heading, phone field, CTA, social buttons
/// and the terms fine print pinned to the bottom. Owns the phone controller
/// and forwards edits to [LoginCubit].
class LoginBody extends StatefulWidget {
  const LoginBody({super.key, this.sessionExpired = false});

  final bool sessionExpired;

  @override
  State<LoginBody> createState() => _LoginBodyState();
}

class _LoginBodyState extends State<LoginBody> {
  final TextEditingController _phone = TextEditingController();

  @override
  void initState() {
    super.initState();
    _phone.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() =>
      context.read<LoginCubit>().phoneChanged(_phone.text);

  @override
  void dispose() {
    _phone
      ..removeListener(_onPhoneChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The Scaffold already resizes for the keyboard, so no inset math here.
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: LoginBrandHero()),
        SliverPadding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s24,
          ),
          sliver: SliverList.list(
            children: [
              const SizedBox(height: AppSpacing.s32),
              if (widget.sessionExpired) ...[
                const LoginExpiredBanner(),
                const SizedBox(height: AppSpacing.s16),
              ],
              const StaggerEntrance(index: 0, child: LoginHeading()),
              const SizedBox(height: AppSpacing.s24),
              StaggerEntrance(
                index: 1,
                child: LoginPhoneField(controller: _phone),
              ),
              const SizedBox(height: AppSpacing.s24),
              const StaggerEntrance(index: 2, child: LoginContinueButton()),
              const SizedBox(height: AppSpacing.s24),
              const StaggerEntrance(index: 3, child: LoginOrDivider()),
              const SizedBox(height: AppSpacing.s24),
              const LoginSocialSection(firstStaggerIndex: 4),
              const SizedBox(height: AppSpacing.s24),
            ],
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Align(
            alignment: AlignmentDirectional.bottomCenter,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s24,
                vertical: AppSpacing.s16,
              ),
              child: const LoginTermsText(),
            ),
          ),
        ),
      ],
    );
  }
}
