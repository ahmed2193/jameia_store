import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/notifications/local_alerts.dart';
import 'package:hero_mart/src/features/orders/data/datasources/tracking_alerts_data_source.dart';
import 'package:hero_mart/src/features/orders/data/repositories/tracking_alerts_repository_impl.dart';
import 'package:hero_mart/src/features/orders/domain/entities/rider_chat.dart';
import 'package:hero_mart/src/features/orders/domain/entities/rider_chat_message.dart';
import 'package:hero_mart/src/features/orders/domain/entities/rider_quick_reply.dart';
import 'package:hero_mart/src/features/orders/domain/repositories/rider_chat_repository.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/allow_tracking_alerts_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/check_tracking_alerts_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/clear_tracking_alert_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/mark_rider_chat_read_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/send_rider_message_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/show_tracking_alert_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/watch_rider_chat_usecase.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/rider_chat_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/tracking_alerts_cubit.dart';

/// Records what would reach the notification shade.
class FakeLocalAlerts implements LocalAlerts {
  FakeLocalAlerts({this.granted = true, this.onAsk = true});

  bool granted;
  bool onAsk;
  int asks = 0;
  final List<LocalAlert> shown = [];
  final List<int> cancelled = [];

  @override
  Future<bool> allowed() async => granted;

  @override
  Future<bool> ask() async {
    asks++;
    return granted = onAsk;
  }

  @override
  Future<void> show(LocalAlert alert) async => shown.add(alert);

  @override
  Future<void> cancel(int id) async => cancelled.add(id);
}

/// The live map's alerts cubit over [shade], through the real data and
/// domain layers.
TrackingAlertsCubit buildTrackingAlertsCubit(FakeLocalAlerts shade) {
  final repository = TrackingAlertsRepositoryImpl(
    TrackingAlertsDataSourceImpl(shade),
  );
  return TrackingAlertsCubit(
    check: CheckTrackingAlertsUseCase(repository),
    allow: AllowTrackingAlertsUseCase(repository),
    show: ShowTrackingAlertUseCase(repository),
    clear: ClearTrackingAlertUseCase(repository),
  );
}

/// A rider message sent at [at].
RiderChatMessage riderSays(String id, DateTime at, {String text = 'Hi'}) =>
    RiderChatMessage(
      id: id,
      fromRider: true,
      sentAt: at,
      textEn: text,
      textAr: text,
    );

/// A chat the test drives by hand: [push] the conversation, read what was
/// [sent]; [failWith] makes the next sends fail.
class FakeRiderChatRepository implements RiderChatRepository {
  final StreamController<RiderChat> _chat =
      StreamController<RiderChat>.broadcast();
  final List<(String, String, RiderQuickReply?)> sent = [];
  final List<String> watched = [];

  /// Every read marker the cubit stored, oldest first.
  final List<(String, DateTime)> read = [];
  Failure? failWith;

  /// Holds the next send until completed.
  Completer<void>? gate;

  void push(RiderChat chat) => _chat.add(chat);

  @override
  Stream<RiderChat> watch(String orderId) {
    watched.add(orderId);
    return _chat.stream;
  }

  @override
  Future<Either<Failure, Unit>> send(
    String orderId,
    String text, {
    RiderQuickReply? quick,
  }) async {
    await gate?.future;
    final failure = failWith;
    if (failure != null) return Left(failure);
    sent.add((orderId, text, quick));
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> markRead(String orderId, DateTime at) async {
    read.add((orderId, at));
    return const Right(unit);
  }
}

RiderChatCubit buildRiderChatCubit(RiderChatRepository repository) =>
    RiderChatCubit(
      watch: WatchRiderChatUseCase(repository),
      send: SendRiderMessageUseCase(repository),
      markRead: MarkRiderChatReadUseCase(repository),
    );
