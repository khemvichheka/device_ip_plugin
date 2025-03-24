import 'package:flutter/material.dart';

class IpDisplayWidget extends StatelessWidget {
  final String label;
  final Map<String, String> ipData;

  const IpDisplayWidget({Key? key, required this.label, required this.ipData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('IPv4: ${ipData['ipv4']}', style: const TextStyle(fontSize: 18)),
                Text('IPv6: ${ipData['ipv6']}', style: const TextStyle(fontSize: 18)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
