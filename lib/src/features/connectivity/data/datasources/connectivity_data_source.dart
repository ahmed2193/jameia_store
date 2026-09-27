import '../../../../core/network/network_info.dart';

/// The device's reachability monitor ([NetworkInfo]) as primitives: `true`
/// = the backend answers.
abstract class ConnectivityDataSource {
  /// The last known value first (when there is one), then every change.
  Stream<bool> watchReachability();

  Future<bool> checkNow();

  void setMonitoring({required bool active});
}

class ConnectivityDataSourceImpl implements ConnectivityDataSource {
  const ConnectivityDataSourceImpl(this._networkInfo);

  final NetworkInfo _networkInfo;

  @override
  Stream<bool> watchReachability() => Stream<bool>.multi((controller) {
    // A response may have settled the status before anyone listened; the
    // monitor only reports changes, so start from what it knows.
    final known = _networkInfo.isReachable;
    if (known != null) controller.add(known);
    final subscription = _networkInfo.onReachabilityChanged.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<bool> checkNow() => _networkInfo.checkNow();

  @override
  void setMonitoring({required bool active}) =>
      active ? _networkInfo.resume() : _networkInfo.pause();
}
