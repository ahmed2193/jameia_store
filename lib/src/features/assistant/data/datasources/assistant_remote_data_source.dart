import 'dart:developer';

import '../../../../core/data/models/remote_payload.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../../../../core/network/event_stream_client.dart';
import '../models/assistant_conversation_model.dart';
import '../models/assistant_reply_models.dart';
import '../models/assistant_stream_event_model.dart';

/// The Hero shopping assistant. Identity is automatic: the Bearer while
/// signed in, `X-Assistant-Guest` otherwise (both added by the interceptors
/// — this class never touches a header or the session).
abstract class AssistantRemoteDataSource {
  /// `GET /v1/init` → `store.assistant` + `store.featureFlags.assistant`.
  /// Memoized for the app run; a failed read is not.
  Future<AssistantAvailabilityModel> getAvailability();

  /// `GET /v1/assistant/conversations?page&limit` (newest activity first),
  /// with its raw `results` for the device copy (the first page).
  Future<RemotePayload<AssistantConversationsPageModel>> getConversations({
    required int page,
    required int limit,
  });

  /// `GET /v1/assistant/conversations/{id}`.
  Future<AssistantConversationDetailModel> getConversation(String id);

  /// `POST /v1/assistant/messages` `{ message, conversationId? }` →
  /// `text/event-stream`, one frame per event. Sent ONCE (no replay).
  Stream<AssistantStreamEventModel> sendMessage({
    required String message,
    String? conversationId,
  });

  /// `POST /v1/assistant/actions/{actionId}/confirm`.
  Future<AssistantActionResultModel> confirmAction(String actionId);

  /// `POST /v1/assistant/conversations/{id}/handoff` with an empty object:
  /// the body is required, every field optional, and the app never guesses a
  /// ticket category.
  Future<AssistantHandoffTicketModel> requestHandoff(String conversationId);

  /// `POST /v1/assistant/messages/{messageId}/feedback`
  /// `{ feedback: "up" | "down" | null }`.
  Future<void> rateMessage({required String messageId, String? feedback});
}

class AssistantRemoteDataSourceImpl implements AssistantRemoteDataSource {
  AssistantRemoteDataSourceImpl(this._api, this._events);

  final ApiConsumer _api;
  final EventStreamClient _events;

  static const String pageField = 'page';
  static const String limitField = 'limit';
  static const String messageField = 'message';
  static const String conversationIdField = 'conversationId';
  static const String feedbackField = 'feedback';
  static const String _logName = 'AssistantRemoteDataSource';

  Future<AssistantAvailabilityModel>? _availability;

  @override
  Future<AssistantAvailabilityModel> getAvailability() {
    final known = _availability;
    if (known != null) return known;
    final request = _fetchAvailability();
    _availability = request;
    // A failure is not kept: forget it so the next caller asks again.
    request.then<void>(
      (_) {},
      onError: (Object _) {
        if (identical(_availability, request)) _availability = null;
      },
    );
    return request;
  }

  Future<AssistantAvailabilityModel> _fetchAvailability() async {
    final results = await _api.get(EndPoints.init);
    return AssistantAvailabilityModel.fromInitJson(
      ApiPayload.asMap(results, EndPoints.init),
    );
  }

  @override
  Future<RemotePayload<AssistantConversationsPageModel>> getConversations({
    required int page,
    required int limit,
  }) async {
    final results = await _api.get(
      EndPoints.assistantConversations,
      queryParameters: <String, dynamic>{pageField: page, limitField: limit},
    );
    final json = ApiPayload.asMap(results, EndPoints.assistantConversations);
    return RemotePayload(
      AssistantConversationsPageModel.fromJson(json, requestedPage: page),
      json,
    );
  }

  @override
  Future<AssistantConversationDetailModel> getConversation(String id) async {
    final path = EndPoints.assistantConversation(id);
    final results = await _api.get(path);
    return AssistantConversationDetailModel.fromJson(
      ApiPayload.asMap(results, path),
    );
  }

  @override
  Stream<AssistantStreamEventModel> sendMessage({
    required String message,
    String? conversationId,
  }) => _events
      .send(
        EndPoints.assistantMessages,
        data: <String, dynamic>{
          messageField: message,
          conversationIdField: ?conversationId,
        },
      )
      .expand(_parseFrame);

  @override
  Future<AssistantActionResultModel> confirmAction(String actionId) async {
    final path = EndPoints.assistantActionConfirm(actionId);
    final results = await _api.post(path);
    return AssistantActionResultModel.fromJson(ApiPayload.asMap(results, path));
  }

  @override
  Future<AssistantHandoffTicketModel> requestHandoff(
    String conversationId,
  ) async {
    final path = EndPoints.assistantHandoff(conversationId);
    final results = await _api.post(path);
    return AssistantHandoffTicketModel.fromJson(
      ApiPayload.asMap(results, path),
    );
  }

  @override
  Future<void> rateMessage({
    required String messageId,
    String? feedback,
  }) async {
    await _api.post(
      EndPoints.assistantMessageFeedback(messageId),
      body: <String, dynamic>{feedbackField: feedback},
    );
  }

  /// Zero or one event per frame: an unknown event name is skipped quietly,
  /// a broken payload is logged and skipped — the turn goes on.
  static Iterable<AssistantStreamEventModel> _parseFrame(
    ServerSentEvent frame,
  ) {
    try {
      final event = AssistantStreamEventModel.fromFrame(frame);
      return event == null ? const [] : [event];
    } on AppException catch (error) {
      log('dropped ${frame.event} frame: $error', name: _logName);
      return const [];
    }
  }
}
