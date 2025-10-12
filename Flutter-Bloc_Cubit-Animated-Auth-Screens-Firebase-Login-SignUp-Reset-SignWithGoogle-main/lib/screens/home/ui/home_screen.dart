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
  Timer? _historyTimer;

  final database = FirebaseDatabase(
    databaseURL:
        "https://my-iot-project-g01-43-default-rtdb.asia-southeast1.firebasedatabase.app/",
  );

  @override
  void initState() {
    super.initState();

    // Wait for build complete to start recording safely
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAutoRecording());
  }

  /// Initializes auto-recording after verifying device
  Future<void> _initAutoRecording() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final device = userDoc.data()?['device'];

    if (device == null) return;

    final deviceName = device['deviceName'];
    _startAutoRecording(deviceName);
  }

  /// Auto record readings to history (every 1 minute)
  void _startAutoRecording(String deviceName) {
    // Cancel any existing timer before starting a new one
    _historyTimer?.cancel();

    final deviceDataRef =
        FirebaseDatabase.instance.ref("devices/$deviceName/readings/latest");
    final historyRef =
        FirebaseDatabase.instance.ref("devices/$deviceName/readings/history");

    _historyTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      final latestSnapshot = await deviceDataRef.get();
      final value = latestSnapshot.value;

      if (value is Map) {
        final now = DateTime.now();
        final date =
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
        final time =
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

        await historyRef.push().set({
          ...value,
          'date': date,
          'time': time,
        });

        debugPrint("✅ Recorded reading for $deviceName at $date $time");
      }
    });

    debugPrint("⏱️ Started auto recording for $deviceName (every 1 min)");
  }

  @override
  void dispose() {
    _historyTimer?.cancel();
    super.dispose();
  }

  /// Manual refresh
  void _refreshHomeData() async {
    setState(() {});
    if (deviceDataRef != null) {
      final latest = await deviceDataRef!.get();
      debugPrint('Manual refresh of Realtime DB: ${latest.value}');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data refreshed')),
    );
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
            style:
                ElevatedButton.styleFrom(backgroundColor: ColorsManager.zhYellow),
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
              style:
                  ElevatedButton.styleFrom(backgroundColor: ColorsManager.zhYellow),
              onPressed: () async {
                if (user == null) return;
                await FirebaseFirestore.instance
                    .collection('devices')
                    .doc(id)
                    .delete();
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({'device': FieldValue.delete()});
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
                  child: CircularProgressIndicator(
                      color: ColorsManager.mainBlue));
            }

            final value = dbSnapshot.data?.snapshot.value;
            final sensorData = <String, dynamic>{};
            if (value is Map<dynamic, dynamic>) {
              value.forEach((k, v) => sensorData[k.toString()] = v);
            }

            final co2 = sensorData['co2'] ?? 0;
            final temperature = sensorData['temperature'] ?? 0.0;
            final humidity = sensorData['humidity'] ?? 0.0;
            final dust = sensorData['dust'] ?? 0.0;
            final airQuality = sensorData['airQuality'] ?? 'Unknown';
            final timestamp = sensorData['timestamp'] ?? '';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Sensor Readings",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                        color: ColorsManager.darkBlue)),
                SizedBox(height: 8.h),
                Text("CO2: $co2 ppm",
                    style:
                        GoogleFonts.nunitoSans(color: ColorsManager.mainBlue)),
                Text("Temperature: $temperature °C",
                    style:
                        GoogleFonts.nunitoSans(color: ColorsManager.mainBlue)),
                Text("Humidity: $humidity %",
                    style:
                        GoogleFonts.nunitoSans(color: ColorsManager.mainBlue)),
                Text("Dust: $dust mg/m³",
                    style:
                        GoogleFonts.nunitoSans(color: ColorsManager.mainBlue)),
                Text("Air Quality: $airQuality",
                    style:
                        GoogleFonts.nunitoSans(color: ColorsManager.mainBlue)),
                SizedBox(height: 8.h),
                Text("Last Updated: $timestamp",
                    style: GoogleFonts.nunitoSans(
                        fontSize: 12.sp, color: ColorsManager.darkBlue)),
              ],
            );
          },
        ),
      ),
    );
  }
}
