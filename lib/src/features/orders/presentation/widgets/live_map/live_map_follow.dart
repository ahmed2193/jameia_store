import '../../../domain/entities/courier_stage.dart';
import 'live_map_camera.dart';
import 'live_map_camera_action.dart';

/// Who holds the live map's camera, and how it follows the rider.
///
/// * Riding along ([chases]): while the rider is on the road the camera
///   rides with them ([LiveMapChaseCamera]) — unless motion is reduced or
///   the customer asked for the road ahead ([showOverview]).
/// * Framing: otherwise it frames the ride — on a new stage (or a
///   recentre), and within a stage only once the road left has clearly
///   shrunk ([LiveMapCamera.shouldReframe]); the map holds still in
///   between.
/// * A drag hands the camera to the customer ([stop]); the camera button,
///   or reaching the door, gives it back ([resume]).
class LiveMapFollow {
  CourierStage? _aimedStage;

  /// Metres of road the rider had left when the camera last aimed.
  double _aimedLeft = 0;
  bool _following = true;
  bool _overview = false;

  /// Whether the camera follows the rider (not the customer's own view).
  bool get following => _following;

  /// Whether the customer asked for the road ahead, from above.
  bool get overview => _overview;

  /// Whether the camera rides along with the rider at [stage]: following,
  /// the road ahead not asked for, the rider on the road, and [motion]
  /// allowed (a camera that moves every frame is motion).
  bool chases({required CourierStage stage, required bool motion}) =>
      _following && !_overview && motion && stage.riding;

  /// What the camera button offers at [stage] ([motion] allowed or not):
  /// the road ahead while the camera rides along; riding along (or, with
  /// motion reduced, following) again once the customer took the map or
  /// looks at the road ahead; nothing while the camera frames the ride by
  /// itself.
  LiveMapCameraAction? action({
    required CourierStage stage,
    required bool motion,
  }) {
    if (!_following) return LiveMapCameraAction.follow;
    if (chases(stage: stage, motion: motion)) {
      return LiveMapCameraAction.overview;
    }
    if (_overview && motion && stage.riding) return LiveMapCameraAction.follow;
    return null;
  }

  /// Whether the camera frames the ride now, at [stage] with [left] metres
  /// of road to go ([always]: whatever the last aim was); records the aim
  /// when it does. Never before the entrance ([introStarted]: the native
  /// map and the art are both there), so no aim is spent on a map that
  /// cannot move yet — the first fix after the entrance aims at the road
  /// ahead.
  bool shouldAim({
    required CourierStage stage,
    required double left,
    required bool always,
    required bool introStarted,
  }) {
    if (!_following || !introStarted) return false;
    if (!always &&
        _aimedStage == stage &&
        !LiveMapCamera.shouldReframe(aimedLeft: _aimedLeft, left: left)) {
      return false;
    }
    _aimedStage = stage;
    _aimedLeft = left;
    return true;
  }

  /// Whether the camera frames the road again because the room around the
  /// map changed ([paddingChanged]: the panel grew or shrank): the map keeps
  /// its zoom and only shifts its centre, so the road framed for the old
  /// room would slide under the panel. Only while following, after the
  /// entrance.
  bool shouldReaimForPadding({
    required bool paddingChanged,
    required bool introStarted,
  }) => paddingChanged && introStarted && _following;

  /// Forgets the last aim (the camera was moved another way): the next fix
  /// aims again.
  void reset() => _aimedStage = null;

  /// The customer took the camera.
  void stop() => _following = false;

  /// The camera follows the rider again, riding along where it can.
  void resume() {
    _following = true;
    _overview = false;
  }

  /// The camera frames the road ahead from above, and keeps doing so.
  void showOverview() {
    _following = true;
    _overview = true;
  }
}
