import 'package:equatable/equatable.dart';

/// Where a [DataSnapshot] came from.
enum SnapshotOrigin {
  /// The server answered just now.
  network,

  /// The copy saved on the device the last time the server answered.
  cache,
}

/// A screen's data together with how fresh it is: what a cached read emits,
/// first from the device copy (at once), then from the network.
class DataSnapshot<T> extends Equatable {
  const DataSnapshot({
    required this.data,
    required this.fetchedAt,
    required this.origin,
  });

  final T data;

  /// When the server produced this data (for a cache copy: when it was saved).
  final DateTime fetchedAt;
  final SnapshotOrigin origin;

  bool get isFromCache => origin == SnapshotOrigin.cache;

  /// The same freshness around other data (a page aggregate built from it).
  DataSnapshot<R> map<R>(R Function(T data) convert) => DataSnapshot<R>(
    data: convert(data),
    fetchedAt: fetchedAt,
    origin: origin,
  );

  @override
  List<Object?> get props => [data, fetchedAt, origin];
}
