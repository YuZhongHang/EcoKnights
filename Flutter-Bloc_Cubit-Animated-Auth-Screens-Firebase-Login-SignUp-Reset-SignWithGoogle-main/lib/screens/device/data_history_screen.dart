import 'package:flutter/material.dart';

class DataHistoryScreen extends StatelessWidget {
  final String deviceId;

  DataHistoryScreen({required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Device History")),
      body: Center(
        child: Text("Show history for device: $deviceId"),
      ),
    );
  }
}
