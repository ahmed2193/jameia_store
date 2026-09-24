import '../../../../core/usecase/usecase.dart';
import '../entities/cart_snapshot.dart';
import '../repositories/cart_repository.dart';

/// The cart as it changes: current snapshot first, then every update.
class WatchCartUseCase implements StreamUseCase<CartSnapshot, NoParams> {
  const WatchCartUseCase(this._repository);
  final CartRepository _repository;

  @override
  Stream<CartSnapshot> call(NoParams params) => _repository.watch();
}
