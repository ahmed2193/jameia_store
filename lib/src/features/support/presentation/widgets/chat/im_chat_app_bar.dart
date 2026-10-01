import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/navigation/hero_snack_bar.dart';
import '../../../../../core/widgets/hero_bar_action.dart';
import '../../../../../core/widgets/hero_title_bar.dart';
import 'im_chat_rider_avatar.dart';

/// Chat title bar (the shared [HeroTitleBar]): the rider's avatar, name and
/// "Your rider", and a call action (a snack bar offline).
class ImChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ImChatAppBar({super.key, required this.riderName});

  final String riderName;

  @override
  Size get preferredSize => const Size.fromHeight(HeroTitleBar.height);

  @override
  Widget build(BuildContext context) {
    return HeroTitleBar(
      title: riderName,
      subtitle: 'support.your_rider'.tr(),
      titleLeading: const ImChatRiderAvatar(),
      actions: [
        HeroBarAction(
          icon: HeroIcons.phone,
          tooltip: 'support.call_rider'.tr(),
          onPressed: () => showHeroSnackBar(
            context,
            'support.calling'.tr(namedArgs: {'name': riderName}),
          ),
        ),
      ],
    );
  }
}
