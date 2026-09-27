// The greeting log on the device: JSON both ways, garbage read as "never",
// a failed write surfaces as a CacheFailure.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/core/storage/local_storage.dart';
import 'package:jameia_mart/src/features/assistant/data/datasources/assistant_nudge_local_data_source.dart';
import 'package:jameia_mart/src/features/assistant/data/mappers/assistant_nudge_log_mapper.dart';
import 'package:jameia_mart/src/features/assistant/data/models/assistant_nudge_log_model.dart';
import 'package:jameia_mart/src/features/assistant/data/repositories/assistant_nudge_repository_impl.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_nudge_log.dart';

class _MapStorage implements LocalStorage {
  final Map<String, Object> values = {};
  bool refuseWrites = false;

  @override
  String? getString(String key) => values[key] as String?;

  @override
  Future<bool> setString(String key, String value) async {
    if (refuseWrites) return false;
    values[key] = value;
    return true;
  }

  @override
  bool? getBool(String key) => values[key] as bool?;

  @override
  Future<bool> setBool(String key, {required bool value}) async {
    values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async => values.remove(key) != null;
}

void main() {
  final log = AssistantNudgeLog(
    lastShownAt: DateTime(2026, 9, 27, 9, 30),
    lastOpenedAt: DateTime(2026, 9, 26, 20),
    snoozedUntil: DateTime(2026, 9, 30),
    ignoredInARow: 1,
    launcherHiddenUntil: DateTime(2026, 9, 28),
    onboardedAt: DateTime(2026, 9, 25, 18),
  );

  test('entity → model → JSON → model → entity keeps every value', () {
    final json = jsonDecode(jsonEncode(log.toModel().toJson()));
    final back = AssistantNudgeLogModel.fromJson(json as Map<String, dynamic>)
        .toEntity();
    expect(back, log);
  });

  test('an empty log writes no moments', () {
    expect(AssistantNudgeLog.empty.toModel().toJson(), {'ignoredInARow': 0});
  });

  test('values of the wrong type read as "never"', () {
    final model = AssistantNudgeLogModel.fromJson({
      'lastShownAt': 'yesterday',
      'ignoredInARow': null,
      'snoozedUntil': 1.5,
    });
    expect(model.toEntity(), AssistantNudgeLog.empty);
  });

  group('AssistantNudgeLocalDataSource', () {
    late _MapStorage storage;
    late AssistantNudgeLocalDataSource source;

    setUp(() {
      storage = _MapStorage();
      source = AssistantNudgeLocalDataSourceImpl(storage);
    });

    test('nothing stored reads as an empty log', () {
      expect(source.read().toEntity(), AssistantNudgeLog.empty);
    });

    test('unreadable JSON reads as an empty log', () {
      storage.values[AssistantNudgeLocalDataSourceImpl.logKey] = '{oops';
      expect(source.read().toEntity(), AssistantNudgeLog.empty);
      storage.values[AssistantNudgeLocalDataSourceImpl.logKey] = '[1, 2]';
      expect(source.read().toEntity(), AssistantNudgeLog.empty);
    });

    test('a written log reads back', () async {
      await source.write(log.toModel());
      expect(source.read().toEntity(), log);
    });

    test('a refused write throws CacheException', () {
      storage.refuseWrites = true;
      expect(() => source.write(log.toModel()), throwsA(isA<CacheException>()));
    });

    test('the repository maps a refused write to CacheFailure', () async {
      storage.refuseWrites = true;
      final result = await AssistantNudgeRepositoryImpl(source)
          .updateLog((_) => log);
      expect(
        result.fold((failure) => failure, (_) => null),
        isA<CacheFailure>(),
      );
    });

    test('changes made at once both land', () async {
      final repository = AssistantNudgeRepositoryImpl(source);
      final at = DateTime(2026, 9, 27, 9);
      await Future.wait([
        repository.updateLog((log) => log.onboarded(at)),
        repository.updateLog((log) => log.shownAt(at)),
      ]);
      final stored = source.read().toEntity();
      expect(stored.onboardedAt, at);
      expect(stored.lastShownAt, at);
    });

    test('an unchanged log is not written', () async {
      storage.refuseWrites = true;
      final result = await AssistantNudgeRepositoryImpl(source)
          .updateLog((log) => log);
      expect(result.isRight(), isTrue);
    });
  });
}
