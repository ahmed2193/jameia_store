import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import 'src/app.dart';
import 'src/config/di/service_locator.dart';
import 'src/core/widgets/image_cache_tuner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await setupServiceLocator(); // core infra + every feature (config/di)

  // Fire-and-forget: tunes the imageCache budget off a /proc/meminfo read; the
  // first frame is fine on Flutter default budget, so keep it off the hot path.
  unawaited(ImageCacheTuner.install());

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      child: const JameiaApp(),
    ),
  );
}
