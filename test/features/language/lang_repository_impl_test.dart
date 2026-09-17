import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/language/data/datasources/lang_local_data_source.dart';
import 'package:jameia_mart/src/features/language/data/datasources/lang_remote_data_source.dart';
import 'package:jameia_mart/src/features/language/data/repositories/lang_repository_impl.dart';

class _FakeLocal implements LangLocalDataSource {
  String saved = '';
  bool signedIn = false;
  Object? error;

  @override
  Future<String> getSavedLang() async {
    if (error != null) throw error!;
    return saved;
  }

  @override
  Future<void> changeLang(String langCode) async => saved = langCode;

  @override
  Future<bool> isSignedIn() async => signedIn;
}

class _FakeRemote implements LangRemoteDataSource {
  final List<String> synced = [];
  Object? error;

  @override
  Future<void> syncLanguage(String langCode) async {
    if (error != null) throw error!;
    synced.add(langCode);
  }
}

void main() {
  late _FakeLocal local;
  late _FakeRemote remote;
  late LangRepositoryImpl repository;

  setUp(() {
    local = _FakeLocal();
    remote = _FakeRemote();
    repository = LangRepositoryImpl(local: local, remote: remote);
  });

  test(
    'getSavedLang reads the local choice; unreadable prefs → failure',
    () async {
      local.saved = 'ar';
      expect(
        await repository.getSavedLang(),
        const Right<Failure, String>('ar'),
      );

      local.error = const CacheException('prefs');
      expect((await repository.getSavedLang()).isLeft(), isTrue);
    },
  );

  test('changeLang persists locally and never touches the network', () async {
    local.signedIn = true;
    final result = await repository.changeLang(langCode: 'ar');

    expect(result, const Right<Failure, Unit>(unit));
    expect(local.saved, 'ar');
    expect(remote.synced, isEmpty);
  });

  test('syncLanguage is a no-op success while signed out', () async {
    final result = await repository.syncLanguage(langCode: 'ar');

    expect(result, const Right<Failure, Unit>(unit));
    expect(remote.synced, isEmpty);
  });

  test('syncLanguage PATCHes the profile when signed in', () async {
    local.signedIn = true;
    final result = await repository.syncLanguage(langCode: 'ar');

    expect(result, const Right<Failure, Unit>(unit));
    expect(remote.synced, ['ar']);
  });

  test('a rejected sync maps to its failure', () async {
    local.signedIn = true;
    remote.error = const UnauthorizedException(
      'Sign in',
      code: 'AUTHENTICATION_REQUIRED',
    );

    expect(
      await repository.syncLanguage(langCode: 'ar'),
      const Left<Failure, Unit>(UnauthorizedFailure('Sign in')),
    );
  });
}
