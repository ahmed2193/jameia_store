import 'dart:convert';
import 'dart:developer';

import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/local_storage.dart';
import '../models/assistant_nudge_log_model.dart';

/// The assistant greeting's log on the device ([LocalStorage]).
abstract class AssistantNudgeLocalDataSource {
  /// An empty log when nothing (or nothing readable) is stored.
  AssistantNudgeLogModel read();

  /// Throws [CacheException] when the log could not be written.
  Future<void> write(AssistantNudgeLogModel log);
}

class AssistantNudgeLocalDataSourceImpl
    implements AssistantNudgeLocalDataSource {
  const AssistantNudgeLocalDataSourceImpl(this._storage);

  final LocalStorage _storage;

  static const String logKey = 'assistant.nudge.v1';

  @override
  AssistantNudgeLogModel read() {
    final raw = _storage.getString(logKey);
    if (raw == null) return const AssistantNudgeLogModel();
    try {
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) {
        return AssistantNudgeLogModel.fromJson(json);
      }
    } on FormatException catch (error) {
      log('Unreadable assistant nudge log: $error', name: 'assistant');
    }
    return const AssistantNudgeLogModel();
  }

  @override
  Future<void> write(AssistantNudgeLogModel log) async {
    final written = await _storage.setString(logKey, jsonEncode(log.toJson()));
    if (!written) {
      throw const CacheException('Could not store the assistant nudge log');
    }
  }
}
