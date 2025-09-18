import 'package:flutter/material.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("Home", style: TextStyles.font24Blue700Weight),
        backgroundColor: Colors.white,
        elevation: 0,
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
              Text(
                "Device",
                style: TextStyles.font24Blue700Weight,
              ),
              SizedBox(height: 20.h),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user?.uid)
                      .collection('devices')
                      .orderBy('updatedAt', descending: true)
                      .limit(1) // Only fetch one device
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

                    final devices = snapshot.data?.docs ?? [];

                    if (devices.isEmpty) {
                      // No device connected
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.devices, size: 80, color: Colors.grey),
                            SizedBox(height: 20.h),
                            Text(
                              "No device connected",
                              style: TextStyle(
                                  fontSize: 18.sp, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10.h),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text("Add Device"),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AddDeviceScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }

                    // Device exists, show dashboard
                    final device = devices.first;
                    final deviceName = device['deviceName'] ?? 'Unknown';
                    final deviceId = device.id;

                    return Center(
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r)),
                        elevation: 4,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(24.w),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                deviceName,
                                style: TextStyle(
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                "ID: $deviceId",
                                style: TextStyle(
                                    fontSize: 16.sp, color: Colors.grey[600]),
                              ),
                              SizedBox(height: 16.h),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.circle,
                                      color: Colors.green, size: 16),
                                  SizedBox(width: 8.w),
                                  const Text(
                                    "Connected",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20.h),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.power_settings_new),
                                label: const Text("Disconnect / Remove"),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user?.uid)
                                      .collection('devices')
                                      .doc(deviceId)
                                      .delete();
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
}
