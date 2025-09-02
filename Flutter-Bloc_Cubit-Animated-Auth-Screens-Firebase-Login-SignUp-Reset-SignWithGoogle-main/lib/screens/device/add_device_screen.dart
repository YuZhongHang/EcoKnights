import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddDeviceScreen extends StatefulWidget {
  final String? deviceId;
  final DocumentSnapshot? existingData;

  const AddDeviceScreen({Key? key, this.deviceId, this.existingData})
      : super(key: key);

  @override
  _AddDeviceScreenState createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final wifiController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      wifiController.text = widget.existingData!['wifiName'];
      passwordController.text = widget.existingData!['wifiPassword'];
      nameController.text = widget.existingData!['deviceName'];
    }
  }

  @override
  void dispose() {
    wifiController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> _saveDevice() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final deviceData = {
          'wifiName': wifiController.text,
          'wifiPassword': passwordController.text,
          'deviceName': nameController.text,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        final deviceRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('devices');

        if (widget.deviceId != null) {
          // Update existing device
          await deviceRef.doc(widget.deviceId).update(deviceData);
        } else {
          // Add new device
          await deviceRef.add(deviceData);
        }

        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deviceId != null ? "Edit Device" : "Add Device"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: wifiController,
                decoration: const InputDecoration(labelText: "WiFi Name"),
                validator: (value) => value == null || value.isEmpty
                    ? "WiFi name required"
                    : null,
              ),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: "WiFi Password"),
                obscureText: true,
                validator: (value) =>
                    value == null || value.isEmpty ? "Password required" : null,
              ),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Device Name"),
                validator: (value) => value == null || value.isEmpty
                    ? "Device name required"
                    : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveDevice,
                child: Text(
                    widget.deviceId != null ? "Update Device" : "Add Device"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
