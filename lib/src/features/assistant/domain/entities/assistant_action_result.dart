import 'package:equatable/equatable.dart';

import 'assistant_block.dart';

/// `POST /v1/assistant/actions/{actionId}/confirm` → `{ message, blocks }`:
/// the confirmed proposal (`cart_action`, status `confirmed`) and usually a
/// `cart_summary`. [message] is shown as sent.
class AssistantActionResult extends Equatable {
  const AssistantActionResult({
    this.message = '',
    this.blocks = const <AssistantBlock>[],
  });

  final String message;
  final List<AssistantBlock> blocks;

  @override
  List<Object?> get props => [message, blocks];
}
