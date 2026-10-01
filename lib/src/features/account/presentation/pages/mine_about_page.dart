import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/widgets/hero_title_bar.dart';
import '../widgets/about/about_body.dart';

/// Mine → About: the app icon and version, the terms / privacy / licenses /
/// rate-us rows, Hero's social profiles and the copyright line. Static
/// content: no cubit.
class MineAboutPage extends StatelessWidget {
  const MineAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      appBar: HeroTitleBar(title: 'account.about'.tr()),
      body: const AboutBody(),
    );
  }
}
