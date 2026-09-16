import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';

/// Language persistence contract. This app is offline, so it is local-only — the
/// `isGuest` + remote-sync branch khayool uses is intentionally omitted. Kept as
/// a repository (not a bare datasource call) so a future server-sync source can
/// slot in behind this contract without touching the cubit.
abstract class LangRepository {
  Future<Either<Failure, String>> getSavedLang();
  Future<Either<Failure, void>> changeLang({required String langCode});
}
