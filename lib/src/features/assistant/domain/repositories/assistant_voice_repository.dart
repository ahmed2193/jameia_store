import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/assistant_voice_access.dart';
import '../entities/assistant_voice_event.dart';
import '../entities/assistant_voice_language.dart';

/// Talking to the assistant: the device's microphone and speech recognizer
/// turn what the customer says into the words of a message, and the chat
/// sends the words. The app keeps no recording.
abstract class AssistantVoiceRepository {
  /// Gets the recognizer ready when the microphone is already allowed,
  /// asking nothing: `granted` / `unavailable` then, `blocked` when refused
  /// for good, `null` while the customer has not been asked.
  Future<Either<Failure, AssistantVoiceAccess?>> prepare();

  /// Asks for the microphone the first time; afterwards answers at once.
  Future<Either<Failure, AssistantVoiceAccess>> requestAccess();

  /// Listens in [languageCode] until [finish] or [cancel]: words and levels
  /// as they come, then one done / failed event, then the stream closes.
  /// One message at a time — a new one drops the previous. Cancelling the
  /// subscription is a [cancel]: the microphone closes and the words go.
  Stream<AssistantVoiceEvent> listen({required String languageCode});

  /// Stops listening; the last words arrive as the done event.
  Future<Either<Failure, Unit>> finish();

  /// Stops listening and drops the words: the stream closes without done.
  Future<Either<Failure, Unit>> cancel();

  /// Opens this app's page in the system settings (microphone blocked).
  Future<Either<Failure, Unit>> openSettings();

  /// The language the customer last chose to talk in; `null` until they
  /// choose one.
  Future<Either<Failure, AssistantVoiceLanguage?>> savedLanguage();

  /// Remembers [language] for the next voice messages.
  Future<Either<Failure, Unit>> saveLanguage(AssistantVoiceLanguage language);
}
