import 'package:equatable/equatable.dart';

/// Which kind of notification a [TrackingAlert] is.
enum TrackingAlertKind {
  /// The quiet card that follows the ride in the notification shade: who is
  /// bringing the order, when, and how far along — updated in place, and
  /// not swiped away while the ride lasts.
  ride,

  /// A moment that sounds and pops up (the order on its way, the rider
  /// almost there, at the door) — while the customer is away from the app.
  moment,

  /// A message from the rider, while the customer is away from the app.
  message,
}

/// What the phone's notification shade shows of a ride, with the texts
/// already in the customer's language (the page composes them).
class TrackingAlert extends Equatable {
  const TrackingAlert({
    required this.orderId,
    required this.kind,
    required this.channelName,
    required this.title,
    required this.body,
    this.orderLabel = '',
    this.progress,
    this.arrivesAt,
    this.riding = true,
    this.rightToLeft = false,
  });

  final String orderId;
  final TrackingAlertKind kind;

  /// The name of the notification channel, shown in the phone's settings.
  final String channelName;
  final String title;
  final String body;

  /// The order as the customer knows it ("Order JM-2004"); empty = none.
  final String orderLabel;

  /// How far along the delivery is (0 → 1); `null` = no bar.
  final double? progress;

  /// When the rider is due at the door: the card counts down to it.
  final DateTime? arrivesAt;

  /// The ride is still going: a [TrackingAlertKind.ride] card cannot be
  /// swiped away until it ends.
  final bool riding;

  /// The customer reads right to left: the ride card's picture runs that
  /// way (store on the right, home on the left).
  final bool rightToLeft;

  @override
  List<Object?> get props => [
    orderId,
    kind,
    channelName,
    title,
    body,
    orderLabel,
    progress,
    arrivesAt,
    riding,
    rightToLeft,
  ];
}
