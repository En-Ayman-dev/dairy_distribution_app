import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;
  final InternetConnectionChecker connectionChecker;

  NetworkInfoImpl(this.connectivity, this.connectionChecker);

  @override
  Future<bool> get isConnected async {
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }
    return await connectionChecker.hasConnection;
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return connectivity.onConnectivityChanged.asyncMap((result) async {
      if (result == ConnectivityResult.none) {
        return false;
      }
      return await connectionChecker.hasConnection;
    });
  }
}