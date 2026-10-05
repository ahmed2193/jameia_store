import 'package:flutter/rendering.dart';

import '../../../../../config/theme/app_colors.dart';

/// The ground of the map card before the map is pictured: a quiet street
/// plan in the picker map's palette (land, a park, the sea's edge, white
/// roads) — clearly a drawing, under the pin and "Adjust pin".
class PinPreviewGroundPainter extends CustomPainter {
  const PinPreviewGroundPainter();

  static const double _roadEdge = 11;
  static const double _road = 8;
  static const double _streetEdge = 7;
  static const double _street = 5;
  static const Radius _parkCorner = Radius.circular(10);

  // Where things sit, as shares of the card.
  static const Rect _park = Rect.fromLTWH(0.06, 0.12, 0.22, 0.42);
  static const double _mainRoadY = 0.66;
  static const double _sideRoadX = 0.36;
  static const double _shoreTop = 0.86;
  static const double _shoreBottom = 0.78;
  static const double _shoreBend = 0.9;
  static const Offset _avenueFrom = Offset(0.52, 0);
  static const Offset _avenueTo = Offset(0.74, 1);
  static const double _streetY = 0.28;
  static const double _streetEnd = 0.8;

  @override
  void paint(Canvas canvas, Size size) {
    Offset at(double x, double y) => Offset(size.width * x, size.height * y);

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.mediumBackground,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          at(_park.left, _park.top),
          at(_park.right, _park.bottom),
        ),
        _parkCorner,
      ),
      Paint()..color = AppColors.brandLightBg,
    );

    final sea = Path()
      ..moveTo(size.width * _shoreTop, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * _shoreBottom, size.height)
      ..quadraticBezierTo(
        size.width * _shoreBend,
        size.height / 2,
        size.width * _shoreTop,
        0,
      );
    canvas.drawPath(sea, Paint()..color = AppColors.accentSkyLight);

    void road(Offset from, Offset to, {required bool main}) {
      final edge = Paint()
        ..color = AppColors.divider
        ..strokeWidth = main ? _roadEdge : _streetEdge
        ..strokeCap = StrokeCap.round;
      final top = Paint()
        ..color = AppColors.white
        ..strokeWidth = main ? _road : _street
        ..strokeCap = StrokeCap.round;
      canvas
        ..drawLine(from, to, edge)
        ..drawLine(from, to, top);
    }

    road(at(0, _mainRoadY), at(_shoreBottom, _mainRoadY), main: true);
    road(at(_sideRoadX, 0), at(_sideRoadX, 1), main: true);
    road(
      at(_avenueFrom.dx, _avenueFrom.dy),
      at(_avenueTo.dx, _avenueTo.dy),
      main: true,
    );
    road(at(_sideRoadX, _streetY), at(_streetEnd, _streetY), main: false);
  }

  @override
  bool shouldRepaint(PinPreviewGroundPainter oldDelegate) => false;
}
