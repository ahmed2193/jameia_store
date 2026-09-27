// Renders the APP ICON source art from the SAME cart the splash paints
// (SplashCartPainting), so the icon, the OS splash and the Flutter splash are
// one mark. Run after changing the cart, then regenerate the platform icons:
//
//   flutter test tool/splash/render_app_icons_test.dart
//   dart run flutter_launcher_icons
//
// Outputs (assets/app_icon/, 1024² each — generator inputs, not bundled):
//   icon_ios.png         opaque — brand green, a soft glow, the white cart
//                        (iOS app icon + legacy Android icon)
//   icon_foreground.png  transparent — the cart inside Android's adaptive-icon
//                        safe zone (background = the brand green colour)
//   icon_monochrome.png  transparent — the cart as one silhouette with the
//                        slats cut out (Android 13+ themed icons)
//   icon_ios_dark.png    transparent — the cart for iOS 18 dark icons (the
//                        tinted icon is its grayscale)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/config/theme/app_colors.dart';
import 'package:jameia_mart/src/core/design/jameia_cart_mark.dart';
import 'package:jameia_mart/src/core/widgets/jameia_mark_icon_painter.dart';
import 'package:jameia_mart/src/features/splash/presentation/widgets/splash_cart_painting.dart';
import 'package:jameia_mart/src/features/splash/presentation/widgets/splash_palette.dart';

const int _size = 1024;
const Offset _center = Offset(_size / 2, _size / 2);
const String _dir = 'assets/app_icon';

/// Cart width as a share of the square (iOS / legacy) icon: the same tile
/// the Home tab lights up as.
const double _squareCartWidth = JameiaMarkIconPainter.tileCartWidth;

/// Android keeps a circle of 66 dp out of the 108 dp adaptive canvas; the
/// cart's farthest point stays at this share of the canvas from the centre.
const double _adaptiveSafeRadius = 66 / 108 / 2;
const double _adaptiveReach = 0.27;

/// Soft light behind the cart on the square icon (like the splash glow).
const double _glowRadius = JameiaMarkIconPainter.glowRadius;
const double _glowOpacity = JameiaMarkIconPainter.glowOpacity;
const Offset _glowLift = Offset(0, -_size * JameiaMarkIconPainter.glowLift);

/// dp-per-unit that makes the cart [width] of the canvas wide.
double _unitForWidth(double width) =>
    _size * width / JameiaCartMark.bounds.width;

/// dp-per-unit that puts the cart's farthest point at [reach] of the canvas.
double _unitForReach(double reach) => _size * reach / JameiaCartMark.reach;

Future<void> _save(String name, void Function(Canvas canvas) paint) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  final image = await recorder.endRecording().toImage(_size, _size);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File('$_dir/$name')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

void _cart(Canvas canvas, double unit) => SplashCartPainting.paint(
  canvas,
  center: _center,
  unit: unit,
  palette: SplashPalette.onBrand,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the adaptive cart stays inside the Android safe zone', () {
    expect(_adaptiveReach, lessThan(_adaptiveSafeRadius));
  });

  test('renders the app icon art', () async {
    await _save('icon_ios.png', (canvas) {
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
      _cart(canvas, _unitForWidth(_squareCartWidth));
    });

    await _save(
      'icon_foreground.png',
      (canvas) => _cart(canvas, _unitForReach(_adaptiveReach)),
    );

    await _save('icon_monochrome.png', (canvas) {
      final unit = _unitForReach(_adaptiveReach);
      final bounds = JameiaCartMark.bounds;
      canvas.saveLayer(null, Paint());
      _cart(canvas, unit);
      // Punch the slats out so the themed icon keeps the basket's detail.
      canvas
        ..translate(_center.dx, _center.dy)
        ..scale(unit)
        ..translate(-bounds.center.dx, -bounds.center.dy)
        ..clipPath(JameiaCartMark.bowl);
      final clear = Paint()..blendMode = BlendMode.clear;
      const half = JameiaCartMark.slatWidth / 2;
      for (final x in JameiaCartMark.slatCenters) {
        canvas.drawRRect(
          RRect.fromLTRBR(
            x - half,
            JameiaCartMark.slatTop,
            x + half,
            JameiaCartMark.slatBottom,
            const Radius.circular(half),
          ),
          clear,
        );
      }
      canvas.restore();
    });

    await _save(
      'icon_ios_dark.png',
      (canvas) => _cart(canvas, _unitForWidth(_squareCartWidth)),
    );

    for (final name in [
      'icon_ios.png',
      'icon_foreground.png',
      'icon_monochrome.png',
      'icon_ios_dark.png',
    ]) {
      expect(File('$_dir/$name').existsSync(), isTrue);
    }
  });
}
