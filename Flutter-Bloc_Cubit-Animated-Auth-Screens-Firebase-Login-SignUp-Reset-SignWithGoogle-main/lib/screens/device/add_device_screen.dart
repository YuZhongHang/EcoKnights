import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final _formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (_) {
        bool _obscurePassword = true;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: ColorsManager.lightYellow,
            title: const Text(
              'Connect to WiFi',
              style: TextStyle(
                fontFamily: 'Georgia',
                color: ColorsManager.darkBlue, 
              ),
            ),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: ssidController,
                    style: const TextStyle( // Text color inside the field (dunno what field)
                      color: ColorsManager.darkBlue,
                    ),
                    decoration: InputDecoration(
                      labelText: 'SSID',
                      labelStyle: GoogleFonts.nunitoSans ( // Label text color
                        color: ColorsManager.gray,
                      ),
                      border: const OutlineInputBorder(),
                      enabledBorder: const OutlineInputBorder( // Border when not focused
                        borderSide: BorderSide(color: ColorsManager.darkBlue, width: 1.5),
                      ),
                      focusedBorder: const OutlineInputBorder( // Border when focused
                        borderSide: BorderSide(color: ColorsManager.gray, width: 2.0),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "SSID can't be empty";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.nunitoSans (
                      color: ColorsManager.darkBlue, // Password text color
                    ),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: GoogleFonts.nunitoSans(
                        color: ColorsManager.gray, // Label color
                      ),
                      border: const OutlineInputBorder(),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: ColorsManager.darkBlue, width: 1.5),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: ColorsManager.gray, width: 2.0),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                              color: ColorsManager.darkBlue
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Password can't be empty";
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  final ssid = ssidController.text.trim();
                  final password = passwordController.text.trim();
                  final creds = "$ssid|$password";

                  await targetChar.write(creds.codeUnits,
                      withoutResponse: false);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'WiFi credentials sent! Waiting for response...')),
                  );

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
                            content:
                                Text('WiFi connection failed! Please retry.')),
                      );
                    }
                  });
                },
                child: const Text('Connect'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _claimDevice(fbp.BluetoothDevice device) async {
    final user = FirebaseAuth.instance.currentUser;
    debugPrint("🔎 Current user: ${user?.uid}");
    if (user == null) return;

    final deviceId = device.id.id;
    debugPrint("📡 Using deviceId: $deviceId");
    debugPrint("📡 Advertised device name: ${device.name}");

    final deviceRef =
        FirebaseFirestore.instance.collection('devices').doc(deviceId);

    final snapshot = await deviceRef.get();
    debugPrint("📦 Firestore snapshot exists? ${snapshot.exists}");

    if (!snapshot.exists) {
      debugPrint("📦 Creating new device document for $deviceId...");
      await deviceRef.set({
        'ownerUid': user.uid,
        'deviceId': deviceId,
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

      debugPrint("✅ Device successfully claimed!");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
          'Device successfully claimed!',
          style: GoogleFonts.nunitoSans(
            color: ColorsManager.darkBlue,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        )),
      );
      Navigator.pop(context, true);
    } else {
      final data = snapshot.data()!;

      if (data['ownerUid'] != user.uid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: ColorsManager.lightYellow,
              content: Text(
                'Device already owned by another user!',
                style: GoogleFonts.nunitoSans(
                  color: ColorsManager.darkBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              )),
        );
      } else {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'device': {
            'deviceId': deviceId,
            'deviceName': device.name,
            'updatedAt': FieldValue.serverTimestamp(),
          }
        }, SetOptions(merge: true));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
            'You already own this device.',
            style: GoogleFonts.nunitoSans(
              color: ColorsManager.darkBlue,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          )),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.greyGreen,
      appBar: AppBar(
        title: Text(
          "Add Device",
          style: TextStyles.addDeviceScreenTitle,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: ColorsManager.darkBlue),
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
