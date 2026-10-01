import 'package:flutter/material.dart';

import '../../../../../core/widgets/hero_bottom_bar.dart';
import 'profile_save_button.dart';

/// The foot of the profile form holding Save: the shared [HeroBottomBar]
/// (white, a hairline shadow on top). It sits under the scrolling fields —
/// above the keyboard while one is being edited — so Save is always one tap
/// away.
class ProfileSaveBar extends StatelessWidget {
  const ProfileSaveBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const HeroBottomBar(child: ProfileSaveButton());
  }
}
