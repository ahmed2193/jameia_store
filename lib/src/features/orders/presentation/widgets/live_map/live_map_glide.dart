import '../../../../../core/motion/motion.dart';
import '../../../domain/entities/courier_progress.dart';

/// How the rider on the live map moves to a new fix: at the feed's own
/// pace between two close fixes ([CourierProgress.glideFrom]); briskly
/// ([AppMotion.slow]) after a longer gap (the map was hidden, the feed
/// stalled); the first fix, or one not after the last, is stepped to
/// (`null`).
abstract final class LiveMapGlide {
  static Duration? between(CourierProgress now, CourierProgress? previous) =>
      now.glideFrom(previous) ??
      (previous != null && now.at.isAfter(previous.at) ? AppMotion.slow : null);
}
