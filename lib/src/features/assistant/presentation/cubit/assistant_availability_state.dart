import 'package:equatable/equatable.dart';

/// `unknown` until `/v1/init` answered — and after a failed read, so the
/// entry points stay hidden rather than open a dead chat.
enum AssistantAvailabilityStatus { unknown, available, unavailable }

class AssistantAvailabilityState extends Equatable {
  const AssistantAvailabilityState({
    this.status = AssistantAvailabilityStatus.unknown,
    this.allowGuests = true,
  });

  final AssistantAvailabilityStatus status;

  /// Signed-out customers may chat (they get an `X-Assistant-Guest` id).
  final bool allowGuests;

  bool get isAvailable => status == AssistantAvailabilityStatus.available;

  @override
  List<Object?> get props => [status, allowGuests];
}
