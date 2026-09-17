import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';

/// Language persistence + account sync contract.
///
/// [changeLang] is local and fast (the UI awaits it before flipping the
/// locale); [syncLanguage] is the separate, best-effort network step that
/// writes the choice to the customer profile when signed in.
abstract class LangRepository {
  /// The saved code, or `''` when the user never chose one.
  Future<Either<Failure, String>> getSavedLang();

  Future<Either<Failure, Unit>> changeLang({required String langCode});

  /// `PATCH /v1/account/profile { language }` — a no-op success while signed
  /// out.
  Future<Either<Failure, Unit>> syncLanguage({required String langCode});
}
