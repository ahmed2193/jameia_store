import 'package:flutter/widgets.dart';

import 'hero_page.dart';

/// Steps of one flow that share their chrome (login → OTP share the brand
/// header): the page only fades in over the one below — nothing slides or
/// zooms — so what both pages paint the same looks still while the rest
/// cross-fades, and a page that stages its own entrance (a sheet rising) is
/// not moved twice.
class HeroCrossFadePage<T> extends HeroPage<T> {
  const HeroCrossFadePage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
  });

  @override
  HeroEnterBuilder get enter =>
      (context, animation, child) =>
          FadeTransition(opacity: animation, child: child);
}
