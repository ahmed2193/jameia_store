import 'package:equatable/equatable.dart';

/// Whether the store runs the assistant (`GET /v1/init` →
/// `store.assistant { enabled, allowGuests }` + `store.featureFlags.assistant`).
class AssistantAvailability extends Equatable {
  const AssistantAvailability({
    this.enabled = false,
    this.allowGuests = false,
    this.featureFlag,
  });

  /// `store.assistant.enabled`.
  final bool enabled;

  /// Signed-out customers may chat (with the `X-Assistant-Guest` identity).
  final bool allowGuests;

  /// `store.featureFlags.assistant`; `null` when the store does not send it.
  final bool? featureFlag;

  /// Both switches must agree; a missing flag does not veto.
  bool get isAvailable => enabled && featureFlag != false;

  @override
  List<Object?> get props => [enabled, allowGuests, featureFlag];
}
