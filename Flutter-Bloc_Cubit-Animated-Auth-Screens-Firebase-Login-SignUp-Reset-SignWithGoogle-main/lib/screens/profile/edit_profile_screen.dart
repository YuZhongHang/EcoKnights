import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import 'package:google_fonts/google_fonts.dart';

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
    _nameController = TextEditingController();
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

      setState(() {
        _nameController.text = (data['username'] as String?) ?? '';
      });

      final storedPhone = (data['phoneNumber'] as String?)?.trim() ?? '';
      if (storedPhone.isNotEmpty) {
        final cleaned = _cleanPlusDigits(storedPhone);
        final split = _splitByKnownCountryCode(cleaned);
        if (split != null) {
          setState(() {
            _selectedCountryCode = split.$1;
            _phoneController.text = split.$2;
          });
        } else {
          setState(() => _phoneController.text = cleaned.replaceAll('+', ''));
        }
      }
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
    try {
      final request =
          http.MultipartRequest('POST', Uri.parse(CLOUDINARY_UPLOAD_URL));

      request.fields['upload_preset'] = CLOUDINARY_UPLOAD_PRESET;
      request.fields['folder'] = 'profile_images';

      request.files
          .add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = json.decode(responseString);

        return jsonMap['secure_url'];
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      print('Cloudinary upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to upload image: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: ColorsManager.zhYellow,
          ),
        );
      }
      return null;
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
      final fullPhone = '$_selectedCountryCode$local';

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

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Profile updated successfully!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: ColorsManager.mainBlue,
          ),
        );
        setState(() => _image = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: ColorsManager.zhYellow,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ NEW FUNCTION: Delete Account
  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();
      await user.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account deleted successfully.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: ColorsManager.mainBlue,
          ),
        );

        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please re-login before deleting your account.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: ColorsManager.zhYellow,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.message}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: ColorsManager.zhYellow,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error deleting account: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: ColorsManager.zhYellow,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildProfileImage(User? user) {
    const double size = 120;
    Widget imageWidget;

    if (_image != null) {
      imageWidget = Image.file(
        _image!,
        width: size,
        height: size,
        fit: BoxFit.cover,
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
            child:
                const Icon(Icons.camera_alt, size: 40, color: Colors.blueGrey),
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
    return ClipOval(child: imageWidget);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: ColorsManager.lightYellow,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: TextStyles.profileScreenTitle,
        ),
        backgroundColor: ColorsManager.greyGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorsManager.mainBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                // Wrap ListView with Expanded
                child: ListView(
                  children: [
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _isLoading ? null : _pickImage,
                      child: Center(child: _buildProfileImage(user)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to change profile picture',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 16,
                        color: ColorsManager.gray,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Email field (read-only)
                    TextFormField(
                      initialValue: user?.email ?? '',
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Name field
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      style:
                          GoogleFonts.nunitoSans(color: ColorsManager.mainBlue),
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                        prefixIcon:
                            Icon(Icons.person, color: ColorsManager.gray),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Enter your name';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Phone field
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      style:
                          GoogleFonts.nunitoSans(color: ColorsManager.mainBlue),
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
                                color: ColorsManager.gray,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      validator: (value) {
                        final v = (value ?? '').trim();
                        if (v.isEmpty) return 'Enter phone number';
                        if (!RegExp(r'^\d{7,15}$').hasMatch(v))
                          return 'Enter 7-15 digits';
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    // Save Profile Button
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [ColorsManager.greyGreen, ColorsManager.gray],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: _isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: ColorsManager.mainBlue,
                                        strokeWidth: 2),
                                  ),
                                  const SizedBox(width: 12),
                                  Text('Saving...',
                                      style: GoogleFonts.nunitoSans(
                                          color: ColorsManager.mainBlue,
                                          fontSize: 18)),
                                ],
                              )
                            : Text('Save Profile',
                                style: GoogleFonts.nunitoSans(
                                    color: ColorsManager.lightYellow,
                                    fontSize: 18)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              // ✅ Delete Account Button - Moved outside ListView
              Padding(
                padding: const EdgeInsets.only(bottom: 20, top: 50),
                child: Center(
                  child: TextButton.icon(
                    onPressed: _isLoading ? null : _deleteAccount,
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    label: Text(
                      'Delete Account',
                      style: GoogleFonts.nunitoSans(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
