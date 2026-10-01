import '../../../../core/notifications/local_alerts.dart';
import '../../domain/entities/tracking_alert.dart';

/// The ride's notifications, through the phone's notification shade.
abstract class TrackingAlertsDataSource {
  Future<bool> allowed();
  Future<bool> ask();
  Future<void> show(TrackingAlert alert);
  Future<void> clearRide(String orderId);
}

/// One ride card per order (posted again = updated in place, with the ride
/// drawn on it), one moment slot and one message slot per order (a newer
/// one replaces the older), all with ids drawn from the order id.
class TrackingAlertsDataSourceImpl implements TrackingAlertsDataSource {
  const TrackingAlertsDataSourceImpl(this._alerts);

  final LocalAlerts _alerts;

  static const int _fnvOffset = 0x811C9DC5;
  static const int _fnvPrime = 0x01000193;
  static const int _mask32 = 0xFFFFFFFF;
  static const int _idMask = 0x1FFFFFFF;
  static const int _slots = 4;

  @override
  Future<bool> allowed() => _alerts.allowed();

  @override
  Future<bool> ask() => _alerts.ask();

  @override
  Future<void> show(TrackingAlert alert) {
    final ride = alert.kind == TrackingAlertKind.ride;
    final progress = ride ? alert.progress : null;
    return _alerts.show(
      LocalAlert(
        id: switch (alert.kind) {
          TrackingAlertKind.ride => rideIdOf(alert.orderId),
          TrackingAlertKind.moment => momentIdOf(alert.orderId),
          TrackingAlertKind.message => messageIdOf(alert.orderId),
        },
        channel: switch (alert.kind) {
          TrackingAlertKind.ride => LocalAlertChannel.live,
          TrackingAlertKind.moment => LocalAlertChannel.updates,
          TrackingAlertKind.message => LocalAlertChannel.messages,
        },
        channelName: alert.channelName,
        title: alert.title,
        body: alert.body,
        subText: alert.orderLabel.isEmpty ? null : alert.orderLabel,
        progress: progress,
        dueAt: ride ? alert.arrivesAt : null,
        ongoing: ride && alert.riding,
        track: progress == null || !alert.riding
            ? null
            : LocalAlertTrack(
                progress: progress,
                rightToLeft: alert.rightToLeft,
              ),
      ),
    );
  }

  @override
  Future<void> clearRide(String orderId) => _alerts.cancel(rideIdOf(orderId));

  /// The ride card's id, then the moment's and the message's right after
  /// it (each order has a block of [_slots] ids, all within a 32-bit int).
  static int rideIdOf(String orderId) => (_hash(orderId) & _idMask) * _slots;
  static int momentIdOf(String orderId) => rideIdOf(orderId) + 1;
  static int messageIdOf(String orderId) => rideIdOf(orderId) + 2;

  /// FNV-1a: the same order, the same ids, every run.
  static int _hash(String id) {
    var hash = _fnvOffset;
    for (final unit in id.codeUnits) {
      hash = ((hash ^ unit) * _fnvPrime) & _mask32;
    }
    return hash;
  }
}
