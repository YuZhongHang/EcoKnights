import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({Key? key}) : super(key: key);

  @override
  _AddDeviceScreenState createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  List<fbp.ScanResult> scannedDevices = [];
  bool scanning = false;

  final String serviceUuid = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  final String dataCharUuid = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";

  @override
  void initState() {
    super.initState();
    scanDevices();
  }

  Future<void> scanDevices() async {
    setState(() {
      scanning = true;
      scannedDevices.clear();
    });

    await fbp.FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    fbp.FlutterBluePlus.scanResults.listen((results) {
      for (var result in results) {
        if (result.device.name.startsWith("EcoKnights_") &&
            !scannedDevices.any((d) => d.device.id == result.device.id)) {
          setState(() {
            scannedDevices.add(result);
          });
        }
      }
    });

    Future.delayed(const Duration(seconds: 5), () {
      fbp.FlutterBluePlus.stopScan();
      setState(() {
        scanning = false;
      });
    });
  }

  Future<void> connectDevice(fbp.ScanResult result) async {
    try {
      await result.device.connect();
      await Future.delayed(const Duration(milliseconds: 500));

      final services = await result.device.discoverServices();
      final service = services.firstWhere(
        (s) => s.uuid.toString().toLowerCase() == serviceUuid.toLowerCase(),
        orElse: () => throw Exception('Service not found'),
      );

      final targetChar = service.characteristics.firstWhere(
        (c) => c.uuid.toString().toLowerCase() == dataCharUuid.toLowerCase(),
        orElse: () => throw Exception('Characteristic not found'),
      );

      // 🔹 Check ownership in Firestore before showing WiFi dialog
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in first!')),
        );
        return;
      }

      final deviceId = result.device.id.id;
      final deviceRef =
          FirebaseFirestore.instance.collection('devices').doc(deviceId);
      final snapshot = await deviceRef.get();

      if (snapshot.exists) {
        final data = snapshot.data()!;
        if (data['ownerUid'] != user.uid) {
          // 🚫 Device owned by someone else
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Device already claimed"),
              content:
                  const Text("This device has been connected by another user!"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
          return; // stop here, don’t open WiFi dialog
        }
      }

      // ✅ Not owned → proceed with WiFi credentials
      await _showWifiDialog(result, targetChar);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect to device')),
      );
    }
  }

  Future<void> _showWifiDialog(
      fbp.ScanResult result, fbp.BluetoothCharacteristic targetChar) async {
    final ssidController = TextEditingController();
    final passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Connect to WiFi'),
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
              Navigator.pop(context); // close dialog

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('WiFi credentials sent! Waiting for response...')),
              );

              // Enable notifications
              await targetChar.setNotifyValue(true);

              targetChar.lastValueStream.listen((value) {
                final response = String.fromCharCodes(value);
                debugPrint("ESP32 replied: $response");

                if (response == "OK") {
                  _claimDevice(result.device);
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

  Future<void> _claimDevice(fbp.BluetoothDevice device) async {
    final user = FirebaseAuth.instance.currentUser;
    debugPrint("Current user: ${user?.uid}");
    if (user == null) return;

    final deviceId = device.id.id; // Use unique Bluetooth ID
    final deviceRef =
        FirebaseFirestore.instance.collection('devices').doc(deviceId);
    final snapshot = await deviceRef.get();

    if (!snapshot.exists) {
      // Claim device for this user
      await deviceRef.set({
        'ownerUid': user.uid,
        'deviceName': device.name,
        'claimedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'device': {
          'deviceId': deviceId,
          'deviceName': device.name,
          'updatedAt': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device successfully claimed!')),
      );

      Navigator.pop(context, true); // Back to HomeScreen
    } else {
      final data = snapshot.data()!;
      if (data['ownerUid'] != user.uid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Device already owned by another user!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You already own this device.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Device"),
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
                      return Card(
                        child: ListTile(
                          title: Text(d.device.name),
                          subtitle: Text(d.device.id.id),
                          trailing: ElevatedButton(
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
