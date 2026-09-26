import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/event_stream_client.dart';
import 'assistant_block_model.dart';
import 'assistant_message_model.dart';

/// One frame of `POST /v1/assistant/messages`, decoded.
///
/// [AssistantStreamEventModel.fromFrame] returns `null` for an event name
/// this build does not know (skipped quietly) and throws [ParsingException]
/// for a known frame with a broken payload (the datasource logs and skips
/// it: one bad frame never kills the turn).
sealed class AssistantStreamEventModel {
  const AssistantStreamEventModel();

  static const String messageStartEvent = 'message_start';
  static const String userMessageEvent = 'user_message';
  static const String textDeltaEvent = 'text_delta';
  static const String toolStartEvent = 'tool_start';
  static const String toolEndEvent = 'tool_end';
  static const String blockEvent = 'block';
  static const String messageEndEvent = 'message_end';
  static const String errorEvent = 'error';

  static const String conversationIdKey = 'conversationId';
  static const String messageKey = 'message';
  static const String deltaKey = 'delta';
  static const String nameKey = 'name';
  static const String callIdKey = 'callId';
  static const String okKey = 'ok';
  static const String blockKey = 'block';
  static const String codeKey = 'code';

  static const Set<String> knownEvents = {
    messageStartEvent,
    userMessageEvent,
    textDeltaEvent,
    toolStartEvent,
    toolEndEvent,
    blockEvent,
    messageEndEvent,
    errorEvent,
  };

  static AssistantStreamEventModel? fromFrame(ServerSentEvent frame) {
    if (!knownEvents.contains(frame.event)) return null;
    final json = frame.json;
    if (json == null) {
      throw ParsingException('${frame.event}: payload is not a JSON object');
    }
    return switch (frame.event) {
      messageStartEvent => AssistantStreamStartedModel(_conversationId(json)),
      userMessageEvent => AssistantStreamUserMessageModel(
        conversationId: _conversationId(json),
        message: AssistantMessageModel.fromJson(_object(json, messageKey)),
      ),
      textDeltaEvent => AssistantStreamTextDeltaModel(
        // Raw: never trimmed — a delta is often just " " or ":\n".
        json[deltaKey] is String ? json[deltaKey] as String : '',
      ),
      toolStartEvent => AssistantStreamToolStartedModel(
        name: JsonRead.string(json[nameKey]) ?? '',
        callId: JsonRead.string(json[callIdKey]) ?? '',
      ),
      toolEndEvent => AssistantStreamToolFinishedModel(
        name: JsonRead.string(json[nameKey]) ?? '',
        callId: JsonRead.string(json[callIdKey]) ?? '',
        ok: JsonRead.flag(json[okKey], fallback: true),
      ),
      blockEvent => AssistantStreamBlockModel(
        AssistantBlockModel.fromJson(_object(json, blockKey)),
      ),
      messageEndEvent => AssistantStreamCompletedModel(
        conversationId: _conversationId(json),
        message: AssistantMessageModel.fromJson(_object(json, messageKey)),
      ),
      // The code may be a string or a number ("a statusMessage or an
      // HTTP-like code").
      errorEvent => AssistantStreamFailedModel(
        code: '${json[codeKey] ?? ''}',
        message: JsonRead.string(json[messageKey]) ?? '',
      ),
      _ => null,
    };
  }

  static String _conversationId(Map<String, dynamic> json) {
    final id = JsonRead.string(json[conversationIdKey]);
    if (id == null) {
      throw const ParsingException('frame: conversationId missing');
    }
    return id;
  }

  static Map<String, dynamic> _object(Map<String, dynamic> json, String key) {
    final object = JsonRead.object(json[key]);
    if (object == null) throw ParsingException('frame: "$key" missing');
    return object;
  }
}

final class AssistantStreamStartedModel extends AssistantStreamEventModel {
  const AssistantStreamStartedModel(this.conversationId);

  final String conversationId;
}

final class AssistantStreamUserMessageModel extends AssistantStreamEventModel {
  const AssistantStreamUserMessageModel({
    required this.conversationId,
    required this.message,
  });

  final String conversationId;
  final AssistantMessageModel message;
}

final class AssistantStreamTextDeltaModel extends AssistantStreamEventModel {
  const AssistantStreamTextDeltaModel(this.delta);

  final String delta;
}

final class AssistantStreamToolStartedModel extends AssistantStreamEventModel {
  const AssistantStreamToolStartedModel({
    required this.name,
    required this.callId,
  });

  final String name;
  final String callId;
}

final class AssistantStreamToolFinishedModel extends AssistantStreamEventModel {
  const AssistantStreamToolFinishedModel({
    required this.name,
    required this.callId,
    this.ok = true,
  });

  final String name;
  final String callId;
  final bool ok;
}

final class AssistantStreamBlockModel extends AssistantStreamEventModel {
  const AssistantStreamBlockModel(this.block);

  final AssistantBlockModel block;
}

final class AssistantStreamCompletedModel extends AssistantStreamEventModel {
  const AssistantStreamCompletedModel({
    required this.conversationId,
    required this.message,
  });

  final String conversationId;
  final AssistantMessageModel message;
}

final class AssistantStreamFailedModel extends AssistantStreamEventModel {
  const AssistantStreamFailedModel({required this.code, this.message = ''});

  final String code;
  final String message;
}
