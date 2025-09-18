import 'package:auth_bloc/screens/device/add_device_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '/helpers/extensions.dart';
import '/routing/routes.dart';
import '/theming/styles.dart';
import '../../../core/widgets/no_internet.dart';
import '../../../core/widgets/progress_indicaror.dart';
import '../../../logic/cubit/auth_cubit.dart';
import '../../../theming/colors.dart';

import '../../device/add_device_screen.dart';
import '../../device/data_history_screen.dart';

import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../../../services/bluetooth_service.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    var scan = await Permission.bluetoothScan.status;
    var connect = await Permission.bluetoothConnect.status;
    var location = await Permission.location.status;
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    statuses.forEach((perm, status) {
      if (status.isPermanentlyDenied) {
        // Open settings if user blocked it forever
        openAppSettings();
      }
    });
  }

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
            icon: const Icon(
              Icons.account_circle,
              color: ColorsManager.mainBlue,
              size: 28,
            ),
            onPressed: () {
              context.pushNamed(Routes.profileScreen);
            },
          ),
        ],
      ),
      body: OfflineBuilder(
        connectivityBuilder: (
          BuildContext context,
          ConnectivityResult connectivity,
          Widget child,
        ) {
          final bool connected = connectivity != ConnectivityResult.none;
          return connected ? _homePage(context, user) : const BuildNoInternet();
        },
        child: const Center(
          child: CircularProgressIndicator(color: ColorsManager.mainBlue),
        ),
      ),
    );
  }

  SafeArea _homePage(BuildContext context, User? user) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        child: Column(
          children: [
            SizedBox(height: 20.h),

            // ✅ Firestore stream to watch devices
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user?.uid)
                    .collection('devices')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: ColorsManager.mainBlue,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return StreamBuilder<List<fbp.ScanResult>>(
                      stream: MyBluetoothService().scanForDevices(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final devices = snapshot.data!
                            .whereType<fbp.ScanResult>()
                            .where((d) =>
                                d.device.platformName.startsWith("EcoKnights_"))
                            .toList();

                        if (devices.isEmpty) {
                          return const Center(
                            child: Text("No ESP32 devices found"),
                          );
                        }

                        for (var d in snapshot.data!) {
                          debugPrint(
                              "📡 Found: '${d.device.name}' (${d.device.id.id})");
                        }

                        return ListView.builder(
                          itemCount: devices.length,
                          itemBuilder: (context, index) {
                            final result = devices[index];
                            return Card(
                              child: ListTile(
                                title: Text(result.device.name),
                                subtitle: Text(result.device.id.id),
                                trailing: IconButton(
                                  icon: const Icon(Icons.wifi,
                                      color: ColorsManager.mainBlue),
                                  onPressed: () async {
                                    await result.device.connect();

                                    final ssidController =
                                        TextEditingController();
                                    final passwordController =
                                        TextEditingController();

                                    await showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text(
                                              "Enter WiFi Credentials"),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextField(
                                                controller: ssidController,
                                                decoration:
                                                    const InputDecoration(
                                                        labelText: "SSID"),
                                              ),
                                              TextField(
                                                controller: passwordController,
                                                decoration:
                                                    const InputDecoration(
                                                        labelText: "Password"),
                                                obscureText: true,
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              child: const Text("Cancel"),
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                            ),
                                            ElevatedButton(
                                              child: const Text("Send"),
                                              onPressed: () async {
                                                final ssid =
                                                    ssidController.text.trim();
                                                final password =
                                                    passwordController.text
                                                        .trim();

                                                if (ssid.isNotEmpty &&
                                                    password.isNotEmpty) {
                                                  final device =
                                                      await MyBluetoothService()
                                                          .connectToDevice(
                                                              result);
                                                  await MyBluetoothService()
                                                      .sendWifiCredentials(
                                                    device,
                                                    ssid,
                                                    password,
                                                  );

                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content: Text(
                                                            "WiFi sent: $ssid")),
                                                  );
                                                  Navigator.pop(context);
                                                }
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }

                  // Show devices if found
                  final devices = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      final deviceId = device.id;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        child: ListTile(
                          title: Text(device['deviceName']),
                          subtitle: Text("WiFi: ${device['wifiName']}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: ColorsManager.mainBlue,
                                ),
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddDeviceScreen(
                                        deviceId: deviceId,
                                        existingData: device,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.history,
                                  color: ColorsManager.mainBlue,
                                ),
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DataHistoryScreen(deviceId: deviceId),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // 👇 Existing Auth State listener
            BlocConsumer<AuthCubit, AuthState>(
              buildWhen: (previous, current) => previous != current,
              listenWhen: (previous, current) => previous != current,
              listener: (context, state) async {
                if (state is AuthLoading) {
                  ProgressIndicaror.showProgressIndicator(context);
                } else if (state is UserSignedOut) {
                  context.pushNamedAndRemoveUntil(
                    Routes.loginScreen,
                    predicate: (route) => false,
                  );
                } else if (state is AuthError) {
                  await AwesomeDialog(
                    context: context,
                    dialogType: DialogType.info,
                    animType: AnimType.rightSlide,
                    title: 'Sign out error',
                    desc: state.message,
                  ).show();
                }
              },
              builder: (context, state) {
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
