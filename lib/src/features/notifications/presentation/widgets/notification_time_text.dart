import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';

/// When a notification arrived, as compact as the distance allows: the time
/// today, month + day + time this year, a full date before that. Formats
/// through `intl` in the active locale (Arabic month names and digits).
class NotificationTimeText extends StatelessWidget {
  const NotificationTimeText({super.key, required this.time});

  final DateTime time;

  static const String _fallbackLanguage = 'en';
  static const String _fallbackLocale = 'en_US';

  /// `DateFormat` parses its pattern on construction and a list builds dozens
  /// of rows, so each (shape, locale) formatter is built once.
  static final Map<String, DateFormat> _formats = {};

  static DateFormat _cached(
    String shape,
    String locale,
    DateFormat Function() build,
  ) => _formats.putIfAbsent('$shape|$locale', build);

  /// Pure so tests can pin [now] and the language.
  static String format(
    DateTime time, {
    required DateTime now,
    required String languageCode,
  }) {
    final local = time.toLocal();
    final locale = _localeFor(languageCode);
    final sameDay =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (sameDay) {
      return _cached('time', locale, () => DateFormat.jm(locale)).format(local);
    }
    if (local.year == now.year) {
      return _cached(
        'day',
        locale,
        () => DateFormat.MMMd(locale).add_jm(),
      ).format(local);
    }
    return _cached(
      'date',
      locale,
      () => DateFormat.yMMMd(locale),
    ).format(local);
  }

  /// `intl` throws for a locale whose date symbols were never loaded (the
  /// Material localizations load them for the app's locales at startup);
  /// fall back rather than crash a list row.
  static String _localeFor(String languageCode) {
    try {
      for (final candidate in [languageCode, _fallbackLanguage]) {
        if (DateFormat.localeExists(candidate)) return candidate;
      }
    } on Object {
      // No date symbols loaded at all (a bare widget test): `intl` still
      // ships `en_US` built in.
    }
    return _fallbackLocale;
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      format(
        time,
        now: DateTime.now(),
        languageCode: context.locale.languageCode,
      ),
      style: AppTextStyles.captionLarge.copyWith(color: AppColors.tertiaryText),
    );
  }
}
