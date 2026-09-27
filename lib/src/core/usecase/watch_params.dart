import 'package:equatable/equatable.dart';

/// Params of a cached read that takes no argument of its own.
/// [forceRefresh] skips the device copy and asks the server (a pull to
/// refresh, a reconnect refresh); otherwise the copy shows first.
class WatchParams extends Equatable {
  const WatchParams({this.forceRefresh = false});

  /// The copy first (when there is one), then the server when it is stale.
  static const WatchParams cached = WatchParams();

  /// The server's, now.
  static const WatchParams fresh = WatchParams(forceRefresh: true);

  final bool forceRefresh;

  @override
  List<Object?> get props => [forceRefresh];
}
