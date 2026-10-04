import 'dart:async';
import 'dart:developer';
import 'dart:ui' show lerpDouble;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/geo_point_entity.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/widgets/hero_map.dart';
import '../../../../../core/widgets/hero_map_style.dart';
import '../../../domain/entities/courier_progress.dart';
import '../../../domain/entities/courier_stage.dart';
import '../../../domain/entities/courier_trip.dart';
import '../../cubit/courier_tracking_cubit.dart';
import '../../cubit/courier_tracking_state.dart';
import 'live_map_camera.dart';
import 'live_map_camera_action.dart';
import 'live_map_camera_button.dart';
import 'live_map_chase.dart';
import 'live_map_chase_camera.dart';
import 'live_map_follow.dart';
import 'live_map_frame_gate.dart';
import 'live_map_glide.dart';
import 'live_map_marker_icons.dart';
import 'live_map_overlays.dart';
import 'live_map_pan_watch.dart';
import 'live_map_road_cutter.dart';

/// The live map: the Hero-styled map with the ride drawn on it, moving.
///
/// * Entrance: the planned road draws itself from the store to the door,
///   the rider fades in once one is found.
/// * Between two fixes the rider GLIDES along the road over the time the
///   fixes are apart — always moving, never jumping — turned with the road
///   (through a corner, not at it); the road behind them is eaten.
/// * While the rider is on the road the camera rides along with them, the
///   way Google Maps follows a car ([LiveMapChaseCamera]): it glides in from
///   the whole ride, then keeps to the rider frame by frame — close in,
///   tilted, turned with the road — closing in near the goal. The camera
///   button swaps that for the road ahead from above, and back.
/// * Otherwise (being found, at the store, at the door, motion reduced, the
///   road ahead asked for) it frames the ride, re-aiming only by clear steps
///   ([LiveMapFollow]). A drag hands the camera to the customer (the camera
///   button gives it back); reaching the door takes it back. A panel that
///   grows or shrinks under the map has the camera aim again for the part
///   left in view.
/// * The rider fades to half strength while the feed is quiet, and back.
/// * Moments ring: rings spread from the store while a rider is found, and
///   from the door when the rider is almost there and there — a few laps,
///   within the ambient budget.
///
/// Performance — every map update is a round of platform messages carrying
/// the rider's bitmap, so the map is only told what can be SEEN
/// ([LiveMapFrameGate]): a glide frame once the rider visibly moved or
/// turned, the road recut once the cut would show ([LiveMapRoadCutter]),
/// never two frames closer than a few vsyncs; only the map rebuilds for it
/// (a [ValueNotifier], not `setState`); the pins and, once the order is on
/// its way, the road driven are built once; a framing camera re-aims only
/// by clear steps ([LiveMapCamera.shouldReframe]), a riding one moves with
/// the map updates the rider's glide already makes. Reduced motion: no
/// entrance, no glide (the rider steps fix to fix), no rings, no riding
/// along, camera jumps.
class LiveMapLayer extends StatefulWidget {
  const LiveMapLayer({super.key, required this.trip, required this.padding});

  final CourierTrip trip;

  /// Room the top bar and the bottom panel take over the map.
  final EdgeInsets padding;

  @override
  State<LiveMapLayer> createState() => _LiveMapLayerState();
}

class _LiveMapLayerState extends State<LiveMapLayer>
    with TickerProviderStateMixin {
  /// How faint the rider shows while the feed is quiet.
  static const double _staleAlpha = 0.5;

  static const Interval _roadIn = Interval(
    0,
    1,
    curve: AppMotion.emphasizedDecelerate,
  );

  /// Ring laps per moment: as many of the brand dots' orbit as fit the
  /// ambient budget.
  static final int _ringLaps =
      AppMotion.ambientBudget.inMilliseconds ~/
      AppMotion.loaderOrbit.inMilliseconds;

  static const String _logName = 'live_map';

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: AppMotion.drawOn,
  );
  late final AnimationController _riderIn = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
  );
  late final AnimationController _glide = AnimationController(vsync: this);

  /// A moment's rings: all [_ringLaps] laps in one run, so every ring is
  /// born and fades out whole, and the run ends with the last ring
  /// ([LiveMapOverlays.ringRunLaps]): no map updates for nothing after it.
  late final AnimationController _rings = AnimationController(
    vsync: this,
    duration: AppMotion.loaderOrbit * LiveMapOverlays.ringRunLaps(_ringLaps),
  );

  /// The rider fading to [_staleAlpha] while the feed is quiet (1), and
  /// back (0).
  late final AnimationController _quiet = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
  );

  /// Ticks once per map update: only the map listens.
  final ValueNotifier<int> _mapFrame = ValueNotifier<int>(0);

  final LiveMapFollow _followState = LiveMapFollow();
  final LiveMapChase _chase = LiveMapChase();
  final LiveMapRoadCutter _cutter = LiveMapRoadCutter();

  GoogleMapController? _map;
  LiveMapOverlays? _overlays;
  double _iconsRatio = 0;
  String? _iconsLabel;
  bool _introStarted = false;
  Duration _lastFrame = Duration.zero;
  double _zoom = LiveMapCamera.openingZoom;

  /// Room the camera keeps around what it frames: enough for the store's
  /// named pin ([LiveMapCamera.framePaddingFor]), once its art is known.
  double _frameEdge = LiveMapCamera.framePadding;

  CourierProgress? _progress;
  CourierStage _stage = CourierStage.assigning;
  double _from = 0;
  double _to = 0;

  /// Where the map last showed the rider, and which way.
  double _shownMeters = 0;
  double _shownHeading = 0;

  Set<Polyline> _road = const <Polyline>{};

  GeoPointEntity? _ringsAt;
  Color _ringsColor = AppColors.primary;

  double get _riderMeters => _from + (_to - _from) * _glide.value;

  @override
  void initState() {
    super.initState();
    final state = context.read<CourierTrackingCubit>().state;
    if (state.stale) _quiet.value = 1;
    _glide.addListener(_onGlideFrame);
    for (final controller in [_intro, _riderIn, _rings, _quiet]) {
      controller.addListener(_onFrame);
    }
    for (final controller in [_intro, _riderIn, _glide, _rings, _quiet]) {
      controller.addStatusListener(_onSettled);
    }
    final progress = state.progress;
    if (progress != null) {
      _progress = progress;
      _stage = progress.stage;
      _from = _to = _shownMeters = progress.pathMeters;
      _glide.value = 1;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final label = _storeLabel;
    if (ratio == _iconsRatio && label == _iconsLabel) return;
    _iconsRatio = ratio;
    _iconsLabel = label;
    unawaited(_loadIcons(ratio, label));
  }

  /// The store pin's name: the branch's, or Hero's store.
  String get _storeLabel {
    final name = widget.trip.storeName;
    return name.isEmpty
        ? 'orders.live_store_default'.tr()
        : 'orders.live_store_named'.tr(namedArgs: {'name': name});
  }

  @override
  void didUpdateWidget(LiveMapLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The panel grew or shrank (a rider found, the prompt dismissed): the
    // map keeps its zoom and only shifts its centre, so the road framed for
    // the old padding would slide under the panel — frame it again once
    // the new padding has reached the map: the map sends it from this
    // frame's microtasks, so the aim waits one event more.
    if (_followState.shouldReaimForPadding(
      paddingChanged: oldWidget.padding != widget.padding,
      introStarted: _introStarted,
    )) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        unawaited(
          Future<void>(() {
            if (mounted) _follow(always: true);
          }),
        );
      });
    }
    final icons = _overlays?.icons;
    if (oldWidget.trip == widget.trip || icons == null) return;
    _overlays = LiveMapOverlays(trip: widget.trip, icons: icons);
    _cutter.reset();
    _repaint();
  }

  @override
  void dispose() {
    _map = null;
    _chase.end();
    for (final controller in [_intro, _riderIn, _glide, _rings, _quiet]) {
      controller.dispose();
    }
    _mapFrame.dispose();
    super.dispose();
  }

  Future<void> _loadIcons(double ratio, String storeLabel) async {
    LiveMapMarkerIcons icons;
    try {
      icons = await LiveMapMarkerIcons.load(
        ratio,
        storeLabel: storeLabel,
        labelStyle: AppTextStyles.subheadingSmall.copyWith(
          color: AppColors.primaryText,
        ),
        textDirection: Directionality.of(context),
      );
    } catch (error) {
      log('marker art failed: $error', name: _logName);
      icons = LiveMapMarkerIcons.fallback;
    }
    if (!mounted || ratio != _iconsRatio || storeLabel != _iconsLabel) return;
    _overlays = LiveMapOverlays(trip: widget.trip, icons: icons);
    _frameEdge = LiveMapCamera.framePaddingFor(
      icons.storeSize,
      icons.storeAnchor,
    );
    _cutter.reset();
    _repaint();
    _startIntro();
  }

  void _onMapCreated(GoogleMapController map) {
    _map = map;
    _startIntro();
  }

  /// Once the map and the art are both there: frame the ride, play the
  /// entrance.
  void _startIntro() {
    if (_introStarted || _map == null || _overlays == null) return;
    _introStarted = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        _aim(LiveMapCamera.overview(widget.trip, padding: _edge), jump: true),
      );
      // A follow aimed in this same frame was overwritten by the jump: the
      // next fix aims again (a camera riding along glides in from here).
      _followState.reset();
      _chase.end();
    });
    // The entrance only draws in the planned road: once the rider has the
    // order the road is whole from the start, and 700 ms of map updates
    // would change nothing.
    final whole =
        LiveMapRoadCutter.drawnAt(stage: _stage, entrance: 0) ==
        LiveMapRoadCutter.fullyDrawn;
    if (whole || MotionGuard.reduced(context)) {
      _intro.value = 1;
    } else {
      unawaited(_intro.forward());
    }
    if (_stage.hasRider) _showRider();
    _ringStage(null);
  }

  void _onProgress(CourierProgress progress) {
    final previous = _progress;
    final before = _stage;
    _progress = progress;
    _stage = progress.stage;
    _from = _riderMeters;
    _to = progress.pathMeters;
    final glide = LiveMapGlide.between(progress, previous);
    if (glide == null || _to <= _from || MotionGuard.reduced(context)) {
      _from = _to;
      _glide.value = 1;
    } else {
      _glide.duration = glide;
      unawaited(_glide.forward(from: 0));
    }
    if (_stage != before) {
      if (!before.hasRider && _stage.hasRider) _showRider();
      // The store reached (or passed): the camera riding along glides in
      // again for the road to the door.
      if (before == CourierStage.toStore) _chase.end();
      // The door reached: the map lands on it, whatever the customer did.
      // A new stage may also change what the camera button offers.
      setState(() {
        if (_stage == CourierStage.arrived) _followState.resume();
      });
      _ringStage(before);
    }
    _follow();
    _repaint();
  }

  void _showRider() {
    if (!_introStarted) return;
    if (MotionGuard.reduced(context)) {
      _riderIn.value = 1;
    } else {
      unawaited(_riderIn.forward());
    }
  }

  /// The feed went quiet ([stale]) or spoke again: the rider fades to
  /// [_staleAlpha], or back to full.
  void _onStale(bool stale) {
    if (MotionGuard.reduced(context)) {
      _quiet.value = stale ? 1 : 0;
    } else if (stale) {
      unawaited(_quiet.forward());
    } else {
      unawaited(_quiet.reverse());
    }
  }

  /// Rings for the moment the ride entered (from [before]).
  void _ringStage(CourierStage? before) {
    final trip = widget.trip;
    switch (_stage) {
      case CourierStage.assigning when before == null:
        _ring(trip.store, AppColors.primary);
      case CourierStage.nearby || CourierStage.arrived:
        _ring(trip.home, AppColors.proAmber);
      case _:
        return;
    }
  }

  void _ring(GeoPointEntity at, Color color) {
    if (!_introStarted || !MotionGuard.ambientAllowed(context)) return;
    _ringsAt = at;
    _ringsColor = color;
    unawaited(_rings.forward(from: 0));
  }

  /// Aims the camera as [LiveMapFollow] says ([always]: whatever it did
  /// last — a recentre, a new room around the map).
  ///
  /// Riding along: glides in once, then [_trackChase] keeps it on the rider
  /// with every map update. Framing: aims at the road ahead of the rider on
  /// a new stage, and within a stage only once that road has clearly
  /// shrunk — the map holds still in between.
  void _follow({bool always = false}) {
    if (_chases) {
      if (_chase.live) {
        if (always) _trackChase(force: true);
      } else if (always || !_chase.active) {
        _flyIntoChase();
      }
      return;
    }
    _chase.end();
    final aim = _followState.shouldAim(
      stage: _stage,
      left: LiveMapCamera.leftMeters(widget.trip, _to, _stage),
      always: always,
      introStarted: _introStarted,
    );
    if (!aim) return;
    unawaited(
      _aim(LiveMapCamera.follow(widget.trip, _to, _stage, padding: _edge)),
    );
  }

  /// Whether the camera rides along with the rider now: after the entrance,
  /// while [LiveMapFollow.chases].
  bool get _chases =>
      _introStarted &&
      _followState.chases(stage: _stage, motion: !MotionGuard.reduced(context));

  /// Glides the camera in to ride along: to where the rider will be when
  /// the glide is over, so it lands on them.
  void _flyIntoChase() {
    if (_map == null) return;
    final pose = _chasePose(_riderMetersIn(AppMotion.cameraGlide));
    _zoom = pose.zoom;
    _chase.flyIn(() {
      if (mounted) _trackChase(force: true);
    });
    unawaited(_aim(CameraUpdate.newCameraPosition(pose)));
  }

  /// Keeps the camera riding along on the rider as the map shows them, when
  /// they moved since it last did ([force]: anyway).
  void _trackChase({bool force = false}) {
    if (_map == null || !_chase.shouldTrack(_shownMeters, force: force)) {
      return;
    }
    final pose = _chasePose(_shownMeters);
    _zoom = pose.zoom;
    unawaited(_aim(CameraUpdate.newCameraPosition(pose), jump: true));
  }

  CameraPosition _chasePose(double meters) => LiveMapChaseCamera.position(
    widget.trip,
    meters,
    _stage,
    map: _mapSize,
    padding: widget.padding,
  );

  /// Where the rider will be [ahead] from now: on along their glide, if
  /// one runs.
  double _riderMetersIn(Duration ahead) => _glide.isAnimating
      ? LiveMapGlide.metersAhead(
          from: _from,
          to: _to,
          done: _glide.value,
          length: _glide.duration ?? Duration.zero,
          ahead: ahead,
        )
      : _riderMeters;

  void _stopFollowing() {
    _chase.end();
    if (_followState.following) setState(_followState.stop);
  }

  /// The camera button: ride along (follow) again, or show the road ahead.
  void _onCameraAction(LiveMapCameraAction action) {
    setState(switch (action) {
      LiveMapCameraAction.follow => _followState.resume,
      LiveMapCameraAction.overview => _followState.showOverview,
    });
    _chase.end();
    _follow(always: true);
  }

  /// The map's own size, once laid out.
  Size get _mapSize {
    final box = context.findRenderObject();
    return box is RenderBox && box.hasSize ? box.size : Size.zero;
  }

  /// The room around a framed ride: [_frameEdge], or less where the map
  /// shows too little around it ([LiveMapCamera.fitEdge]).
  double get _edge {
    final size = _mapSize;
    if (size.isEmpty) return _frameEdge;
    return LiveMapCamera.fitEdge(_frameEdge, widget.padding.deflateSize(size));
  }

  Future<void> _aim(CameraUpdate update, {bool jump = false}) async {
    final map = _map;
    if (map == null) return;
    try {
      await (jump ? map.moveCamera(update) : map.glideTo(context, update));
    } on PlatformException catch (error) {
      log('camera: $error', name: _logName);
    }
  }

  /// The zoom the glide gate measures with, read when the camera settles —
  /// not on every camera frame, which would cost a message per frame. A
  /// camera riding along settles after every map update, at the zoom it was
  /// given: nothing to read.
  Future<void> _onCameraIdle() async {
    final map = _map;
    if (map == null || _chase.active) return;
    try {
      final zoom = await map.getZoomLevel();
      if (mounted) _zoom = zoom;
    } on PlatformException catch (error) {
      log('zoom: $error', name: _logName);
    }
  }

  /// A glide frame is worth a map update only once the rider has visibly
  /// moved or turned since the last one. With the camera riding along the
  /// whole map moves and turns under them: every glide frame is, up to
  /// [LiveMapFrameGate.chaseFrameGap].
  void _onGlideFrame() {
    if (_chase.live) {
      _onFrame(gap: LiveMapFrameGate.chaseFrameGap);
      return;
    }
    final meters = _riderMeters;
    final path = widget.trip.path;
    final moved = LiveMapFrameGate.riderMoved(
      shownMeters: _shownMeters,
      shownHeading: _shownHeading,
      meters: meters,
      heading: path.headingAround(meters),
      zoom: _zoom,
      latitude: path.pointAt(meters).lat,
    );
    if (moved) _onFrame();
  }

  void _onFrame({Duration gap = LiveMapFrameGate.frameGap}) {
    final binding = SchedulerBinding.instance;
    // A value set outside a frame (a jump) has no frame time: paint now.
    if (binding.schedulerPhase == SchedulerPhase.transientCallbacks) {
      final now = binding.currentFrameTimeStamp;
      if (LiveMapFrameGate.tooSoon(_lastFrame, now, gap: gap)) return;
      _lastFrame = now;
    }
    _repaint();
  }

  void _onSettled(AnimationStatus status) {
    if (status.isAnimating) return;
    if (_rings.isCompleted) _ringsAt = null;
    _repaint();
  }

  /// One map update: recut the road if due, note where the rider shows,
  /// and keep a camera riding along on them.
  void _repaint() {
    if (!mounted) return;
    _recutRoad();
    _shownMeters = _riderMeters;
    _shownHeading = widget.trip.path.headingAround(_shownMeters);
    _mapFrame.value++;
    _trackChase();
  }

  /// Recuts the road when the stage or the entrance changed it, or the
  /// rider has moved far enough on screen since the last cut
  /// ([LiveMapRoadCutter]); the entrance only draws in the planned road.
  void _recutRoad() {
    final overlays = _overlays;
    if (overlays == null) return;
    final meters = _riderMeters;
    final drawn = LiveMapRoadCutter.drawnAt(
      stage: _stage,
      entrance: _roadIn.transform(_intro.value),
    );
    final step = LiveMapFrameGate.lineStepMeters(
      _zoom,
      widget.trip.path.pointAt(meters).lat,
    );
    final due = _cutter.needsRecut(
      stage: _stage,
      drawn: drawn,
      meters: meters,
      stepMeters: step,
    );
    if (!due) return;
    _cutter.mark(stage: _stage, drawn: drawn, meters: meters);
    _road = overlays.polylines(lineMeters: meters, stage: _stage, drawn: drawn);
  }

  Set<Marker> _markers() =>
      _overlays?.markers(
        riderMeters: _shownMeters,
        stage: _stage,
        riderAlpha:
            AppMotion.signature.transform(_riderIn.value) *
            lerpDouble(
              1,
              _staleAlpha,
              AppMotion.signature.transform(_quiet.value),
            )!,
      ) ??
      const <Marker>{};

  Set<Circle> _circles() {
    final overlays = _overlays;
    final ringsAt = _ringsAt;
    if (overlays == null || ringsAt == null) return const <Circle>{};
    return overlays.rings(
      ringsAt,
      _ringsColor,
      lapsDone: _rings.value * LiveMapOverlays.ringRunLaps(_ringLaps),
      laps: _ringLaps,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CourierTrackingCubit, CourierTrackingState>(
          listenWhen: (previous, current) =>
              current.progress != null && previous.progress != current.progress,
          listener: (context, state) => _onProgress(state.progress!),
        ),
        BlocListener<CourierTrackingCubit, CourierTrackingState>(
          listenWhen: (previous, current) => previous.stale != current.stale,
          listener: (context, state) => _onStale(state.stale),
        ),
      ],
      child: Stack(
        children: [
          Positioned.fill(
            child: LiveMapPanWatch(
              onPanned: _stopFollowing,
              child: ValueListenableBuilder<int>(
                valueListenable: _mapFrame,
                builder: (context, _, _) => HeroMap(
                  target: LiveMapCamera.latLng(widget.trip.store),
                  zoom: LiveMapCamera.openingZoom,
                  style: HeroMapStyle.brand,
                  padding: widget.padding,
                  minMaxZoomPreference: LiveMapCamera.zoomRange,
                  markers: _markers(),
                  polylines: _road,
                  circles: _circles(),
                  onMapCreated: _onMapCreated,
                  onCameraIdle: _onCameraIdle,
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: AppSpacing.gutter,
            end: AppSpacing.gutter,
            bottom: widget.padding.bottom + AppSpacing.s16,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: LiveMapCameraButton(
                action: _followState.action(
                  stage: _stage,
                  motion: !MotionGuard.reduced(context),
                ),
                onPressed: _onCameraAction,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
