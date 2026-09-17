import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// Stream of "the session could not be refreshed" events, so the app-global
/// session cubit can sign the user out and route to login.
class WatchSessionExpiryUseCase implements StreamUseCase<void, NoParams> {
  const WatchSessionExpiryUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Stream<void> call(NoParams params) => _repository.watchSessionExpiry();
}
