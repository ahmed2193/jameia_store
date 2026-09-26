import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';
import 'assistant_block_model.dart';

/// `POST /v1/assistant/actions/{actionId}/confirm` → `{ message, blocks[] }`.
class AssistantActionResultModel {
  const AssistantActionResultModel({
    this.message = '',
    this.blocks = const <AssistantBlockModel>[],
  });

  static const String messageKey = 'message';
  static const String blocksKey = 'blocks';

  final String message;
  final List<AssistantBlockModel> blocks;

  factory AssistantActionResultModel.fromJson(Map<String, dynamic> json) =>
      AssistantActionResultModel(
        message: JsonRead.string(json[messageKey]) ?? '',
        blocks: AssistantBlockModel.listFrom(json[blocksKey]),
      );
}

/// `POST /v1/assistant/conversations/{id}/handoff` →
/// `{ ticketId, ticketNumber, message }`.
class AssistantHandoffTicketModel {
  const AssistantHandoffTicketModel({
    required this.ticketId,
    this.ticketNumber = '',
    this.message = '',
  });

  static const String ticketIdKey = 'ticketId';
  static const String ticketNumberKey = 'ticketNumber';
  static const String messageKey = 'message';

  final String ticketId;
  final String ticketNumber;
  final String message;

  factory AssistantHandoffTicketModel.fromJson(Map<String, dynamic> json) {
    final ticketId = JsonRead.string(json[ticketIdKey]);
    if (ticketId == null) {
      throw const ParsingException('handoff: ticketId missing');
    }
    return AssistantHandoffTicketModel(
      ticketId: ticketId,
      ticketNumber: JsonRead.string(json[ticketNumberKey]) ?? '',
      message: JsonRead.string(json[messageKey]) ?? '',
    );
  }
}

/// The assistant's switches in `GET /v1/init`:
/// `store.assistant { enabled, allowGuests }` + `store.featureFlags.assistant`.
class AssistantAvailabilityModel {
  const AssistantAvailabilityModel({
    this.enabled = false,
    this.allowGuests = false,
    this.featureFlag,
  });

  static const String storeKey = 'store';
  static const String assistantKey = 'assistant';
  static const String enabledKey = 'enabled';
  static const String allowGuestsKey = 'allowGuests';
  static const String featureFlagsKey = 'featureFlags';

  final bool enabled;
  final bool allowGuests;

  /// `null` when `featureFlags` has no `assistant` key (it defaults to `{}`).
  final bool? featureFlag;

  /// Never throws: a store without the block runs no assistant.
  factory AssistantAvailabilityModel.fromInitJson(Map<String, dynamic> json) {
    final store = JsonRead.object(json[storeKey]) ?? const {};
    final assistant = JsonRead.object(store[assistantKey]) ?? const {};
    final flags = JsonRead.object(store[featureFlagsKey]) ?? const {};
    final flag = flags[assistantKey];
    return AssistantAvailabilityModel(
      enabled: JsonRead.flag(assistant[enabledKey]),
      allowGuests: JsonRead.flag(assistant[allowGuestsKey]),
      featureFlag: flag is bool ? flag : null,
    );
  }
}
