import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'motion.dart';
import 'shader_asset_image.dart';
import 'shader_reveal_painter.dart';

export 'dissolve_image.dart';

/// **core/motion/shader_transition.dart** — drivers for the GLSL effects ported
/// from Jameia's video-effects SDK (`shaders/*.frag`).
///
/// * [ShaderReveal] — plays a single-image fragment shader (affine settle or
///   focus-in blur) over an asset image, on mount. The richer cousin of a plain
///   fade for hero images / brand art.
/// * [DissolveImage] — cross-fades between two asset images via `dissolve.frag`.
///
/// All driven by an [AnimationController] using [AppMotion] durations and gated
/// by [MotionGuard] (reduced-motion → final frame, no animation). Impeller only;
/// where a shader can't load the widgets fall back to a plain [Image]/cross-fade.
enum ShaderRevealKind { affine, focusBlur }

const _kShaderAsset = <ShaderRevealKind, String>{
  ShaderRevealKind.affine: 'shaders/affine_reveal.frag',
  ShaderRevealKind.focusBlur: 'shaders/blur.frag',
};

class ShaderReveal extends StatefulWidget {
  const ShaderReveal({
    super.key,
    required this.asset,
    this.kind = ShaderRevealKind.affine,
    this.duration,
    this.fit = BoxFit.cover,
  });

  final String asset;
  final ShaderRevealKind kind;
  final Duration? duration;
  final BoxFit fit;

  @override
  State<ShaderReveal> createState() => _ShaderRevealState();
}

class _ShaderRevealState extends State<ShaderReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration ?? AppMotion.slow,
  );
  ui.FragmentShader? _shader;
  ui.Image? _image;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        _kShaderAsset[widget.kind]!,
      );
      final image = await loadShaderAssetImage(widget.asset);
      if (!mounted) return;
      setState(() {
        _shader = program.fragmentShader();
        _image = image;
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
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fallback: shader/image unavailable → plain image (no effect).
    if (_failed || _shader == null || _image == null) {
      return Image.asset(widget.asset, fit: widget.fit);
    }
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          painter: ShaderRevealPainter(
            shader: _shader!,
            image: _image!,
            progress: _c.value,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}
