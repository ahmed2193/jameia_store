import '../../../domain/entities/courier_stage.dart';
import 'live_map_camera.dart';

/// Whether the live map's camera follows the rider, and when it re-aims:
/// on a new stage (or a recentre); within a stage only once the road left
/// has clearly shrunk ([LiveMapCamera.shouldReframe]) — the map holds still
/// in between. A drag hands the camera to the customer ([stop]); the
/// recenter button, or reaching the door, gives it back ([resume]).
class LiveMapFollow {
  CourierStage? _aimedStage;

  /// Metres of road the rider had left when the camera last aimed.
  double _aimedLeft = 0;
  bool _following = true;

  /// Whether the camera follows the rider (not the customer's own view).
  bool get following => _following;

  /// Whether the camera aims now, at [stage] with [left] metres of road to
  /// go ([always]: whatever the last aim was); records the aim when it
  /// does. Never before the entrance ([introStarted]: the native map and
  /// the art are both there), so no aim is spent on a map that cannot move
  /// yet — the first fix after the entrance aims at the road ahead.
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

  /// The camera follows the rider again.
  void resume() => _following = true;
}
