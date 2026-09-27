import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import 'splash_choreography.dart';
import 'splash_layout.dart';
import 'splash_wordmark.dart';

/// The localized tagline under the lockup, faded in on the choreography's
/// tagline beat. Live text (not baked into an image) so it follows the app
/// language and reads in RTL.
class SplashTagline extends StatelessWidget {
  const SplashTagline({
    super.key,
    required this.clock,
    required this.choreography,
    required this.wordmark,
  });

  final Animation<double> clock;
  final SplashChoreography choreography;

  /// The name above the tagline (its size sets where the tagline sits).
  final SplashWordmark wordmark;

  /// The tagline rises by this share of its own height as it fades in.
  static const Offset _riseFrom = Offset(0, 0.5);

  @override
  Widget build(BuildContext context) {
    final beat = clock.drive(
      CurveTween(curve: choreography.tagline(wordmark)),
    );
    // Touches pass through to the scene under it.
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = SplashLayout(constraints.biggest, wordmark);
          return Stack(
            children: [
              PositionedDirectional(
                top: layout.taglineTop,
                start: AppSpacing.s24,
                end: AppSpacing.s24,
                child: FadeTransition(
                  opacity: beat,
                  child: SlideTransition(
                    position: beat.drive(
                      Tween<Offset>(begin: _riseFrom, end: Offset.zero),
                    ),
                    child: Text(
                      'splash.tagline'.tr(),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: AppTextStyles.headingMedium.copyWith(
                        color: choreography.endPalette.letter,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
