import 'dart:async';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NetworkType { wifi, mobile }

class DeviceIpPlugin {
// Private Constructor to enforce Singleton
  DeviceIpPlugin._privateConstructor();
  static final DeviceIpPlugin instance = DeviceIpPlugin._privateConstructor();
  // Channel for Native Communication
  static const MethodChannel _channel = MethodChannel('device_ip_plugin');
  static const String _cacheKey = 'ip_address_cache';

  //Stream Controller for Real-time Updates
  final StreamController<Map<String, String>> _ipStreamController = StreamController<Map<String, String>>.broadcast();

  Stream<Map<String, String>> get ipStream => _ipStreamController.stream;

  //Retrieving IP Address with Caching
  Future<Map<String, String>> getIpAddress(NetworkType networkType) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String cacheKey = '$_cacheKey.${networkType.toString().split('.').last}';
    final String? cachedIpv4 = prefs.getString('$cacheKey.ipv4');
    final String? cachedIpv6 = prefs.getString('$cacheKey.ipv6');

    // Validating IP Addresses
    if (_isValidIp(cachedIpv4) && _isValidIp(cachedIpv6)) {
      return {'ipv4': cachedIpv4!, 'ipv6': cachedIpv6!};
    }
    try {
      //Requesting IP from Native Code
      final dynamic ipResult = await _channel.invokeMethod(
        'getIpAddress',
        {'networkType': networkType.toString().split('.').last},
      );

      Map<String, String> ipData = _parseIpResult(ipResult);
      await _cacheIpAddresses(prefs, cacheKey, ipData);
      log("IPData $ipData");

      _ipStreamController.add(ipData);
      log("IPData $ipData");
      return ipData;
    } catch (e) {
      return _handleError(prefs, cacheKey);
    }
  }

  Future<void> _cacheIpAddresses(SharedPreferences prefs, String cacheKey, Map<String, String> ipData) async {
    await prefs.setString('$cacheKey.ipv4', ipData['ipv4']!);
    await prefs.setString('$cacheKey.ipv6', ipData['ipv6']!);
  }

  bool _isValidIp(String? ip) {
    return ip != null && ip != "No internet connection";
  }

  // Parsing the Native Result
  Map<String, String> _parseIpResult(dynamic result) {
    if (result is String) {
      return {'ipv4': result, 'ipv6': result};
    } else if (result is Map<Object?, Object?>) {
      return {
        'ipv4': (result['ipv4'] as String?) ?? 'No internet connection',
        'ipv6': (result['ipv6'] as String?) ?? 'No internet connection'
      };
    }
    return {'ipv4': 'No internet connection', 'ipv6': 'No internet connection'};
  }

  // Handling Errors & Caching 'No Internet' Message
  Map<String, String> _handleError(SharedPreferences prefs, String cacheKey) {
    prefs.setString('$cacheKey.ipv4', "No internet connection");
    prefs.setString('$cacheKey.ipv6', "No internet connection");
    return {'ipv4': "No internet connection", 'ipv6': "No internet connection"};
  }

  Future<String?> getPlatformVersion() async {
    try {
      return await _channel.invokeMethod('getPlatformVersion');
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _ipStreamController.close();
  }
}
