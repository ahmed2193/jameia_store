import 'package:dartz/dartz.dart';
import 'package:jameia_mart/src/core/domain/entities/data_snapshot.dart';
import 'package:jameia_mart/src/core/error/failures.dart';

final DateTime _fetchedAt = DateTime.utc(2026, 9, 27, 12);

/// When a [networkRead]'s network snapshot was fetched.
final DateTime networkSnapshotAt = _fetchedAt;

/// When a [networkRead]'s saved copy was fetched.
final DateTime savedSnapshotAt = _fetchedAt.subtract(const Duration(hours: 3));

/// [read] as a cached read streams it: the [saved] copy first (when given),
/// then one network snapshot, or its failure. The request starts when this
/// is called — a gated fake sees it at once. (An `async*` body:
/// `asyncExpand` never completes under the fake clock of a widget test.)
Stream<DataSnapshot<T>> networkRead<T>(
  Future<Either<Failure, T>> read, {
  T? saved,
}) async* {
  if (saved != null) {
    yield DataSnapshot<T>(
      data: saved,
      fetchedAt: savedSnapshotAt,
      origin: SnapshotOrigin.cache,
    );
  }
  final result = await read;
  yield* result.fold(
    Stream<DataSnapshot<T>>.error,
    (data) => Stream.value(
      DataSnapshot<T>(
        data: data,
        fetchedAt: _fetchedAt,
        origin: SnapshotOrigin.network,
      ),
    ),
  );
}
