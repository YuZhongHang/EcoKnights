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
        connectivityBuilder:
            (
              BuildContext context,
              ConnectivityResult connectivity,
              Widget child,
            ) {
              final bool connected = connectivity != ConnectivityResult.none;
              return connected
                  ? _homePage(context, user)
                  : const BuildNoInternet();
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
                            .whereType<fbp.ScanResult>() // ✅ Ensure type safety
                            .where(
                              (d) => d.device.name.startsWith("EcoDevice_"),
                            )
                            .toList();

                        if (devices.isEmpty) {
                          return const Center(
                            child: Text("No ESP32 devices found"),
                          );
                        }

                        return ListView.builder(
                          itemCount: devices.length,
                          itemBuilder: (context, index) {
                            final result = devices[index];
                            return Card(
                              child: ListTile(
                                title: Text(result.device.name),
                                subtitle: Text(result.device.id.id),
                                trailing: ElevatedButton(
                                  child: const Text("Send WiFi"),
                                  onPressed: () async {
                                    // Example WiFi creds (later: use a dialog to enter)
                                    String ssid = "MyHomeWiFi";
                                    String password = "MySecret123";

                                    final device = await MyBluetoothService()
                                        .connectToDevice(result);
                                    await MyBluetoothService()
                                        .sendWifiCredentials(
                                          device,
                                          ssid,
                                          password,
                                        );

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("WiFi sent to ESP32"),
                                      ),
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
