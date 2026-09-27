import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/error/failures.dart';
import '../entities/assistant_action_result.dart';
import '../entities/assistant_availability.dart';
import '../entities/assistant_conversations_feed.dart';
import '../entities/assistant_handoff_ticket.dart';
import '../entities/assistant_message_entity.dart';
import '../entities/assistant_stream_event.dart';
import '../entities/assistant_thread.dart';

/// The Hero shopping assistant (`/v1/assistant/*`). Signed in → the
/// customer's threads; signed out → the device guest's (`X-Assistant-Guest`,
/// merged into the customer at login).
abstract class AssistantRepository {
  /// Whether the store runs the assistant; read once per app run.
  Future<Either<Failure, AssistantAvailability>> getAvailability();

  Future<Either<Failure, AssistantConversationsFeed>> getConversations({
    required int page,
    required int limit,
  });

  /// One conversation with its messages, as a thread.
  /// The history's first page as the history screen reads it: the
  /// signed-in customer's saved copy first (nothing is kept for a guest),
  /// then the server's (only the server's with [forceRefresh]); failures on
  /// the error channel. Later pages are [getConversations]' — never kept.
  Stream<DataSnapshot<AssistantConversationsFeed>> watchFirstPage({
    required int limit,
    bool forceRefresh = false,
  });

  Future<Either<Failure, AssistantThread>> getConversation(String id);

  /// Sends [message] and streams the reply. Errors travel as stream errors
  /// carrying a `Failure` (validation, signed out, offline, dropped
  /// connection); an in-band failure is an `AssistantStreamFailed` event.
  Stream<AssistantStreamEvent> sendMessage({
    required String message,
    String? conversationId,
  });

  Future<Either<Failure, AssistantActionResult>> confirmAction(String actionId);

  Future<Either<Failure, AssistantHandoffTicket>> requestHandoff(
    String conversationId,
  );

  /// [feedback] `none` clears the rating.
  Future<Either<Failure, Unit>> rateMessage({
    required String messageId,
    required AssistantFeedback feedback,
  });
}
