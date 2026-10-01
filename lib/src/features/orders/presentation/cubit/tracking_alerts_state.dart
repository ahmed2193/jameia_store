import 'package:equatable/equatable.dart';

/// Whether the ride can reach the phone's notification shade ([allowed]:
/// `null` until checked), and the live map's "get live updates" prompt.
class TrackingAlertsState extends Equatable {
  const TrackingAlertsState({
    this.allowed,
    this.asking = false,
    this.promptDismissed = false,
  });

  final bool? allowed;

  /// The phone's permission dialog is up.
  final bool asking;

  /// The customer answered the prompt on this map (either way).
  final bool promptDismissed;

  /// The prompt shows while the shade is closed to the app and the customer
  /// has not answered it here.
  bool get showPrompt => allowed == false && !promptDismissed;

  TrackingAlertsState copyWith({
    bool? allowed,
    bool? asking,
    bool? promptDismissed,
  }) => TrackingAlertsState(
    allowed: allowed ?? this.allowed,
    asking: asking ?? this.asking,
    promptDismissed: promptDismissed ?? this.promptDismissed,
  );

  @override
  List<Object?> get props => [allowed, asking, promptDismissed];
}
