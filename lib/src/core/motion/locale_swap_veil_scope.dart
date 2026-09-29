import 'package:flutter/widgets.dart';

import 'locale_swap_veil_host.dart';

/// Hands the [LocaleSwapVeilHost] down the tree (read without a dependency:
/// the host never changes for a subtree).
class LocaleSwapVeilScope extends InheritedWidget {
  const LocaleSwapVeilScope({
    super.key,
    required this.host,
    required super.child,
  });

  final LocaleSwapVeilHostState host;

  @override
  bool updateShouldNotify(LocaleSwapVeilScope oldWidget) =>
      host != oldWidget.host;
}
