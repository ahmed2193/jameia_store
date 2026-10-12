// Own isolate (own file): a binding (the test binding) exists before the
// app's ensureInitialized() runs. It must hand back that binding, not
// construct a second one (BindingBase asserts "Binding is already
// initialized").

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/media/hero_widgets_binding.dart';
import 'package:hero_mart/src/core/media/trimming_image_cache.dart';

void main() {
  test('keeps an existing binding instead of constructing a second', () {
    final TestWidgetsFlutterBinding existing =
        TestWidgetsFlutterBinding.ensureInitialized();

    final WidgetsBinding binding = HeroWidgetsBinding.ensureInitialized();

    expect(binding, same(existing));
    expect(binding, isNot(isA<HeroWidgetsBinding>()));
    expect(
      PaintingBinding.instance.imageCache,
      isNot(isA<TrimmingImageCache>()),
    );
    expect(WidgetsBinding.instance, same(existing));
  });
}
