// lib/ui/profile/edit_profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  File? _image;
  bool _isLoading = false;
  bool _isUploadingImage = false;

  String _selectedCountryCode = '+60'; // default MY

  // TODO: Replace with your Cloudinary credentials
  static const String CLOUDINARY_CLOUD_NAME = 'dlonnxqqz';
  static const String CLOUDINARY_UPLOAD_PRESET = 'flutter_profile_pics';
  static const String CLOUDINARY_UPLOAD_URL = 
      'https://api.cloudinary.com/v1_1/$CLOUDINARY_CLOUD_NAME/image/upload';

  static const Map<String, String> _countryCodes = {
    'Malaysia': '+60',
    'Singapore': '+65',
    'United States': '+1',
    'Canada': '+1',
    'United Kingdom': '+44',
    'Australia': '+61',
    'New Zealand': '+64',
    'India': '+91',
    'China': '+86',
    'Hong Kong': '+852',
    'Taiwan': '+886',
    'Japan': '+81',
    'South Korea': '+82',
    'Indonesia': '+62',
    'Thailand': '+66',
    'Philippines': '+63',
    'Vietnam': '+84',
    'Brunei': '+673',
    'Cambodia': '+855',
    'Laos': '+856',
    'Myanmar': '+95',
    'Pakistan': '+92',
    'Bangladesh': '+880',
    'Sri Lanka': '+94',
    'Nepal': '+977',
    'UAE': '+971',
    'Saudi Arabia': '+966',
    'Qatar': '+974',
    'Bahrain': '+973',
    'Kuwait': '+965',
    'Oman': '+968',
    'Turkey': '+90',
    'South Africa': '+27',
    'Nigeria': '+234',
    'Kenya': '+254',
    'Ghana': '+233',
    'France': '+33',
    'Germany': '+49',
    'Italy': '+39',
    'Spain': '+34',
    'Portugal': '+351',
    'Netherlands': '+31',
    'Belgium': '+32',
    'Switzerland': '+41',
    'Sweden': '+46',
    'Norway': '+47',
    'Denmark': '+45',
    'Finland': '+358',
    'Ireland': '+353',
    'Poland': '+48',
    'Czechia': '+420',
    'Austria': '+43',
    'Greece': '+30',
    'Romania': '+40',
    'Hungary': '+36',
    'Russia': '+7',
    'Ukraine': '+380',
    'Mexico': '+52',
    'Brazil': '+55',
    'Argentina': '+54',
    'Chile': '+56',
    'Colombia': '+57',
    'Peru': '+51',
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: FirebaseAuth.instance.currentUser?.displayName ?? '',
    );
    _phoneController = TextEditingController();
    _loadLatestFromFirestore();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadLatestFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!snap.exists) return;
      final data = snap.data();
      if (data == null) return;

      final stored = (data['phoneNumber'] as String?)?.trim() ?? '';
      if (stored.isEmpty) return;

      final cleaned = _cleanPlusDigits(stored);
      final split = _splitByKnownCountryCode(cleaned);

      setState(() {
        if (split != null) {
          _selectedCountryCode = split.$1;
          _phoneController.text = split.$2;
        } else {
          _phoneController.text = cleaned.replaceAll('+', '');
        }
      });
    } catch (_) {
      // ignore errors silently
    }
  }

  String _cleanPlusDigits(String input) {
    final only = input.replaceAll(RegExp(r'[^\d+]'), '');
    return only.startsWith('+') ? only : '+$only';
  }

  (String, String)? _splitByKnownCountryCode(String full) {
    final codes = _countryCodes.values.toSet().toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final code in codes) {
      if (full.startsWith(code)) {
        return (code, full.substring(code.length));
      }
    }
    return null;
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    setState(() => _isUploadingImage = true);
    
    try {
      final request = http.MultipartRequest('POST', Uri.parse(CLOUDINARY_UPLOAD_URL));
      
      request.fields['upload_preset'] = CLOUDINARY_UPLOAD_PRESET;
      request.fields['folder'] = 'profile_images'; // Optional: organize in folders
      
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      
      final response = await request.send();
      
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = json.decode(responseString);
        
        return jsonMap['secure_url']; // This is the image URL
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      print('Cloudinary upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to upload image: $e')),
        );
      }
      return null;
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  void _openCountryPicker() {
    final entries = _countryCodes.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    showModalBottomSheet(
      showDragHandle: true,
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, i) {
                final e = entries[i];
                final selected = e.value == _selectedCountryCode;
                return ListTile(
                  title: Text(e.key),
                  subtitle: Text(e.value),
                  trailing: selected ? const Icon(Icons.check) : null,
                  onTap: () {
                    setState(() => _selectedCountryCode = e.value);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final newName = _nameController.text.trim();
      if (newName.isNotEmpty && newName != (user.displayName ?? '')) {
        await user.updateDisplayName(newName);
      }

      String? imageUrl;
      if (_image != null) {
        imageUrl = await _uploadImageToCloudinary(_image!);
        if (imageUrl != null) {
          await user.updatePhotoURL(imageUrl);
        }
      }

      final local = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
      final fullPhone = '${_selectedCountryCode}$local';

      Map<String, dynamic> userData = {
        'username': newName,
        'phoneNumber': fullPhone,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (imageUrl != null) {
        userData['photoURL'] = imageUrl;
      } else if (user.photoURL != null) {
        userData['photoURL'] = user.photoURL!;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        userData, 
        SetOptions(merge: true)
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Profile updated successfully!')),
        );
        // Clear the selected image after successful upload
        setState(() => _image = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Widget _buildProfileImage(User? user) {
  final double size = 120; // diameter of profile picture

  Widget imageWidget;

  if (_image != null) {
    imageWidget = Image.file(
      _image!,
      width: size,
      height: size,
      fit: BoxFit.cover, // cover fills but keeps aspect ratio
    );
  } else if (user?.photoURL != null && user!.photoURL!.isNotEmpty) {
    imageWidget = Image.network(
      user.photoURL!,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: size,
          height: size,
          color: Colors.grey.shade200,
          child: const Icon(Icons.camera_alt, size: 40, color: Colors.blueGrey),
        );
      },
    );
  } else {
    imageWidget = Container(
      width: size,
      height: size,
      color: Colors.grey.shade200,
      child: const Icon(Icons.camera_alt, size: 40, color: Colors.blueGrey),
    );
  }

  return Stack(
    children: [
      ClipOval(child: imageWidget),
      if (_isUploadingImage)
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        ),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _isUploadingImage ? null : _pickImage,
                    child: Center(child:_buildProfileImage(user)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to change profile picture',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                  initialValue: user?.email ?? '',
                  enabled: false, // make it non-editable
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                    prefixIconConstraints: BoxConstraints(
                      minWidth: 72,
                      minHeight: 48,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                      prefixIconConstraints: BoxConstraints(
                        minWidth: 72,
                        minHeight: 48,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: const OutlineInputBorder(),
                      prefixIcon: InkWell(
                        onTap: _openCountryPicker,
                        child: Container(
                          alignment: Alignment.center,
                          width: 72,
                          child: Text(
                            _selectedCountryCode,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                    ),
                    validator: (value) {
                      final v = (value ?? '').trim();
                      if (v.isEmpty) return 'Enter phone number';
                      if (!RegExp(r'^\d{7,15}$').hasMatch(v)) {
                        return 'Enter 7–15 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: (_isLoading || _isUploadingImage) ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: (_isLoading || _isUploadingImage)
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Profile',
                            style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}