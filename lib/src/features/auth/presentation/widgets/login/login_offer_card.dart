import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_waving_mark.dart';
import '../../cubit/login_cubit.dart';
import '../../cubit/login_state.dart';
import 'login_offer_words.dart';

/// The offer at the top of the sign-in sheet, like a food app's "first
/// order" card: the Hero bag flying on a warm cream card beside what signing
/// up gets today — the store's welcome points when it gives any ("Join Hero
/// and get 100 points!" · "For new customers only"), otherwise what an
/// account keeps for you. Nothing is promised the store does not give. The
/// words fade through in place when the store answers; the card keeps its
/// height.
class LoginOfferCard extends StatelessWidget {
  const LoginOfferCard({super.key});

  static const double _markSize = AppSize.s64;
  static const double _minHeight = AppSize.s96;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: kHeroPromoCream,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.r3)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _minHeight),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s12,
          ),
          child: Row(
            children: [
              const HeroWavingMark(size: _markSize),
              const SizedBox(width: AppSpacing.s16),
              Expanded(
                child: BlocSelector<LoginCubit, LoginState, int>(
                  selector: (state) => state.welcomeBonus,
                  builder: (context, bonus) => FadeThroughSwitcher(
                    stateKey: bonus,
                    alignment: AlignmentDirectional.centerStart,
                    child: LoginOfferWords(bonus: bonus),
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
