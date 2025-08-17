// In lib/ui/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../profile/edit_profile_screen.dart'; 

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
            if (FirebaseAuth.instance.currentUser?.photoURL != null)
              CircleAvatar(
                radius: 50,
                backgroundImage: CachedNetworkImageProvider(
                  FirebaseAuth.instance.currentUser!.photoURL!,
                ),
              )
            else
              const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/images/placeholder.png'),
              ),
            const SizedBox(height: 20),
            Text(
              FirebaseAuth.instance.currentUser?.displayName ?? 'No Name',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              FirebaseAuth.instance.currentUser?.email ?? 'No Email',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                );
              },
              child: const Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }
}