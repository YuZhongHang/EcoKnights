import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import 'package:google_fonts/google_fonts.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  bool _isLoading = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;

  @override
  void initState() {
    super.initState();
    // Add listeners to both controllers for real-time validation
    _oldPassController.addListener(_validateForm);
    _newPassController.addListener(_validateForm);
  }

  void _validateForm() {
    // Trigger validation when either field changes
    if (_formKey.currentState != null) {
      _formKey.currentState!.validate();
    }
  }

  @override
  void dispose() {
    _oldPassController.removeListener(_validateForm);
    _newPassController.removeListener(_validateForm);
    _oldPassController.dispose();
    _newPassController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    // CRITICAL: Force validation and check result
    final isValid = _formKey.currentState?.validate() ?? false;

    print("Form validation result: $isValid");
    print("Old password: '${_oldPassController.text.trim()}'");
    print("New password: '${_newPassController.text.trim()}'");

    if (!isValid) {
      print("Form validation failed - stopping execution");
      return;
    }

    final oldPass = _oldPassController.text.trim();
    final newPass = _newPassController.text.trim();

    if (oldPass == newPass) {
      print("BLOCKED: Passwords are identical after trim");
      _showMessage('New password cannot be the same as old password.');
      return;
    }

    if (oldPass.isEmpty) {
      print("BLOCKED: Old password is empty");
      _showMessage('Please enter your old password.');
      return;
    }

    if (newPass.isEmpty) {
      print("BLOCKED: New password is empty");
      _showMessage('Please enter a new password.');
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('User not logged in.');
      setState(() => _isLoading = false);
      return;
    }

    try {
      print("Attempting to reauthenticate user");
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPass,
      );
      await user.reauthenticateWithCredential(cred);

      print("Attempting to update password");
      await user.updatePassword(newPass);
      _showMessage('Password changed successfully!');
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error: ${e.code} - ${e.message}");
      if (e.code == 'wrong-password') {
        _showMessage('Old password is incorrect.');
      } else if (e.code == 'weak-password') {
        _showMessage('New password is too weak.');
      } else {
        _showMessage('Error: ${e.message}');
      }
    } catch (e) {
      print("Unexpected error: $e");
      _showMessage('Unexpected error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: msg.contains('successfully') ? Colors.green : Colors.red,
    ));
  }

  String? _validateOldPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter old password';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter new password';
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(trimmedValue)) {
      return 'Include at least 1 special character';
    }

    // Check against old password
    final oldPassword = _oldPassController.text.trim();
    if (oldPassword.isNotEmpty && trimmedValue == oldPassword) {
      return 'New password cannot be the same as old password';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.lightYellow,
      appBar: AppBar(
        title: Text(
          'Change Password',
          style: TextStyles.profileScreenTitle,
        ),
        backgroundColor: ColorsManager.greyGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorsManager.mainBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                children: [
                  TextFormField(
                    controller: _oldPassController,
                    obscureText: _obscureOldPassword,
                    decoration: InputDecoration(
                      labelText: 'Old Password',
                      labelStyle: TextStyle(
                          color: ColorsManager.gray), // Label text color
                      border: const OutlineInputBorder(
                        borderSide: BorderSide(color: ColorsManager.gray),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: ColorsManager.gray),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: ColorsManager.greyGreen, width: 2.0),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: ColorsManager
                                .zhYellow), // <-- your custom color
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: ColorsManager.zhYellow,
                            width: 2.0), // <-- your custom color
                      ),
                      prefixIcon: Icon(
                        Icons.lock,
                        color: ColorsManager.gray,
                      ),
                      errorStyle: GoogleFonts.nunitoSans(
                        color: ColorsManager.zhYellow,
                        fontSize: 14, // custom font size
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscureOldPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: ColorsManager.darkBlue),
                        onPressed: () {
                          setState(() {
                            _obscureOldPassword = !_obscureOldPassword;
                          });
                        },
                      ),
                    ),
                    validator: _validateOldPassword,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _newPassController,
                    obscureText: _obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      labelStyle: TextStyle(
                          color: ColorsManager.gray), // Label text color
                      border: const OutlineInputBorder(
                        borderSide: BorderSide(color: ColorsManager.gray),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: ColorsManager.gray),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: ColorsManager.greyGreen, width: 2.0),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: ColorsManager
                                .zhYellow), // <-- your custom color
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: ColorsManager.zhYellow,
                            width: 2.0), // <-- your custom color
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: ColorsManager.gray,
                      ),
                      errorStyle: GoogleFonts.nunitoSans(
                        color: ColorsManager.zhYellow,
                        fontSize: 14, // custom font size
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscureNewPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: ColorsManager.darkBlue),
                        onPressed: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                    ),
                    validator: _validateNewPassword,
                  ),
                  const SizedBox(height: 30),
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
                      onPressed: _isLoading ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors
                            .transparent, // Make button background transparent
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: ColorsManager.mainBlue)
                          : Text(
                              'Change Password',
                              style: GoogleFonts.nunitoSans(
                                  fontSize: 16,
                                  color: ColorsManager.lightYellow),
                            ),
                    ),
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
