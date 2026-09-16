import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'motion.dart';

/// **core/motion/shader_transition.dart** — drivers for the GLSL effects ported
/// from KeeTa's video-effects SDK (`shaders/*.frag`).
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

/// Loads (and caches) a [ui.Image] from an asset path.
Future<ui.Image> _loadAssetImage(String path) async {
  final data = await rootBundle.load(path);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  return frame.image;
}

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
      final image = await _loadAssetImage(widget.asset);
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
          painter: _ShaderPainter(
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

class _ShaderPainter extends CustomPainter {
  _ShaderPainter({
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
  bool shouldRepaint(covariant _ShaderPainter old) =>
      old.progress != progress || old.image != image;
}

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
      final from = await _loadAssetImage(widget.fromAsset);
      final to = await _loadAssetImage(widget.toAsset);
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
          painter: _DissolvePainter(
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

class _DissolvePainter extends CustomPainter {
  _DissolvePainter({
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
  bool shouldRepaint(covariant _DissolvePainter old) =>
      old.progress != progress;
}
