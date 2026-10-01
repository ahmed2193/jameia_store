import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/hero_assets.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/press_scale.dart';

/// The welcome-gift card of the current language (the text is baked into the
/// art): the GIF plays its pop-in once and holds; under reduced motion the
/// held frame shows straight away. The whole card is the "Order now" button.
class HomeWelcomeGiftArt extends StatefulWidget {
  const HomeWelcomeGiftArt({super.key, required this.onTap});

  final VoidCallback onTap;

  /// The art is 640 × 844.
  static const double aspectRatio = 640 / 844;

  static const String _arabic = 'ar';

  static String gifFor(String languageCode) => languageCode == _arabic
      ? HeroAssets.popupFirstOrderFreeDeliveryAr
      : HeroAssets.popupFirstOrderFreeDeliveryEn;

  static String stillFor(String languageCode) => languageCode == _arabic
      ? HeroAssets.popupFirstOrderFreeDeliveryArStill
      : HeroAssets.popupFirstOrderFreeDeliveryEnStill;

  @override
  State<HomeWelcomeGiftArt> createState() => _HomeWelcomeGiftArtState();
}

class _HomeWelcomeGiftArtState extends State<HomeWelcomeGiftArt> {
  /// The GIF this card played: dropped from the image cache on close, so the
  /// next showing plays the pop-in again instead of the held frame, and its
  /// decoded frames do not outlive the popup.
  AssetImage? _played;

  @override
  void dispose() {
    final played = _played;
    if (played != null) unawaited(played.evict());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = context.locale.languageCode;
    final still = MotionGuard.reduced(context);
    final image = AssetImage(
      still
          ? HomeWelcomeGiftArt.stillFor(languageCode)
          : HomeWelcomeGiftArt.gifFor(languageCode),
    );
    if (!still) _played = image;
    return Semantics(
      button: true,
      label: 'home.welcome_popup_label'.tr(),
      excludeSemantics: true,
      child: PressScale(
        onTap: widget.onTap,
        child: AspectRatio(
          aspectRatio: HomeWelcomeGiftArt.aspectRatio,
          child: Image(
            image: image,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}
