import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'dissolve_painter.dart';
import 'motion.dart';
import 'shader_asset_image.dart';

/// Cross-fades between two asset images with `dissolve.frag`. Plays on mount, or
/// re-plays when [toAsset] changes.
class DissolveImage extends StatefulWidget {
  const DissolveImage({
    super.key,
    required this.fromAsset,
    required this.toAsset,
    this.duration,
    this.fit = BoxFit.cover,
  });

  final String fromAsset;
  final String toAsset;
  final Duration? duration;
  final BoxFit fit;

  @override
  State<DissolveImage> createState() => _DissolveImageState();
}

class _DissolveImageState extends State<DissolveImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration ?? AppMotion.medium,
  );
  ui.FragmentShader? _shader;
  ui.Image? _from;
  ui.Image? _to;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/dissolve.frag',
      );
      final from = await loadShaderAssetImage(widget.fromAsset);
      final to = await loadShaderAssetImage(widget.toAsset);
      if (!mounted) return;
      setState(() {
        _shader = program.fragmentShader();
        _from = from;
        _to = to;
      });
      if (WidgetsBinding.instance.disableAnimations) {
        _c.value = 1;
      } else {
        _c.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _shader?.dispose();
    _from?.dispose();
    _to?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed || _shader == null || _from == null || _to == null) {
      return Image.asset(widget.toAsset, fit: widget.fit);
    }
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          painter: DissolvePainter(
            shader: _shader!,
            from: _from!,
            to: _to!,
            progress: _c.value,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}
