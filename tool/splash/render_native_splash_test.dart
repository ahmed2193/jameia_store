// Renders the native launch image from the SAME shapes the Flutter splash
// paints (HeroMarkPainting), so the OS splash and the first Flutter frame
// are pixel-identical. Run after changing the mark, then regenerate the
// Android / iOS launch screens:
//
//   flutter test tool/splash/render_native_splash_test.dart
//   dart run flutter_native_splash:create
//
// Output: assets/splash/splash_mark.png — 1152×1152, transparent, the white
// bag in its yellow cape centred. flutter_native_splash reads it as 4× (a
// 288 dp / pt box) for Android 12+ (windowSplashScreenAnimatedIcon), Android
// ≤11 (centred bitmap) and iOS (LaunchImage, content mode "center").
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/design/hero_mark_painting.dart';
import 'package:hero_mart/src/features/splash/presentation/widgets/splash_layout.dart';

const int _size = 1152;
const String _out = 'assets/splash/splash_mark.png';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the mark fits the circle Android 12+ keeps of the icon', () {
    expect(SplashLayout.nativeReach, lessThan(SplashLayout.nativeSafeRadius));
  });

  test('renders $_out', () async {
    const pxPerDp = _size / SplashLayout.nativeBox;
    final recorder = ui.PictureRecorder();
    HeroMarkPainting.paint(
      Canvas(recorder),
      center: const Offset(_size / 2, _size / 2),
      unit: SplashLayout.nativeUnit * pxPerDp,
      colors: HeroMarkColors.onBrand,
    );
    final image = await recorder.endRecording().toImage(_size, _size);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    File(_out)
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
    expect(File(_out).existsSync(), isTrue);
  });
}
