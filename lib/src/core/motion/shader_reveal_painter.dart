import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Paints a single-image fragment shader for [ShaderReveal] at [progress].
class ShaderRevealPainter extends CustomPainter {
  ShaderRevealPainter({
    required this.shader,
    required this.image,
    required this.progress,
  });

  final ui.FragmentShader shader;
  final ui.Image image;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, progress)
      ..setImageSampler(0, image);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant ShaderRevealPainter old) =>
      old.progress != progress || old.image != image;
}
