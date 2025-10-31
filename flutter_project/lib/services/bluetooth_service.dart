import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

class MyBluetoothService {
  /// Scan for devices for 15 seconds
  Stream<List<fbp.ScanResult>> scanForDevices() {
    fbp.FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    return fbp
        .FlutterBluePlus
        .scanResults; // Already returns Stream<List<ScanResult>>
  }

  /// Stop scanning
  void stopScan() {
    fbp.FlutterBluePlus.stopScan();
  }

  /// Connect to a device
  Future<fbp.BluetoothDevice> connectToDevice(fbp.ScanResult result) async {
    final device = result.device;
    await device.connect();
    return device;
  }

  /// Send WiFi credentials
  Future<void> sendWifiCredentials(
    fbp.BluetoothDevice device,
    String ssid,
    String password,
  ) async {
    var services = await device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.write) {
          final wifiData = "$ssid|$password";
          await characteristic.write(wifiData.codeUnits, withoutResponse: true);
          return;
        }
      }
    }
    throw Exception("No writable characteristic found!");
  }
}
