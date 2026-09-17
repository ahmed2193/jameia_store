import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../error/failures.dart';

/// Base contract every async use case implements.
///
/// A use case is a single, named business action. The cubit calls it; the use
/// case calls the repository. It returns `Either<Failure, T>` so the caller
/// must handle the failure branch explicitly (no thrown exceptions cross this
/// boundary).
///
/// ```dart
/// class GetX implements UseCase<Result, Params> { ... }
/// final either = await getX(params);
/// either.fold((failure) => emit(Error), (data) => emit(Loaded));
/// ```
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Synchronous use case — for interactive actions a tap must resolve in the
/// same frame (e.g. re-deriving a filtered view from already-loaded data).
abstract class SyncUseCase<T, Params> {
  Either<Failure, T> call(Params params);
}

/// Use case exposing a continuous value stream (e.g. a store-mode toggle).
abstract class StreamUseCase<T, Params> {
  Stream<T> call(Params params);
}

/// Use this as `Params` for use cases that take no arguments.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
