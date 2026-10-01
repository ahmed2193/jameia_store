import 'dart:async';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/motion/earcons.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../domain/entities/courier_progress.dart';
import '../../../domain/entities/courier_stage.dart';
import '../../../domain/entities/courier_trip.dart';
import '../../../domain/entities/tracking_alert.dart';
import '../../../domain/entities/tracking_alert_rules.dart';
import '../../cubit/courier_tracking_cubit.dart';
import '../../cubit/courier_tracking_state.dart';
import '../../cubit/rider_chat_cubit.dart';
import '../../cubit/rider_chat_state.dart';
import '../../cubit/tracking_alerts_cubit.dart';

/// Marks the ride's moments and keeps the phone's notification shade in
/// step with it ([TrackingAlertRules]):
///
/// * in the app: a haptic at each stage that matters, and the brand chime
///   when the rider is almost there and at the door;
/// * in the shade: a quiet card that follows the ride ("Arriving in 5 min",
///   the rider and the stage, minutes counting down, a bar, and expanded
///   the ride drawn store → rider → home), posted again when it changed
///   and whenever the customer leaves the app; while they are away, the
///   moments sound as notifications instead of chimes, and the rider's
///   messages arrive as notifications too (in the app, a tap of haptics
///   while the chat is shut).
class LiveMapAlerts extends StatefulWidget {
  const LiveMapAlerts({super.key, required this.order, required this.child});

  final OrderEntity order;
  final Widget child;

  @override
  State<LiveMapAlerts> createState() => _LiveMapAlertsState();
}

class _LiveMapAlertsState extends State<LiveMapAlerts>
    with WidgetsBindingObserver {
  CourierProgress? _shown;
  CourierProgress? _last;

  /// The chat just before the snapshot that brought new messages.
  RiderChatState _chatBefore = const RiderChatState();

  bool get _inFront =>
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(context.read<TrackingAlertsCubit>().check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      // Back from the settings the prompt may have sent them to.
      unawaited(context.read<TrackingAlertsCubit>().check());
      return;
    }
    if (state != AppLifecycleState.paused) return;
    final trip = context.read<CourierTrackingCubit>().state.trip;
    final progress = _last;
    if (trip != null && progress != null) _postCard(trip, progress);
  }

  void _onRide(BuildContext context, CourierTrackingState state) {
    final trip = state.trip;
    final progress = state.progress;
    if (trip == null || progress == null) return;
    final before = _last;
    _last = progress;
    // The chat opens as the rider heads here — in the app or away from it
    // (the rider card that also opens it is only built on screen).
    if (progress.stage.delivering) {
      context.read<RiderChatCubit>().start(trip.orderId);
    }
    if (TrackingAlertRules.isMoment(before, progress)) {
      _inFront ? _feel(progress.stage) : _postMoment(trip, progress);
    } else if (before != null && before.stage != progress.stage) {
      if (_inFront) _feel(progress.stage);
    }
    if (TrackingAlertRules.cardChanged(_shown, progress)) {
      _postCard(trip, progress);
    }
  }

  /// In the app: a haptic, and the chime at the two moments of arrival.
  static void _feel(CourierStage stage) {
    switch (stage) {
      case CourierStage.toStore || CourierStage.onTheWay:
        Haptics.pick();
      case CourierStage.nearby:
        Haptics.pick();
        unawaited(Earcons.play(Earcon.riderNearby));
      case CourierStage.arrived:
        Haptics.done();
        unawaited(Earcons.play(Earcon.orderArrived));
      case _:
        return;
    }
  }

  String _rider(CourierTrip trip) => trip.riderName.isEmpty
      ? 'orders.live_rider_default'.tr()
      : trip.riderName;

  String get _orderLabel => widget.order.orderNumber.isEmpty
      ? ''
      : 'orders.live_alert_order'.tr(
          namedArgs: {'number': widget.order.orderNumber},
        );

  void _postCard(CourierTrip trip, CourierProgress progress) {
    final alerts = context.read<TrackingAlertsCubit>();
    // Not counted as shown until it can be: the first card once allowed.
    if (alerts.state.allowed != true) return;
    _shown = progress;
    final minutes = progress.minutesLeft;
    final stage = progress.stage.labelKey.tr();
    unawaited(
      alerts.show(
        TrackingAlert(
          orderId: trip.orderId,
          kind: TrackingAlertKind.ride,
          channelName: 'orders.alerts_channel_live'.tr(),
          title: minutes == null || progress.arrived
              ? stage
              : 'orders.live_alert_arriving_in'.plural(
                  minutes,
                  namedArgs: {'minutes': '$minutes'},
                ),
          body: 'orders.live_alert_ride_line'.tr(
            namedArgs: {'rider': _rider(trip), 'stage': stage},
          ),
          orderLabel: _orderLabel,
          progress: progress.rideFraction,
          arrivesAt: progress.arrivesAt,
          riding: !progress.arrived,
          rightToLeft: Directionality.of(context) == TextDirection.rtl,
        ),
      ),
    );
  }

  /// A new message from the rider ([before]: the chat as it was): a haptic
  /// in the app while the chat is shut, a notification away from it (the
  /// sheet may be up behind another app). Nothing for a message read on an
  /// earlier open, nor a haptic for the greeting the chat opens with (the
  /// on-the-way haptic marks that moment).
  void _onChat(
    BuildContext context,
    RiderChatState before,
    RiderChatState now,
  ) {
    final messages = now.chat.messages;
    if (messages.isEmpty) return;
    final last = messages.last;
    if (!last.fromRider) return;
    final seen = before.readUpTo ?? now.chat.readUpTo;
    if (seen != null && !last.sentAt.isAfter(seen)) return;
    if (now.open && _inFront) return;
    if (_inFront) {
      if (before.chat.messages.isNotEmpty) Haptics.pick();
      return;
    }
    final trip = context.read<CourierTrackingCubit>().state.trip;
    if (trip == null) return;
    unawaited(
      context.read<TrackingAlertsCubit>().show(
        TrackingAlert(
          orderId: trip.orderId,
          kind: TrackingAlertKind.message,
          channelName: 'orders.alerts_channel_chat'.tr(),
          title: _rider(trip),
          body: last.textFor(context.locale.languageCode),
          orderLabel: _orderLabel,
        ),
      ),
    );
  }

  void _postMoment(CourierTrip trip, CourierProgress progress) {
    final minutes = progress.minutesLeft ?? 0;
    final args = {'rider': _rider(trip), 'minutes': '$minutes'};
    final (title, body) = switch (progress.stage) {
      CourierStage.nearby => (
        'orders.live_alert_nearby_title',
        'orders.live_alert_nearby_body'.tr(namedArgs: args),
      ),
      CourierStage.arrived => (
        'orders.live_alert_arrived_title',
        'orders.live_alert_arrived_body'.tr(namedArgs: args),
      ),
      _ => (
        'orders.live_alert_on_the_way_title',
        'orders.live_alert_on_the_way_body_count'.plural(
          minutes,
          namedArgs: args,
        ),
      ),
    };
    unawaited(
      context.read<TrackingAlertsCubit>().show(
        TrackingAlert(
          orderId: trip.orderId,
          kind: TrackingAlertKind.moment,
          channelName: 'orders.alerts_channel_updates'.tr(),
          title: title.tr(),
          body: body,
          orderLabel: _orderLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<CourierTrackingCubit, CourierTrackingState>(
        listenWhen: (before, now) =>
            now.progress != null && before.progress != now.progress,
        listener: _onRide,
      ),
      BlocListener<RiderChatCubit, RiderChatState>(
        listenWhen: (before, now) {
          final grew = now.chat.messages.length > before.chat.messages.length;
          if (grew) _chatBefore = before;
          return grew;
        },
        listener: (context, now) => _onChat(context, _chatBefore, now),
      ),
    ],
    child: widget.child,
  );
}
