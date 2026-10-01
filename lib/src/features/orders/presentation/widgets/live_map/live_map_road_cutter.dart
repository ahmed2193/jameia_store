import '../../../domain/entities/courier_stage.dart';

/// When the live map's road is worth recutting — each cut sends every point
/// of the road left to the native map, so it is cut only when something
/// that shows changed: the stage, the draw-in of the planned road (the
/// entrance), or the rider moved far enough on screen since the last cut.
class LiveMapRoadCutter {
  /// The draw-in once the road no longer draws in: from the stage the
  /// order is on its way, the road ahead is drawn whole.
  static const double fullyDrawn = 1;

  CourierStage? _stage;
  double? _drawn;
  double _meters = 0;

  /// The draw-in the road is cut at: [entrance] (0 → 1) while the road is
  /// only planned, [fullyDrawn] once the order is on its way — so the
  /// entrance never recuts a road it does not draw in.
  static double drawnAt({
    required CourierStage stage,
    required double entrance,
  }) => stage.delivering ? fullyDrawn : entrance;

  /// Whether the road cut last differs from the one for [stage], [drawn]
  /// and a rider [meters] down the road, [stepMeters] being how far the
  /// rider moves between two cuts (`LiveMapFrameGate.lineStepMeters`).
  bool needsRecut({
    required CourierStage stage,
    required double drawn,
    required double meters,
    required double stepMeters,
  }) =>
      _stage != stage ||
      _drawn != drawn ||
      (meters - _meters).abs() >= stepMeters;

  /// The road was just cut for [stage], [drawn] and [meters].
  void mark({
    required CourierStage stage,
    required double drawn,
    required double meters,
  }) {
    _stage = stage;
    _drawn = drawn;
    _meters = meters;
  }

  /// Forgets the last cut (a new ride or new art): the next one recuts.
  void reset() => _stage = null;
}
