import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/locale_swap_veil.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/navigation/app_keys.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_segmented_control.dart';
import '../../cubit/setting_cubit.dart';
import 'settings_language.dart';
import 'settings_tile.dart';
import 'settings_tone.dart';

/// "Language" row with an EN / العربية segmented control under the title
/// (full width, so both labels fit at any text size). A tap glides the
/// thumb to the new language first; once it lands, the switch itself runs
/// under [LocaleSwapVeil] — one calm veil over the whole app while it
/// rebuilds and mirrors, never two app trees on screen. The success haptic
/// lands once the veil has lifted, on the language the customer now sees.
class SettingsLanguageTile extends StatefulWidget {
  const SettingsLanguageTile({
    super.key,
    required this.title,
    required this.languageCode,
  });

  final String title;

  /// The language the app shows right now.
  final String languageCode;

  @override
  State<SettingsLanguageTile> createState() => _SettingsLanguageTileState();
}

class _SettingsLanguageTileState extends State<SettingsLanguageTile> {
  static const double _controlHeight = AppSize.s40;

  /// Where the thumb sits while a switch runs (the app still shows the old
  /// language underneath).
  SettingsLanguage? _pending;

  Future<void> _select(SettingsLanguage language) async {
    if (_pending != null) return;
    setState(() => _pending = language);
    final settings = context.read<SettingCubit>();
    // The switch runs after two waits, and a back gesture while the veil is
    // up closes Settings: it runs on the app's navigator context, which
    // outlives every page — never on this row's.
    final appContext = navigatorKey.currentContext ?? context;
    // Let the thumb land before the veil covers it.
    await Future<void>.delayed(
      MotionGuard.duration(context, AppSprings.calm.duration),
    );
    if (!mounted) return;
    var switched = false;
    try {
      await LocaleSwapVeil.run(
        context,
        color: AppColors.mediumBackground,
        commit: () async {
          switched = await settings.changeLanguage(appContext, language.code);
        },
      );
      if (switched) Haptics.done();
    } finally {
      if (mounted) setState(() => _pending = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy =
        _pending != null ||
        context.select<SettingCubit, bool>((c) => c.state.isChangingLanguage);
    return SettingsTile(
      icon: HeroIcons.language,
      tone: SettingsTone.sky,
      title: widget.title,
      below: HeroSegmentedControl<SettingsLanguage>(
        values: SettingsLanguage.values,
        selected: _pending ?? SettingsLanguage.of(widget.languageCode),
        labelOf: (language) => language.labelKey.tr(),
        onChanged: busy ? null : _select,
        height: _controlHeight,
      ),
    );
  }
}
