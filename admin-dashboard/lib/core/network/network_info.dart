import 'package:flutter/foundation.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl();

  @override
  Future<bool> get isConnected async {
    // For web, we assume connection is always available
    // For mobile apps, you could add proper network checking here
    if (kIsWeb) {
      return true;
    }

    // For non-web platforms, you could implement proper network checking
    // For now, we'll assume connection is available
    return true;
  }
}
