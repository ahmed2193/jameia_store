// Renders the APP ICON source art, and the in-app logo, from the SAME mark
// the splash paints (HeroMarkPainting), so the icon, the OS splash, the
// Flutter splash and the Home tab are one mark. Run after changing the mark,
// then regenerate the platform icons:
//
//   flutter test tool/splash/render_app_icons_test.dart
//   dart run flutter_launcher_icons
//
// Outputs (1024² each):
//   assets/app_icon/icon_ios.png         opaque — Hero green, a soft glow, the
//                                        white bag in its yellow cape (iOS app
//                                        icon + legacy Android icon)
//   assets/app_icon/icon_foreground.png  transparent — the mark inside
//                                        Android's adaptive-icon safe zone
//                                        (background = the brand green colour)
//   assets/app_icon/icon_monochrome.png  transparent — the mark as one white
//                                        silhouette, "h" and cape gap cut out
//                                        (Android 13+ themed icons)
//   assets/app_icon/icon_ios_dark.png    transparent — the mark for iOS 18
//                                        dark icons (the tinted icon is its
//                                        grayscale)
//   assets/launcher/app_icon_square.png  the in-app logo (HeroAssets.appLogo:
//                                        home, login, about) = icon_ios.png at
//                                        512² (never shown above 96 dp)
// The assets/app_icon files are generator inputs, not bundled.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/config/theme/app_colors.dart';
import 'package:hero_mart/src/core/design/hero_mark.dart';
import 'package:hero_mart/src/core/design/hero_mark_painting.dart';
import 'package:hero_mart/src/core/widgets/hero_mark_icon_painter.dart';

const int _size = 1024;
const Offset _center = Offset(_size / 2, _size / 2);
const String _dir = 'assets/app_icon';
const String _inAppLogo = 'assets/launcher/app_icon_square.png';
const int _inAppLogoSize = 512;

/// Mark width as a share of the square (iOS / legacy) icon: the same tile
/// the Home tab lights up as.
const double _squareMarkWidth = HeroMarkIconPainter.tileMarkWidth;

/// Android keeps a circle of 66 dp out of the 108 dp adaptive canvas; the
/// mark's farthest point stays at this share of the canvas from the centre.
const double _adaptiveSafeRadius = 66 / 108 / 2;
const double _adaptiveReach = 0.28;

/// Soft light behind the mark on the square icon (like the splash glow).
const double _glowRadius = HeroMarkIconPainter.glowRadius;
const double _glowOpacity = HeroMarkIconPainter.glowOpacity;
const Offset _glowLift = Offset(0, -_size * HeroMarkIconPainter.glowLift);

/// px per design unit that makes the mark [width] of the canvas wide.
double _unitForWidth(double width) => _size * width / HeroMark.bounds.width;

/// px per design unit that puts the mark's farthest point at [reach] of the
/// canvas.
double _unitForReach(double reach) => _size * reach / HeroMark.reach;

/// Paints [paint] (drawn for a [_size] canvas) into a [size]² PNG at [path].
Future<void> _save(
  String path,
  void Function(Canvas canvas) paint, {
  int size = _size,
}) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder)..scale(size / _size));
  final image = await recorder.endRecording().toImage(size, size);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

void _mark(Canvas canvas, double unit, HeroMarkColors colors) =>
    HeroMarkPainting.paint(canvas, center: _center, unit: unit, colors: colors);

/// The square icon: brand green, the glow, the mark.
void _squareIcon(Canvas canvas) {
  const bounds = Rect.fromLTWH(0, 0, _size * 1.0, _size * 1.0);
  canvas.drawRect(bounds, Paint()..color = AppColors.primary);
  const glow = AppColors.brandDarkBg;
  final center = _center + _glowLift;
  canvas.drawCircle(
    center,
    _size * _glowRadius,
    Paint()
      ..shader = ui.Gradient.radial(center, _size * _glowRadius, [
        glow.withValues(alpha: _glowOpacity),
        glow.withValues(alpha: 0),
      ]),
  );
  _mark(canvas, _unitForWidth(_squareMarkWidth), HeroMarkColors.onBrand);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the adaptive mark stays inside the Android safe zone', () {
    expect(_adaptiveReach, lessThan(_adaptiveSafeRadius));
  });

  test('renders the app icon art and the in-app logo', () async {
    await _save('$_dir/icon_ios.png', _squareIcon);
    await _save(_inAppLogo, _squareIcon, size: _inAppLogoSize);
    await _save(
      '$_dir/icon_foreground.png',
      (canvas) =>
          _mark(canvas, _unitForReach(_adaptiveReach), HeroMarkColors.onBrand),
    );
    await _save(
      '$_dir/icon_monochrome.png',
      (canvas) => _mark(
        canvas,
        _unitForReach(_adaptiveReach),
        HeroMarkColors.mono(AppColors.white),
      ),
    );
    await _save(
      '$_dir/icon_ios_dark.png',
      (canvas) => _mark(
        canvas,
        _unitForWidth(_squareMarkWidth),
        HeroMarkColors.onBrand,
      ),
    );

    for (final path in [
      '$_dir/icon_ios.png',
      '$_dir/icon_foreground.png',
      '$_dir/icon_monochrome.png',
      '$_dir/icon_ios_dark.png',
      _inAppLogo,
    ]) {
      expect(File(path).existsSync(), isTrue);
    }
  });
}
