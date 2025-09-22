import 'package:auth_bloc/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

import '../../../core/widgets/no_internet.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../device/add_device_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  fbp.BluetoothDevice? connectedDevice;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("Home", style: TextStyles.font24Blue700Weight),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon:
                const Icon(Icons.account_circle, color: ColorsManager.mainBlue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: OfflineBuilder(
        connectivityBuilder: (BuildContext context,
            ConnectivityResult connectivity, Widget child) {
          final bool connected = connectivity != ConnectivityResult.none;
          return connected ? child : const BuildNoInternet();
        },
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Device", style: TextStyles.font24Blue700Weight),
              SizedBox(height: 20.h),
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: ColorsManager.mainBlue),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }

                    final userData =
                        snapshot.data?.data() as Map<String, dynamic>?;
                    final device = userData?['device'];

                    if (device == null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.devices, size: 80, color: Colors.grey),
                            SizedBox(height: 20.h),
                            Text("No device connected",
                                style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(height: 10.h),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text("Add Device"),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const AddDeviceScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }

                    final deviceId = device['deviceId'];
                    final deviceName = device['deviceName'];

                    return Center(
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: 4,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(24.w),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(deviceName,
                                  style: TextStyle(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 8.h),
                              Text("ID: $deviceId",
                                  style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.grey[600])),
                              SizedBox(height: 16.h),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.wifi),
                                label: const Text(
                                  "Reconnect",
                                  style: TextStyle(fontSize: 14),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: () async {
                                  await _reconnectAndShowWifiDialog(
                                      deviceId, deviceName);
                                },
                              ),
                              SizedBox(height: 12.h),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.power_settings_new),
                                label: const Text(
                                  "Disconnect / Remove",
                                  style: TextStyle(fontSize: 14),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () async {
                                  final uid = user!.uid;
                                  await FirebaseFirestore.instance
                                      .collection('devices')
                                      .doc(deviceId)
                                      .delete();
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(uid)
                                      .update({'device': FieldValue.delete()});
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reconnectAndShowWifiDialog(
      String deviceId, String deviceName) async {
    try {
      // Scan to find the BLE device first
      await fbp.FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

      fbp.ScanResult? scanResult;
      final results = await fbp.FlutterBluePlus.scanResults.first;
      for (var r in results) {
        if (r.device.id.id == deviceId) {
          scanResult = r;
          break;
        }
      }

      await fbp.FlutterBluePlus.stopScan();

      if (scanResult == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device not found during reconnect.')),
        );
        return;
      }

      connectedDevice = scanResult.device;
      await connectedDevice!.connect(autoConnect: false);
      final services = await connectedDevice!.discoverServices();

      final targetService = services.firstWhere(
          (s) =>
              s.uuid.toString().toLowerCase() ==
              "6e400001-b5a3-f393-e0a9-e50e24dcca9e",
          orElse: () => throw Exception('Service not found'));

      final targetChar = targetService.characteristics.firstWhere(
          (c) =>
              c.uuid.toString().toLowerCase() ==
              "6e400002-b5a3-f393-e0a9-e50e24dcca9e",
          orElse: () => throw Exception('Characteristic not found'));

      // Show WiFi dialog
      await _showWifiDialog(targetChar, deviceName);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reconnect: $e')),
      );
    }
  }

  Future<void> _showWifiDialog(
      fbp.BluetoothCharacteristic targetChar, String deviceName) async {
    final ssidController = TextEditingController();
    final passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Reconnect WiFi - $deviceName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ssidController,
              decoration: const InputDecoration(labelText: 'SSID'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final ssid = ssidController.text.trim();
              final password = passwordController.text.trim();
              if (ssid.isEmpty || password.isEmpty) return;

              final creds = "$ssid|$password";
              await targetChar.write(creds.codeUnits, withoutResponse: false);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('WiFi credentials sent! Waiting for response...'),
                ),
              );

              await targetChar.setNotifyValue(true);
              targetChar.lastValueStream.listen((value) {
                final response = String.fromCharCodes(value);
                debugPrint("ESP32 replied: $response");

                if (response == "OK") {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('WiFi connected successfully!')),
                  );
                } else if (response == "FAIL") {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('WiFi connection failed! Please retry.')),
                  );
                }
              });
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}
