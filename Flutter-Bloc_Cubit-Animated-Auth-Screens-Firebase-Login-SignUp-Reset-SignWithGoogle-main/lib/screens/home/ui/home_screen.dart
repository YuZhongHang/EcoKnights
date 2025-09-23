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
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';

Widget _buildWelcomeSection(User? user) {
  return Card(
    elevation: 4,
    child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ColorsManager.gray, ColorsManager.mainBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.home, // Changed from admin icon
            size: 48,
            color: ColorsManager.lightYellow,
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome, ${user?.displayName ?? 'User'}!', // Changed text
            style: TextStyles.adminDashboardCardTitle,
          ),
          const SizedBox(height: 8),
          Text(
            'Glad to have you back.',
            style: GoogleFonts.nunitoSans(
              fontSize: 16,
              color: ColorsManager.lightYellow,
            ),
          ),
          if (user?.email != null) ...[
            const SizedBox(height: 8),
            Text(
              'Logged in as: ${user!.email}', // 👈 Still useful
              style: GoogleFonts.nunitoSans(
                fontSize: 14,
                color: ColorsManager.darkBlue,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

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
      backgroundColor: ColorsManager.greyGreen,
      appBar: AppBar(
        title: Text(
          "Home",
          style: TextStyles.userHomeScreenTitle,
        ),
        backgroundColor: ColorsManager.greyGreen,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle,
                color: ColorsManager.darkBlue, size: 30),
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
              _buildWelcomeSection(user),
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
                            Icon(Icons.devices,
                                size: 80, color: ColorsManager.darkBlue),
                            SizedBox(height: 20.h),
                            Text("No device connected",
                                style: GoogleFonts.nunitoSans(
                                    fontSize: 18.sp,
                                    color: ColorsManager.darkBlue)),
                            SizedBox(height: 10.h),
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    ColorsManager.gray,
                                    ColorsManager.mainBlue,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.add,
                                    color: ColorsManager
                                        .darkBlue), // Change icon color
                                label: const Text(
                                  "Add Device",
                                  style: TextStyle(
                                    color: ColorsManager.darkBlue, // Text color
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AddDeviceScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors
                                      .transparent, // Make button transparent
                                  shadowColor:
                                      Colors.transparent, // Remove shadow
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 24),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      );
                    }

                    final deviceId = device['deviceId'];
                    final deviceName = device['deviceName'];

                    return Center(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 4,
                          clipBehavior: Clip
                              .antiAlias, // Important: clips child to the card's border
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(24.w),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  ColorsManager.lightYellow,
                                  ColorsManager.grayYellow,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(deviceName,
                                    style: TextStyle(
                                        color: ColorsManager.darkBlue,
                                        fontFamily: 'Georgia',
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 8.h),
                                Text("ID: $deviceId",
                                    style: GoogleFonts.nunitoSans(
                                        fontSize: 14.sp,
                                        color: ColorsManager.gray)),
                                SizedBox(height: 14.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.circle,
                                        color: Colors.green, size: 16),
                                    SizedBox(width: 8.w),
                                    const Text("Connected",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green)),
                                  ],
                                ),
                                SizedBox(height: 20.h),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.power_settings_new,
                                      color: ColorsManager.darkBlue),
                                  label: Text(
                                    "Disconnect / Remove",
                                    style: GoogleFonts.nunitoSans(
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: ColorsManager
                                            .darkBlue, // Wrap inside TextStyle
                                      ),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: ColorsManager.zhYellow),
                                  onPressed: () async {
                                    final uid = user!.uid;
                                    await FirebaseFirestore.instance
                                        .collection('devices')
                                        .doc(deviceId)
                                        .delete();
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(uid)
                                        .update(
                                            {'device': FieldValue.delete()});
                                  },
                                ),
                              ],
                            ),
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
