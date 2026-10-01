import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_svg_glyph.dart';
import '../../../domain/entities/courier_progress.dart';
import '../../cubit/courier_tracking_cubit.dart';
import 'live_map_track_bar.dart';

/// Store → door at a glance, between the map's own two pins: how much of
/// the road the order has come ([LiveMapTrackBar]). Between two close fixes
/// the bar runs on at an even pace over the time between them, in step with
/// the rider gliding on the map; the first fix, or one after a long quiet,
/// eases there instead. Empty until the rider leaves the store with the
/// order.
class LiveMapTrack extends StatefulWidget {
  const LiveMapTrack({super.key});

  @override
  State<LiveMapTrack> createState() => _LiveMapTrackState();
}

class _LiveMapTrackState extends State<LiveMapTrack> {
  static const double _pin = AppSize.s24;

  /// The fix the bar last headed to, and how long it glides there from the
  /// one before (`null`: ease instead).
  CourierProgress? _current;
  Duration? _gap;

  /// Takes [progress] as the new target once it is a new fix (a new
  /// [CourierProgress.at]); a copy of the same fix (the minutes ticking
  /// down) keeps the glide as it is.
  void _follow(CourierProgress? progress) {
    if (progress?.at == _current?.at) return;
    _gap = progress?.glideFrom(_current);
    _current = progress;
  }

  @override
  Widget build(BuildContext context) {
    _follow(
      context.select<CourierTrackingCubit, CourierProgress?>(
        (cubit) => cubit.state.progress,
      ),
    );
    final gap = _gap;
    return ExcludeSemantics(
      child: Row(
        children: [
          const HeroSvgGlyph.art(HeroAssets.mapStorePin, size: _pin),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: RepaintBoundary(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: _current?.deliveryFraction ?? 0),
                duration: MotionGuard.duration(context, gap ?? AppMotion.slow),
                curve: gap == null ? AppMotion.signature : AppMotion.linear,
                builder: (context, value, _) =>
                    LiveMapTrackBar(fraction: value),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          const HeroSvgGlyph.art(HeroAssets.mapHomePin, size: _pin),
        ],
      ),
    );
  }
}
