// In lib/ui/profile/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  File? _image;
  bool _isLoading = false; // Add a loading state

  @override
  void initState() {
    super.initState();
    // Initialize controller with current display name
    _nameController = TextEditingController(
        text: FirebaseAuth.instance.currentUser?.displayName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose(); // Dispose controller to prevent memory leaks
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return; // Stop if form is not valid
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Handle case where user is not logged in (though unlikely to reach this screen then)
        _showMessage('Error: User not logged in.');
        return;
      }

      // Update display name
      if (_nameController.text.isNotEmpty &&
          _nameController.text != user.displayName) {
        await user.updateDisplayName(_nameController.text);
        await user.reload();
        final updatedUser = FirebaseAuth.instance.currentUser;
      }

      // Upload new image if selected
      if (_image != null) {
        // Create a reference to the Firebase Storage location
        // Using user.uid ensures each user has their own unique folder for profile pictures
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_profile_images')
            .child('${user.uid}.jpg'); // Or .png, based on your image type

        // Upload the file
        final uploadTask = storageRef.putFile(_image!);

        // Wait for the upload to complete and get the snapshot
        final snapshot = await uploadTask.whenComplete(() {});

        // Get the download URL of the uploaded image
        final downloadUrl = await snapshot.ref.getDownloadURL();

        // Update the user's photoURL in Firebase Authentication
        await user.updatePhotoURL(downloadUrl);
      }

      _showMessage('Profile updated successfully! ✅');
      Navigator.pop(context); // Go back to the previous screen
    } on FirebaseAuthException catch (e) {
      _showMessage('Failed to update profile: ${e.message} 😞');
    } catch (e) {
      _showMessage('An unexpected error occurred: $e 😖');
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  // Helper function to show a SnackBar message
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine the initial image for the CircleAvatar
    ImageProvider profileImage;
    if (_image != null) {
      profileImage = FileImage(_image!);
    } else if (FirebaseAuth.instance.currentUser?.photoURL != null &&
        FirebaseAuth.instance.currentUser!.photoURL!.isNotEmpty) {
      profileImage = NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!);
    } else {
      // Fallback to a default asset image or a placeholder icon
      profileImage = const AssetImage(
          'assets/default_profile.png'); // You'll need to add a default image
      // Or: profileImage = const Icon(Icons.account_circle, size: 100).image as ImageProvider;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Stack(
        // Use Stack to overlay the loading indicator
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius:
                          60, // Slightly larger radius for better visibility
                      backgroundImage: profileImage,
                      backgroundColor:
                          Colors.grey.shade200, // Background for default/empty
                      child: _image == null &&
                              (FirebaseAuth.instance.currentUser?.photoURL ==
                                      null ||
                                  FirebaseAuth
                                      .instance.currentUser!.photoURL!.isEmpty)
                          ? const Icon(Icons.camera_alt,
                              color: Colors.blueGrey,
                              size: 40) // Icon if no image
                          : null, // No child if image is present
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border:
                          OutlineInputBorder(), // Add a border for better aesthetics
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : _saveProfile, // Disable button while loading
                    style: ElevatedButton.styleFrom(
                      minimumSize:
                          const Size(double.infinity, 50), // Full width button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white) // Show spinner
                        : const Text(
                            'Save Profile',
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading) // Overlay a translucent background and spinner when loading
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
