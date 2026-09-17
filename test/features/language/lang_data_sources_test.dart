import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/network/dio_consumer.dart';
import 'package:jameia_mart/src/core/network/end_points.dart';
import 'package:jameia_mart/src/core/storage/local_storage.dart';
import 'package:jameia_mart/src/features/language/data/datasources/lang_local_data_source.dart';
import 'package:jameia_mart/src/features/language/data/datasources/lang_remote_data_source.dart';

import '../../core/network/network_test_fakes.dart';

class _MemoryStorage implements LocalStorage {
  final Map<String, Object> values = {};

  @override
  String? getString(String key) => values[key] as String?;

  @override
  Future<bool> setString(String key, String value) async {
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
  test(
    'local datasource persists the code and reports the session state',
    () async {
      final storage = _MemoryStorage();
      final session = InMemorySessionStore();
      final dataSource = LangLocalDataSourceImpl(storage, session);

      expect(await dataSource.getSavedLang(), '');
      await dataSource.changeLang('ar');
      expect(await dataSource.getSavedLang(), 'ar');

      expect(await dataSource.isSignedIn(), isFalse);
      session.accessToken = 'acc';
      expect(await dataSource.isSignedIn(), isTrue);
    },
  );

  test('remote datasource PATCHes { language } to the profile route', () async {
    final adapter = FakeHttpClientAdapter((_, _) => okBody({'_id': 'x'}));
    final dio = Dio()..httpClientAdapter = adapter;
    final dataSource = LangRemoteDataSourceImpl(DioConsumer(dio));

    await dataSource.syncLanguage('ar');

    final request = adapter.requests.single;
    expect(request.method, 'PATCH');
    expect(request.path, EndPoints.accountProfile);
    expect(Map<String, dynamic>.from(request.data as Map), {'language': 'ar'});
  });
}
