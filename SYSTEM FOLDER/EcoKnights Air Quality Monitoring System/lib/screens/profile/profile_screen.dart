import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <- add this
import 'package:cached_network_image/cached_network_image.dart';
import '../profile/edit_profile_screen.dart';
import 'change_password_screen.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        width: 200,
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
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            text,
            style: GoogleFonts.nunitoSans(
                fontSize: 16, color: ColorsManager.lightYellow),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUid = currentUser?.uid;

    return Scaffold(
      backgroundColor: ColorsManager.lightYellow,
      appBar: AppBar(
        title: Text('Profile', style: TextStyles.profileScreenTitle),
        backgroundColor: ColorsManager.greyGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorsManager.mainBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: currentUid == null
            ? const Text('Not signed in')
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Text('No profile found');
                  }

                  final doc = snapshot.data!;
                  if (!doc.exists) return const Text('Profile not found');

                  final data = doc.data() ?? <String, dynamic>{};
                  final username = (data['username'] as String?) ?? 'No Name';
                  final photoUrl = (data['photoURL'] as String?) ?? '';

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: photoUrl.isNotEmpty
                            ? CachedNetworkImageProvider(photoUrl)
                            : const AssetImage('assets/images/placeholder.png')
                                as ImageProvider,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        username,
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          color: ColorsManager.mainBlue,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        currentUser?.email ?? 'No Email',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 16,
                          color: ColorsManager.gray,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildButton('Edit Profile', () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                        // No manual refresh needed — stream updates automatically.
                      }),
                      _buildButton('Change Password', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChangePasswordScreen(),
                          ),
                        );
                      }),
                      _buildButton('Log Out', _logout),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
