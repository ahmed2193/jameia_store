import 'package:flutter/material.dart';

/// A small outlined bin whose lid swings open on its end hinge — the bin
/// the cancelled mic drops into.
class AssistantVoiceBinPainter extends CustomPainter {
  const AssistantVoiceBinPainter({required this.lidAngle, required this.color});

  /// 0 closed; negative swings the lid open.
  final double lidAngle;
  final Color color;

  // Proportions of the box.
  static const double _stroke = 0.1;
  static const double _lidLine = 0.24;
  static const double _topInset = 0.14;
  static const double _bottomInset = 0.22;
  static const double _ribNear = 0.42;
  static const double _ribFar = 0.58;
  static const double _ribSlant = 0.02;
  static const double _hinge = 0.92;
  static const double _lidLength = 0.84;
  static const double _handleFrom = 0.56;
  static const double _handleTo = 0.3;
  static const double _handleLift = 1.6;
  static const double _ribGap = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = w * _stroke;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final lidY = h * _lidLine;
    final bottom = h - stroke / 2;
    canvas.drawPath(
      Path()
        ..moveTo(w * _topInset, lidY + stroke)
        ..lineTo(w * _bottomInset, bottom)
        ..lineTo(w * (1 - _bottomInset), bottom)
        ..lineTo(w * (1 - _topInset), lidY + stroke),
      paint,
    );
    final ribTop = lidY + stroke * _ribGap;
    final ribBottom = bottom - stroke * _ribGap;
    canvas
      ..drawLine(
        Offset(w * _ribNear, ribTop),
        Offset(w * (_ribNear + _ribSlant), ribBottom),
        paint,
      )
      ..drawLine(
        Offset(w * _ribFar, ribTop),
        Offset(w * (_ribFar - _ribSlant), ribBottom),
        paint,
      )
      ..save()
      ..translate(w * _hinge, lidY)
      ..rotate(lidAngle)
      ..drawLine(Offset(-w * _lidLength, 0), Offset.zero, paint)
      ..drawLine(
        Offset(-w * _handleFrom, -stroke * _handleLift),
        Offset(-w * _handleTo, -stroke * _handleLift),
        paint,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(AssistantVoiceBinPainter oldDelegate) =>
      lidAngle != oldDelegate.lidAngle || color != oldDelegate.color;

  /// Pure drawing, no meaning: nothing for a screen reader on each frame.
  @override
  bool shouldRebuildSemantics(AssistantVoiceBinPainter oldDelegate) => false;
}
