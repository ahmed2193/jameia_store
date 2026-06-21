import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Thin connectivity gate. Repositories can check `await networkInfo.isConnected`
/// before a remote call to fail fast with a `NetworkFailure` instead of waiting
/// for a Dio timeout.
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final InternetConnection _connectionChecker;

  NetworkInfoImpl(this._connectionChecker);

  @override
  Future<bool> get isConnected => _connectionChecker.hasInternetAccess;
}
