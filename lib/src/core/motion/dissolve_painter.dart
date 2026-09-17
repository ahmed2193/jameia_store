import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Paints `dissolve.frag` between [from] and [to] for [DissolveImage].
class DissolvePainter extends CustomPainter {
  DissolvePainter({
    required this.shader,
    required this.from,
    required this.to,
    required this.progress,
  });

  final ui.FragmentShader shader;
  final ui.Image from;
  final ui.Image to;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, progress)
      ..setImageSampler(0, from)
      ..setImageSampler(1, to);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant DissolvePainter old) => old.progress != progress;
}
