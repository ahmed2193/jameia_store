import '../../../../core/data/datasources/cache_slots.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../../../../core/storage/cache_namespace.dart';
import '../models/assistant_conversation_model.dart';

/// The assistant history as last shown: its first page, per language.
/// Customer-only: a guest's chats move to the customer at sign-in and the
/// app then starts a new guest id, so a guest copy could list chats the next
/// guest cannot open — nothing is kept for a guest. Wiped on sign-out.
/// Parsed back with the DTO's own `fromJson`.
abstract class AssistantHistoryCacheDataSource {
  /// `GET /v1/assistant/conversations` — the first page of [limit].
  CacheSlot<AssistantConversationsPageModel>? firstPage({required int limit});
}

class AssistantHistoryCacheDataSourceImpl
    implements AssistantHistoryCacheDataSource {
  const AssistantHistoryCacheDataSourceImpl(this._slots);

  final CacheSlots _slots;

  static const int _firstPage = 1;

  static const CacheNamespace historyNamespace = CacheNamespace(
    'assistant.history',
    scope: CacheScope.customer,
    freshFor: Duration(seconds: 60),
    maxAge: Duration(days: 14),
  );

  @override
  CacheSlot<AssistantConversationsPageModel>? firstPage({required int limit}) =>
      _slots.of(
        historyNamespace,
        id: '$limit',
        parse: (raw) => AssistantConversationsPageModel.fromJson(
          ApiPayload.asMap(raw, EndPoints.assistantConversations),
          requestedPage: _firstPage,
        ),
      );
}
