import 'package:auth_bloc/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../../core/widgets/no_internet.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../device/add_device_screen.dart';
import '../../history/history_screen.dart';

/// ----- WELCOME CARD ---------------------------------------------------------
Widget _buildWelcomeSectionWithName(String? username, String? email) {
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
          const Icon(Icons.home, size: 48, color: ColorsManager.lightYellow),
          const SizedBox(height: 16),
          Text('Welcome, ${username ?? 'User'}!',
              style: TextStyles.adminDashboardCardTitle),
          const SizedBox(height: 8),
          Text(
            'Glad to have you back.',
            style: GoogleFonts.nunitoSans(
              fontSize: 16,
              color: ColorsManager.lightYellow,
            ),
          ),
          if (email != null) ...[
            const SizedBox(height: 8),
            Text(
              'Logged in as: $email',
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

/// ----- HOME SCREEN ----------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  fbp.BluetoothDevice? connectedDevice;
  DatabaseReference? deviceDataRef;
  StreamSubscription? _historyMonitor;

  final database = FirebaseDatabase(
    databaseURL:
        "https://my-iot-project-g01-43-default-rtdb.asia-southeast1.firebasedatabase.app/",
  );

  @override
  void initState() {
    super.initState();
    // No auto-recording needed
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _verifyAndMonitorDevice());
  }

  /// Verify device exists and optionally monitor history
  Future<void> _verifyAndMonitorDevice() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final device = userDoc.data()?['device'];

    if (device == null) return;

    final deviceName = device['deviceName'];

    debugPrint("✅ Device found: $deviceName");
    debugPrint("📊 ESP32 records history every 30 seconds automatically");

    // Optional: Monitor history to verify ESP32 is working
    _monitorHistoryUpdates(deviceName);
  }

  /// ✅ Optional: Monitor history entries (for debugging/verification)
  void _monitorHistoryUpdates(String deviceName) {
    final historyRef = FirebaseDatabase.instance
        .ref("devices/$deviceName/readings/history")
        .limitToLast(1);

    _historyMonitor = historyRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map;
        final latest = data.values.first as Map;
        debugPrint("✅ History updated by ESP32: ${latest['timestamp']}");
      }
    });
  }

  @override
  void dispose() {
    _historyMonitor?.cancel();
    super.dispose();
  }

  /// Manual refresh
  void _refreshHomeData() async {
    setState(() {});
    if (deviceDataRef != null) {
      final latest = await deviceDataRef!.get();
      debugPrint('Manual refresh of Realtime DB: ${latest.value}');
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data refreshed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: ColorsManager.greyGreen,
      appBar: AppBar(
        title: Text("Home", style: TextStyles.userHomeScreenTitle),
        backgroundColor: ColorsManager.greyGreen,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh,
                color: ColorsManager.darkBlue, size: 28),
            tooltip: 'Refresh',
            onPressed: _refreshHomeData,
          ),
          IconButton(
            icon: const Icon(Icons.account_circle,
                color: ColorsManager.darkBlue, size: 30),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
        ],
      ),
      body: OfflineBuilder(
        connectivityBuilder: (context, connectivity, child) {
          final bool connected = connectivity != ConnectivityResult.none;
          return connected ? child : const BuildNoInternet();
        },
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: ColorsManager.mainBlue));
              }

              final userData = snapshot.data?.data() as Map<String, dynamic>?;
              final username = userData?['username'] ?? 'User';
              final email = user?.email;
              final device = userData?['device'];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSectionWithName(username, email),
                  SizedBox(height: 20.h),
                  Expanded(child: _buildDeviceSection(device, user)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// DEVICE SECTION
  Widget _buildDeviceSection(dynamic device, User? user) {
    if (device == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.devices, size: 80, color: ColorsManager.darkBlue),
            SizedBox(height: 20.h),
            Text("No device connected",
                style: GoogleFonts.nunitoSans(
                    fontSize: 18.sp, color: ColorsManager.darkBlue)),
            SizedBox(height: 10.h),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, color: ColorsManager.darkBlue),
              label: const Text(
                "Add Device",
                style: TextStyle(
                  color: ColorsManager.darkBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AddDeviceScreen()));
              },
            )
          ],
        ),
      );
    }

    final deviceId = device['deviceId'];
    final deviceName = device['deviceName'];

    deviceDataRef =
        FirebaseDatabase.instance.ref("devices/$deviceName/readings/latest");

    return SingleChildScrollView(
      child: Column(
        children: [
          _deviceInfoCard(deviceName, deviceId, user),
          SizedBox(height: 16.h),
          _sensorDataCard(),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            icon: const Icon(Icons.history, color: ColorsManager.darkBlue),
            label: const Text("View History",
                style: TextStyle(
                    color: ColorsManager.darkBlue,
                    fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.zhYellow),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => HistoryScreen(deviceName: deviceName)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _deviceInfoCard(String name, String id, User? user) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24.w),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [ColorsManager.lightYellow, ColorsManager.grayYellow],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Text(name,
                style: TextStyle(
                    color: ColorsManager.darkBlue,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            Text("ID: $id",
                style: GoogleFonts.nunitoSans(
                    fontSize: 14.sp, color: ColorsManager.gray)),
            SizedBox(height: 14.h),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Text("Connected",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.green)),
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
                      color: ColorsManager.darkBlue),
                ),
              ),
              style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.zhYellow),
              onPressed: () async {
                if (user == null) return;

                // Show confirmation dialog
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Remove Device?'),
                    content: const Text(
                        'Are you sure you want to disconnect and remove this device?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Remove',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('devices')
                        .doc(id)
                        .delete();
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({'device': FieldValue.delete()});

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Device removed successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error removing device: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sensorDataCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24.w),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [ColorsManager.gray93Color, ColorsManager.brightYellow],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<DatabaseEvent>(
          stream: deviceDataRef!.onValue,
          builder: (context, dbSnapshot) {
            if (dbSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child:
                      CircularProgressIndicator(color: ColorsManager.mainBlue));
            }

            if (dbSnapshot.hasError) {
              return Center(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    Text('Error: ${dbSnapshot.error}',
                        style: const TextStyle(color: Colors.red)),
                  ],
                ),
              );
            }

            final value = dbSnapshot.data?.snapshot.value;
            final sensorData = <String, dynamic>{};
            if (value is Map<dynamic, dynamic>) {
              value.forEach((k, v) => sensorData[k.toString()] = v);
            }

            // Handle missing data
            if (sensorData.isEmpty) {
              return Center(
                child: Column(
                  children: [
                    const Icon(Icons.sensors_off, color: Colors.grey, size: 48),
                    const SizedBox(height: 8),
                    Text('Waiting for sensor data...',
                        style: GoogleFonts.nunitoSans(
                          color: Colors.grey,
                          fontSize: 16,
                        )),
                  ],
                ),
              );
            }

            final co2 = sensorData['co2'] ?? 0;
            final temperature = sensorData['temperature'] ?? 0.0;
            final humidity = sensorData['humidity'] ?? 0.0;
            final dust = sensorData['dust'] ?? 0.0;
            final airQuality = sensorData['airQuality'] ?? 'Unknown';
            final timestamp = sensorData['timestamp'] ?? 'No timestamp';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Sensor Readings",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.sp,
                            color: ColorsManager.darkBlue)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getAirQualityColor(airQuality),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        airQuality,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                _buildSensorRow(Icons.cloud_outlined, "CO2", "$co2 ppm"),
                SizedBox(height: 8.h),
                _buildSensorRow(Icons.thermostat_outlined, "Temperature",
                    "${temperature.toStringAsFixed(1)} °C"),
                SizedBox(height: 8.h),
                _buildSensorRow(Icons.water_drop_outlined, "Humidity",
                    "${humidity.toStringAsFixed(1)} %"),
                SizedBox(height: 8.h),
                _buildSensorRow(
                    Icons.grain, "Dust", "${dust.toStringAsFixed(2)} µg/m³"),
                SizedBox(height: 16.h),
                Divider(color: ColorsManager.darkBlue.withOpacity(0.3)),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 16, color: ColorsManager.darkBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text("Last Updated: $timestamp",
                          style: GoogleFonts.nunitoSans(
                              fontSize: 12.sp,
                              color: ColorsManager.darkBlue,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSensorRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: ColorsManager.mainBlue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.nunitoSans(
              color: ColorsManager.darkBlue,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.nunitoSans(
            color: ColorsManager.mainBlue,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Color _getAirQualityColor(String quality) {
    switch (quality.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.deepOrange;
      case 'very poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
