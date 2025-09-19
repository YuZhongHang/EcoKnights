import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

class AddDeviceScreen extends StatefulWidget {
  final String? deviceId;

  const AddDeviceScreen({Key? key, this.deviceId}) : super(key: key);

  @override
  _AddDeviceScreenState createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  List<fbp.ScanResult> scannedDevices = [];
  fbp.BluetoothDevice? connectedDevice;
  bool scanning = false;

  final String serviceUuid = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  final String dataCharUuid = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";

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
      await Future.delayed(const Duration(seconds: 1));

      // ✅ Discover all services ONCE
      final services = await result.device.discoverServices();

      // ✅ Find the service we care about
      final service = services.firstWhere(
        (s) => s.uuid.toString().toLowerCase() == serviceUuid.toLowerCase(),
        orElse: () => throw Exception("Service not found"),
      );

      // ✅ Find the characteristic inside that service
      final targetChar = service.characteristics.firstWhere(
        (c) => c.uuid.toString().toLowerCase() == dataCharUuid.toLowerCase(),
        orElse: () => throw Exception("Characteristic not found"),
      );

      debugPrint("✅ Using hardcoded characteristic: ${targetChar.uuid}");

      // WiFi Dialog
      showDialog(
        context: context,
        builder: (context) {
          final ssidController = TextEditingController();
          final passwordController = TextEditingController();

          return AlertDialog(
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

                  if (ssid.isNotEmpty && password.isNotEmpty) {
                    // Enable notifications
                    await targetChar.setNotifyValue(true);
                    targetChar.lastValueStream.listen((value) {
                      final response = String.fromCharCodes(value);
                      debugPrint("ESP32 replied: $response");

                      if (response == "OK") {
                        Navigator.pop(context);
                        setState(() {
                          connectedDevice = result.device;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('WiFi connected successfully!')),
                        );
                      } else if (response == "FAIL") {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('WiFi connection failed!')),
                        );
                      }
                    });

                    // Send WiFi credentials
                    final creds = "$ssid|$password";
                    await targetChar.write(creds.codeUnits,
                        withoutResponse: false);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Sending WiFi credentials...')),
                    );
                  }
                },
                child: const Text('Connect'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('Error connecting to device: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect to device')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    scanDevices();
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
