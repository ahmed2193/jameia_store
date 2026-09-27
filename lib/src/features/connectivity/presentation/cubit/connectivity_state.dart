import 'package:equatable/equatable.dart';

import '../../domain/entities/connectivity_status.dart';
import 'connectivity_banner_mode.dart';

/// App-global connection state. [status] is debounced going offline and
/// instant coming back; screens react to [reconnectEpoch] (bumped once per
/// offline → online recovery), never to raw status flips.
class ConnectivityState extends Equatable {
  const ConnectivityState({
    this.status = ConnectivityStatus.unknown,
    this.reconnectEpoch = 0,
    this.isChecking = false,
    this.showBackOnline = false,
    this.lastChangedAt,
  });

  final ConnectivityStatus status;

  /// How many times the connection came back during this run.
  final int reconnectEpoch;

  /// A check the customer (or a submit) asked for is running.
  final bool isChecking;

  /// The short "Back online" confirmation is due.
  final bool showBackOnline;

  /// When [status] last changed.
  final DateTime? lastChangedAt;

  bool get isOffline => status == ConnectivityStatus.offline;

  ConnectivityBannerMode get bannerMode {
    if (isOffline) {
      return isChecking
          ? ConnectivityBannerMode.reconnecting
          : ConnectivityBannerMode.offline;
    }
    return showBackOnline
        ? ConnectivityBannerMode.backOnline
        : ConnectivityBannerMode.hidden;
  }

  ConnectivityState copyWith({
    ConnectivityStatus? status,
    int? reconnectEpoch,
    bool? isChecking,
    bool? showBackOnline,
    DateTime? lastChangedAt,
  }) => ConnectivityState(
    status: status ?? this.status,
    reconnectEpoch: reconnectEpoch ?? this.reconnectEpoch,
    isChecking: isChecking ?? this.isChecking,
    showBackOnline: showBackOnline ?? this.showBackOnline,
    lastChangedAt: lastChangedAt ?? this.lastChangedAt,
  );

  @override
  List<Object?> get props => [
    status,
    reconnectEpoch,
    isChecking,
    showBackOnline,
    lastChangedAt,
  ];
}
