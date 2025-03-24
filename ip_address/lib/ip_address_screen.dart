import 'package:device_ip_plugin/device_ip_plugin.dart';
import 'package:device_ip_plugin_example/ip_widget.dart';
import 'package:flutter/material.dart';

class DeviceIpAddressScreen extends StatefulWidget {
  const DeviceIpAddressScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _DeviceIpAddressScreenState createState() => _DeviceIpAddressScreenState();
}

class _DeviceIpAddressScreenState extends State<DeviceIpAddressScreen> {
  Map<String, String> _wifiIp = {'ipv4': 'fetching...', 'ipv6': 'fetching...'};
  Map<String, String> _mobileIp = {'ipv4': 'fetching...', 'ipv6': 'fetching...'};
  NetworkType _selectedNetworkType = NetworkType.wifi;
  bool _isLoading = false;
  final plugin = DeviceIpPlugin.instance;

  @override
  void initState() {
    super.initState();
    _fetchIp();
  }

  Future<void> _fetchIp() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    try {
      final ipAddresses = await plugin.getIpAddress(_selectedNetworkType);
      setState(() {
        if (_selectedNetworkType == NetworkType.wifi) {
          _wifiIp = ipAddresses;
          _mobileIp = {'ipv4': 'fetching...', 'ipv6': 'fetching...'};
        } else {
          _mobileIp = ipAddresses;
          _wifiIp = {'ipv4': 'fetching...', 'ipv6': 'fetching...'};
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        if (_selectedNetworkType == NetworkType.wifi) {
          _wifiIp = {'ipv4': 'Error: ${e.toString()}', 'ipv6': 'Error: ${e.toString()}'};
        } else {
          _mobileIp = {'ipv4': 'Error: ${e.toString()}', 'ipv6': 'Error: ${e.toString()}'};
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Device IP Plugin'),
          centerTitle: true,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Align(
              alignment: Alignment.center,
              child: DropdownButton<NetworkType>(
                value: _selectedNetworkType,
                onChanged: (NetworkType? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedNetworkType = newValue;
                      _fetchIp();
                    });
                  }
                },
                items: <NetworkType>[NetworkType.wifi, NetworkType.mobile]
                    .map<DropdownMenuItem<NetworkType>>((NetworkType value) {
                  return DropdownMenuItem<NetworkType>(
                    value: value,
                    child: Text(value == NetworkType.wifi ? 'Wi-Fi' : 'Mobile Data'),
                  );
                }).toList(),
              ),
            ),
            const Spacer(flex: 1),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _isLoading
                        ? const CircularProgressIndicator()
                        : Column(
                            children: [
                              IpDisplayWidget(label: 'Wi-Fi', ipData: _wifiIp),
                              IpDisplayWidget(label: 'Mobile', ipData: _mobileIp),
                            ],
                          ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _fetchIp,
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
