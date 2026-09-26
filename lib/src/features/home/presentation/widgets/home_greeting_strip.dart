import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/haptics.dart';
import '../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../domain/entities/home_greeting.dart';
import 'home_day_part_disc.dart';
import 'home_layout.dart';
import 'home_waving_hand.dart';

/// The hello at the top of the feed: the sky of the moment, "Good morning,
/// Sara" with a waving hand, and a line that fits the hour ("Start your day
/// with something fresh"). A tap on it waves back.
class HomeGreetingStrip extends StatefulWidget {
  const HomeGreetingStrip({super.key, this.clock = DateTime.now});

  /// What time it is; a test sets the hour.
  final DateTime Function() clock;

  @override
  State<HomeGreetingStrip> createState() => _HomeGreetingStripState();
}

class _HomeGreetingStripState extends State<HomeGreetingStrip> {
  /// Ticks once per tap on the greeting.
  final ValueNotifier<int> _waves = ValueNotifier<int>(0);

  @override
  void dispose() {
    _waves.dispose();
    super.dispose();
  }

  void _waveBack() {
    Haptics.tap();
    _waves.value++;
  }

  @override
  Widget build(BuildContext context) {
    final name = context.select<AuthSessionCubit, String>(
      (session) => session.state.customer?.givenName ?? '',
    );
    final greeting = HomeGreeting.at(widget.clock(), fullName: name);
    final hello = switch (greeting.dayPart) {
      HomeDayPart.morning => 'home.greeting_morning',
      HomeDayPart.afternoon => 'home.greeting_afternoon',
      HomeDayPart.evening => 'home.greeting_evening',
      HomeDayPart.night => 'home.greeting_night',
    }.tr();
    final hint = switch (greeting.dayPart) {
      HomeDayPart.morning => 'home.greeting_hint_morning',
      HomeDayPart.afternoon => 'home.greeting_hint_afternoon',
      HomeDayPart.evening => 'home.greeting_hint_evening',
      HomeDayPart.night => 'home.greeting_hint_night',
    }.tr();
    final title = greeting.hasName
        ? 'home.greeting_named'.tr(
            namedArgs: {'greeting': hello, 'name': greeting.firstName},
          )
        : hello;
    return GestureDetector(
      onTap: _waveBack,
      behavior: HitTestBehavior.opaque,
      // Waving back is a flourish; the words are what a screen reader needs.
      excludeFromSemantics: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          HomeLayout.gutter,
          AppSpacing.s4,
          HomeLayout.gutter,
          AppSpacing.s12,
        ),
        child: Row(
          children: [
            HomeDayPartDisc(dayPart: greeting.dayPart),
            const SizedBox(width: AppSpacing.s10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.headingMedium.copyWith(
                            fontWeight: AppTextStyles.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s6),
                      HomeWavingHand(trigger: _waves),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
