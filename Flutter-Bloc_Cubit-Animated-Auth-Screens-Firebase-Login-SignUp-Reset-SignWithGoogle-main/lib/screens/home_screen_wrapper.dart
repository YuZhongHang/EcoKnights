import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'home/ui/home_screen.dart';
import 'admin/admin_home_screen.dart';
import 'login/ui/login_screen.dart';

class HomeScreenWrapper extends StatelessWidget {
  const HomeScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!authSnapshot.hasData) {
          return const LoginScreen();
        }

        final user = authSnapshot.data!;

        return StreamBuilder<DocumentSnapshot>(
          // Using 'user' collection to match security rules
          stream: FirebaseFirestore.instance
              .collection('users') // Matches your security rules
              .doc(user.uid)
              .snapshots(),
          builder: (context, docSnapshot) {
            if (docSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading user data...'),
                    ],
                  ),
                ),
              );
            }

            if (docSnapshot.hasError) {
              print('=== FIRESTORE ERROR ===');
              print('Error: ${docSnapshot.error}');
              print('User UID: ${user.uid}');
              print('=======================');

              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Error loading user data'),
                      const SizedBox(height: 8),
                      Text(
                        'Error: ${docSnapshot.error}',
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _createUserDocument(user),
                        child: const Text('Create Profile'),
                      ),
                      TextButton(
                        onPressed: () => FirebaseAuth.instance.signOut(),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!docSnapshot.hasData || !docSnapshot.data!.exists) {
              print('=== USER DOCUMENT MISSING ===');
              print('User UID: ${user.uid}');
              print('Document exists: ${docSnapshot.data?.exists ?? false}');
              print('==============================');

              // Auto-create user document
              return FutureBuilder(
                future: _createUserDocument(user),
                builder: (context, createSnapshot) {
                  if (createSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Creating your profile...'),
                          ],
                        ),
                      ),
                    );
                  }

                  if (createSnapshot.hasError) {
                    return Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text('Error creating user profile'),
                            Text('${createSnapshot.error}'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => FirebaseAuth.instance.signOut(),
                              child: const Text('Sign Out'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Profile created successfully, show user screen
                  return const HomeScreen();
                },
              );
            }

            // Debug: Print the data
            final data = docSnapshot.data!.data() as Map<String, dynamic>;
            print('=== HOME SCREEN WRAPPER DEBUG ===');
            print('User UID: ${user.uid}');
            print('User Email: ${user.email}');
            print('Document exists: ${docSnapshot.data!.exists}');
            print('Document data: $data');
            print('Role from document: "${data['role']}"');
            print('Role type: ${data['role'].runtimeType}');

            try {
              final userModel = UserModel.fromFirestore(docSnapshot.data!);
              print('Parsed UserModel role: ${userModel.role}');
              print('UserModel.isAdmin: ${userModel.isAdmin}');
              print(
                  'Role == UserRole.admin: ${userModel.role == UserRole.admin}');
              print(
                  'Role == UserRole.superAdmin: ${userModel.role == UserRole.superAdmin}');
              print('================================');

              // Route to appropriate screen based on role
              if (userModel.isAdmin) {
                print('Routing to ADMIN screen');
                return const AdminHomeScreen();
              } else {
                print('Routing to USER screen');
                return const HomeScreen();
              }
            } catch (e) {
              print('=== PARSING ERROR ===');
              print('Error parsing user model: $e');
              print('Raw data: $data');
              print('=====================');

              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning, size: 48, color: Colors.orange),
                      const SizedBox(height: 16),
                      const Text('Error parsing user data'),
                      Text('$e'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _fixUserDocument(user, data),
                        child: const Text('Fix Profile'),
                      ),
                      TextButton(
                        onPressed: () => FirebaseAuth.instance.signOut(),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  // Helper method to create user document
  static Future<void> _createUserDocument(User firebaseUser) async {
    final docRef =
        FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid);
    final snap = await docRef.get();

    if (snap.exists) {
      // Preserve existing role and metadata
      final existing = snap.data() as Map<String, dynamic>;
      final preservedRole =
          existing['role']; // string or int depending on your model
      final preservedIsActive = existing['isActive'];

      final userModel = UserModel(
        uid: firebaseUser.uid,
        email: existing['email'] ?? firebaseUser.email ?? '',
        username: existing['username'] ??
            firebaseUser.displayName ??
            firebaseUser.email?.split('@').first ??
            'User${firebaseUser.uid.substring(0, 6)}',
        phoneNumber: existing['phoneNumber'] ?? firebaseUser.phoneNumber,
        createdAt: (existing['createdAt'] is Timestamp)
            ? (existing['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        lastLoginAt: DateTime.now(),
        photoURL: existing['photoURL'] ?? firebaseUser.photoURL,
        role: preservedRole != null
            ? UserRole.fromString(preservedRole) // <-- see helper below
            : UserRole.user, // fallback if somehow missing
        isActive: preservedIsActive is bool ? preservedIsActive : true,
        isEmailVerified: existing['isEmailVerified'] is bool
            ? existing['isEmailVerified']
            : (firebaseUser.emailVerified),
      );

      await docRef.set(userModel.toFirestore(), SetOptions(merge: true));
      return;
    }

    // New document: it’s safe to default to user here
    final userModel = UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      username: firebaseUser.displayName ??
          firebaseUser.email?.split('@').first ??
          'User${firebaseUser.uid.substring(0, 6)}',
      phoneNumber: firebaseUser.phoneNumber,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      photoURL: firebaseUser.photoURL,
      role: UserRole.user, // default for brand new users
      isActive: true,
      isEmailVerified: firebaseUser.emailVerified,
    );

    await docRef.set(userModel.toFirestore(), SetOptions(merge: true));
  }

  // Helper method to fix corrupted user document
  // lib/screens/home_screen_wrapper.dart
  static Future<void> _fixUserDocument(
      User firebaseUser, Map<String, dynamic> existingData) async {
    final docRef =
        FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid);

    final userModel = UserModel(
      uid: firebaseUser.uid,
      email: existingData['email'] ?? firebaseUser.email ?? '',
      username: existingData['username'] ??
          firebaseUser.displayName ??
          firebaseUser.email?.split('@').first ??
          'User${firebaseUser.uid.substring(0, 6)}',
      phoneNumber: existingData['phoneNumber'] ?? firebaseUser.phoneNumber,
      createdAt: (existingData['createdAt'] is Timestamp)
          ? (existingData['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastLoginAt: DateTime.now(),
      photoURL: existingData['photoURL'] ?? firebaseUser.photoURL,
      // PRESERVE role if present; never hardcode to user here
      role: (existingData.containsKey('role') && existingData['role'] != null)
          ? UserRole.fromString(existingData['role'])
          : UserRole.user,
      isActive:
          (existingData['isActive'] is bool) ? existingData['isActive'] : true,
      isEmailVerified: (existingData['isEmailVerified'] is bool)
          ? existingData['isEmailVerified']
          : firebaseUser.emailVerified,
    );

    await docRef.set(userModel.toFirestore(), SetOptions(merge: true));
  }
}
