import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../../../services/bluetooth_service.dart';
import 'package:permission_handler/permission_handler.dart';

class AddDeviceScreen extends StatefulWidget {
  final String? deviceId;
  final DocumentSnapshot? existingData;

  const AddDeviceScreen({Key? key, this.deviceId, this.existingData})
      : super(key: key);

  @override
  _AddDeviceScreenState createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  List<fbp.ScanResult> scannedDevices = [];
  fbp.BluetoothDevice? connectedDevice;
  bool scanning = false;

  @override
  void initState() {
    super.initState();
    requestPermissionsAndScan();
  }

  Future<void> requestPermissionsAndScan() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses.values.any((status) => status.isPermanentlyDenied)) {
      openAppSettings();
      return;
    }

    scanDevices();
  }

  void scanDevices() {
    setState(() => scanning = true);
    scannedDevices.clear();
    MyBluetoothService().scanForDevices().listen((results) {
      setState(() {
        scannedDevices = results
            .where((r) => r.device.name.startsWith("EcoKnights_"))
            .toList();
        scanning = false;
      });
    });
  }

  Future<void> connectDevice(fbp.ScanResult result) async {
    try {
      await result.device.connect();
      setState(() => connectedDevice = result.device);

      // Show dialog to input WiFi credentials
      final wifiData = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) {
          final ssidController = TextEditingController();
          final passwordController = TextEditingController();
          return AlertDialog(
            title: const Text("Enter WiFi Credentials"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ssidController,
                  decoration: const InputDecoration(labelText: "SSID"),
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: "Password"),
                  obscureText: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  if (ssidController.text.isNotEmpty &&
                      passwordController.text.isNotEmpty) {
                    Navigator.pop(context, {
                      "ssid": ssidController.text,
                      "password": passwordController.text
                    });
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      );

      if (wifiData != null) {
        saveDevice(result.device, wifiData["ssid"]!, wifiData["password"]!);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to connect: $e")));
    }
  }

  Future<void> saveDevice(
      fbp.BluetoothDevice device, String ssid, String password) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final deviceData = {
      'deviceName': device.name,
      'deviceId': device.id.id,
      'wifiName': ssid,
      'wifiPassword': password,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final deviceRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('devices');

    // Only one device per user: replace previous if exists
    final existing = await deviceRef.limit(1).get();
    if (existing.docs.isNotEmpty) {
      await deviceRef.doc(existing.docs.first.id).set(deviceData);
    } else {
      await deviceRef.add(deviceData);
    }

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Device saved successfully!")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deviceId != null ? "Edit Device" : "Add Device"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: scanDevices,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: scanning
            ? const Center(child: CircularProgressIndicator())
            : scannedDevices.isEmpty
                ? const Center(child: Text("No devices found."))
                : ListView.builder(
                    itemCount: scannedDevices.length,
                    itemBuilder: (context, index) {
                      final d = scannedDevices[index];
                      final isConnected = connectedDevice == d.device;
                      return Card(
                        child: ListTile(
                          title: Text(d.device.name),
                          subtitle: Text(d.device.id.id),
                          trailing: isConnected
                              ? const Text("Connected",
                                  style: TextStyle(color: Colors.green))
                              : ElevatedButton(
                                  child: const Text("Connect"),
                                  onPressed: () => connectDevice(d),
                                ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
