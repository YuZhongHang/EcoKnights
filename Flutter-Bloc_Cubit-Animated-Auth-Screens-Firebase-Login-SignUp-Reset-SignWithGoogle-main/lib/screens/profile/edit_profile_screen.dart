// lib/ui/profile/edit_profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

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

  /// Selected country calling code (always includes '+')
  String _selectedCountryCode = '+60'; // default MY

  /// A reasonably wide list of country codes. Add more if you need.
  /// (Kept compact to avoid an enormous file.)
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

      // Clean: keep '+' and digits only (strip spaces, dashes, etc.)
      final cleaned = _cleanPlusDigits(stored);

      // If it starts with '+', try to split into country code + local part using our known codes
      if (cleaned.startsWith('+')) {
        final split = _splitByKnownCountryCode(cleaned);
        if (split != null) {
          setState(() {
            _selectedCountryCode = split.$1; // country code
            _phoneController.text = split.$2; // local number
          });
          return;
        }
      }

      // Otherwise, fall back: keep the default country code, show digits as local number
      setState(() {
        _phoneController.text = cleaned.replaceAll('+', '');
      });
    } catch (_) {
      // Silent fail; keep defaults
    }
  }

  /// Returns string with only '+' and digits kept.
  String _cleanPlusDigits(String input) {
    final only = input.replaceAll(RegExp(r'[^\d+]'), '');
    // Normalize multiple '+' just in case
    final normalized = only.replaceFirst(RegExp(r'^\+*'), '+');
    return normalized.startsWith('+')
        ? '+${normalized.substring(1)}'
        : normalized;
  }

  /// Try to split "+<cc><local>" using our known country codes.
  /// Chooses the longest matching code.
  /// Returns (countryCode, localPart) or null if no match.
  (String, String)? _splitByKnownCountryCode(String withPlus) {
    // Sort codes by length desc to prefer the longest match (e.g., +852 over +85)
    final codes = _countryCodes.values.toSet().toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final code in codes) {
      if (withPlus.startsWith(code)) {
        final local = withPlus.substring(code.length);
        return (code, local);
      }
    }
    return null;
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text('Select Country/Region',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Expanded(
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
            ],
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
      if (user == null) throw Exception('User not logged in');

      // Update display name in Auth
      final newName = _nameController.text.trim();
      if (newName.isNotEmpty && newName != (user.displayName ?? '')) {
        await user.updateDisplayName(newName);
      }

      // Upload profile image if chosen
      if (_image != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('user_profile_images')
            .child('${user.uid}.jpg');
        final snap = await ref.putFile(_image!).whenComplete(() {});
        final url = await snap.ref.getDownloadURL();
        await user.updatePhotoURL(url);
      }

      await user.reload();

      // Build and normalize the full phone number
      final localDigits =
          _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
      final fullPhone = '${_selectedCountryCode}$localDigits';

      // Save to Firestore (merge)
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': newName,
        'phoneNumber': fullPhone,
        'photoURL': user.photoURL ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also reflect immediately in UI (ensures latest shows)
      setState(() {
        _phoneController.text = localDigits;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully! ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    ImageProvider profileImage;
    if (_image != null) {
      profileImage = FileImage(_image!);
    } else if (user?.photoURL != null && user!.photoURL!.isNotEmpty) {
      profileImage = NetworkImage(user.photoURL!);
    } else {
      profileImage = const AssetImage('assets/default_profile.png');
    }

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
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: profileImage,
                      backgroundColor: Colors.grey.shade200,
                      child: _image == null &&
                              (user?.photoURL == null ||
                                  (user!.photoURL ?? '').isEmpty)
                          ? const Icon(Icons.camera_alt,
                              color: Colors.blueGrey, size: 40)
                          : null,
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
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 72, // width of the icon container
                        minHeight: 48,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter your name'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  /// SINGLE field with tappable prefix -> both move together on error
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: const OutlineInputBorder(),
                      // Tappable prefix that opens the country picker
                      prefixIcon: InkWell(
                        onTap: _openCountryPicker,
                        child: Container(
                          alignment: Alignment.center,
                          width: 72,
                          child: Text(
                            _selectedCountryCode,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    validator: (value) {
                      final v = (value ?? '').trim();
                      if (v.isEmpty) return 'Enter phone number';
                      // digits-only, 7..15 length constraint (E.164 local part guideline)
                      if (!RegExp(r'^\d{7,15}$').hasMatch(v)) {
                        return 'Enter 7–15 digits';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
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
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
