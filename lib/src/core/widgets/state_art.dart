import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../motion/motion.dart';
import '../responsive/app_size.dart';

/// The illustration a whole-screen state leads with (empty, error, offline,
/// signed-out, not found …): one of the 160 × 120 `HeroAssets.state*` /
/// `empty*` plates — an 88 dp disc centred at (80, 58) over a soft floor
/// shadow. Decorative: screen readers hear the state's words, not the art.
///
/// [entrance]: fades in while it scales from 0.9 to full size once, on
/// mount (docs/motion §9.4 #17: [AppMotion.medium], `signature`); a state
/// that is already there when its screen opens passes `false`. Static under
/// reduced motion.
///
/// [compact]: the 120 × 90 size of the same plate, for a card or a sheet
/// (docs/motion/asset_manifest.md §1.1).
class StateArt extends StatefulWidget {
  const StateArt({
    super.key,
    required this.asset,
    this.entrance = true,
    this.compact = false,
  });

  /// A `HeroAssets` path.
  final String asset;
  final bool entrance;
  final bool compact;

  static const double width = AppSize.s160;
  static const double height = AppSize.s120;
  static const double compactWidth = AppSize.s120;
  static const double compactHeight = AppSize.s90;

  /// Where the disc sits in the frame: its top-left corner is 14 dp down
  /// (58 − 44) of the 32 dp spare height, centred across.
  static const Alignment discAlignment = FractionalOffset(0.5, 14 / 32);

  @override
  State<StateArt> createState() => _StateArtState();
}

class _StateArtState extends State<StateArt>
    with SingleTickerProviderStateMixin {
  static const double _scaleFrom = 0.9;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
    value: 1,
  );
  late final CurvedAnimation _progress = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.signature,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: _scaleFrom,
    end: 1,
  ).animate(_progress);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.entrance && !MotionGuard.reduced(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: _progress,
        child: ScaleTransition(
          scale: _scale,
          child: SvgPicture.asset(
            widget.asset,
            width: widget.compact ? StateArt.compactWidth : StateArt.width,
            height: widget.compact ? StateArt.compactHeight : StateArt.height,
          ),
        ),
      ),
    );
  }
}
