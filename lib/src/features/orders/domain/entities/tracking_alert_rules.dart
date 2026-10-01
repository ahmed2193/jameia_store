import 'courier_progress.dart';
import 'courier_stage.dart';

/// When the ride's notifications change — often enough to feel live, never
/// a stream of noise:
///
/// * the ride card is posted again for a new stage, a new minute, each
///   [cardStep] more of the ride, or [cardRefresh] after the last post (a
///   rider held up at the same minute): each post pushes back the time the
///   phone takes a forgotten card away, so a live ride never loses it;
/// * a moment sounds only at the stages a waiting customer cares about —
///   the order on its way, the rider almost there, at the door — and only
///   when the stage changes while they follow (not on opening the map).
abstract final class TrackingAlertRules {
  static const double cardStep = 0.05;
  static const Duration cardRefresh = Duration(minutes: 1);

  static bool cardChanged(CourierProgress? shown, CourierProgress now) =>
      shown == null ||
      shown.stage != now.stage ||
      shown.minutesLeft != now.minutesLeft ||
      (now.rideFraction - shown.rideFraction).abs() >= cardStep ||
      now.at.difference(shown.at) >= cardRefresh;

  static bool isMoment(CourierProgress? before, CourierProgress now) =>
      before != null &&
      before.stage != now.stage &&
      switch (now.stage) {
        CourierStage.onTheWay ||
        CourierStage.nearby ||
        CourierStage.arrived => true,
        _ => false,
      };
}
