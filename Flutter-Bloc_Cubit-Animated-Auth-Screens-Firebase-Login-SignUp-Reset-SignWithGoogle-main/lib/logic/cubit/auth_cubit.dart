import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auth_bloc/models/user_model.dart';
import 'package:auth_bloc/services/firestore_service.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthCubit() : super(AuthInitial());

  // FIXED: Better error handling and state management
  Future<void> createAccountAndLinkItWithGoogleAccount(
      String email,
      String password,
      GoogleSignInAccount googleUser,
      OAuthCredential credential) async {
    if (isClosed) return;
    emit(AuthLoading());

    try {
      // Create user with email/password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: googleUser.email,
        password: password,
      );

      // Link with Google credential
      await userCredential.user!.linkWithCredential(credential);

      // Update profile information
      await userCredential.user!.updateDisplayName(googleUser.displayName);
      await userCredential.user!.updatePhotoURL(googleUser.photoUrl);

      // Create user profile in Firestore
      final userModel = UserModel.create(
        uid: userCredential.user!.uid,
        email: googleUser.email,
        username: googleUser.displayName ?? googleUser.email.split('@').first,
        role: UserRole.user,
        isEmailVerified: true, // Google accounts are considered verified
        photoURL: googleUser.photoUrl,
      );

      await _firestore
          .collection("users")
          .doc(userCredential.user!.uid)
          .set(userModel.toFirestore());

      if (isClosed) return;
      emit(UserSingupAndLinkedWithGoogle());
    } catch (e) {
      debugPrint('❌ Error linking Google account: $e');
      if (!isClosed) emit(AuthError(_getErrorMessage(e)));
    }
  }

  Future<void> resetPassword(String email) async {
    if (isClosed) return;
    emit(AuthLoading());

    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (!isClosed) emit(ResetPasswordSent());
    } catch (e) {
      debugPrint('❌ Error resetting password: $e');
      if (!isClosed) emit(AuthError(_getErrorMessage(e)));
    }
  }

  Future<void> signInWithEmail({
  required String email,
  required String password,
}) async {
  try {
    if (!isClosed) emit(AuthLoading());

    // Sign in with Firebase Auth
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      if (!isClosed) emit(AuthError("User not found"));
      return;
    }

    // Load or create Firestore user profile
    final userProfile = await _getOrCreateUserProfile(user);
    if (userProfile == null) {
      if (!isClosed) emit(AuthError("Failed to load user profile"));
      return;
    }

    // Update last login timestamp
    await _updateLastLogin(userProfile.uid);

    // Check if account is active
    if (!userProfile.isActive) {
      await _auth.signOut();
      if (!isClosed) {
        emit(AuthError(
          'Your account has been deactivated. Please contact support.',
        ));
      }
      return;
    }

    // 🔑 Role-based login
    if (userProfile.isAdmin) {
      debugPrint('✅ Admin login from Firestore role');
      emit(AdminSignIn(user: userProfile));
    } else {
      debugPrint('✅ Normal user login');
      emit(UserSignIn(user: userProfile));
    }
  } on FirebaseAuthException catch (e) {
    String errorMessage;
    switch (e.code) {
      case 'user-not-found':
        errorMessage = 'No user found for that email.';
        break;
      case 'wrong-password':
        errorMessage = 'Wrong password provided for that user.';
        break;
      case 'invalid-email':
        errorMessage = 'The email address is invalid.';
        break;
      default:
        errorMessage = 'Authentication error: ${e.message}';
    }
    if (!isClosed) emit(AuthError(errorMessage));
  } catch (e) {
    if (!isClosed) {
      emit(AuthError("An unexpected error occurred: $e"));
    }
  }
}




  Future<void> signInWithGoogle() async {
    if (isClosed) return;
    emit(AuthLoading());

    try {
      debugPrint('🔐 Starting Google sign in');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        if (!isClosed) emit(AuthError('Google Sign In cancelled'));
        return;
      }

      // Get Google auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential authResult =
          await _auth.signInWithCredential(credential);
      final user = authResult.user;

      if (user == null) {
        if (!isClosed) emit(AuthError('Google sign in failed'));
        return;
      }

      // Check if this is a new user
      if (authResult.additionalUserInfo?.isNewUser == true) {
        // Delete the user account so they can register properly
        await user.delete();
        if (!isClosed)
          emit(IsNewUser(googleUser: googleUser, credential: credential));
        return;
      }

      debugPrint('✅ Google auth successful for: ${user.uid}');

      // Get or create user profile
      final userProfile = await _getOrCreateUserProfile(user);
      if (userProfile == null) {
        if (!isClosed) emit(AuthError("Failed to load user profile"));
        return;
      }

      // Update last login
      await _updateLastLogin(userProfile.uid);

      // Check if user is active
      if (!userProfile.isActive) {
        await _auth.signOut();
        if (!isClosed) {
          emit(AuthError(
              'Your account has been deactivated. Please contact support.'));
        }
        return;
      }

      // Emit appropriate state based on role
      if (isClosed) return;
      if (userProfile.isAdmin) {
        emit(AdminSignIn(user: userProfile));
      } else {
        emit(UserSignIn(user: userProfile));
      }
    } catch (e) {
      debugPrint('❌ Google sign in error: $e');
      if (!isClosed) emit(AuthError(_getErrorMessage(e)));
    }
  }

  Future<void> signOut() async {
    if (isClosed) return;
    emit(AuthLoading());

    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      if (!isClosed) emit(UserSignedOut());
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      if (!isClosed) emit(AuthError('Failed to sign out'));
    }
  }

  Future<void> signUpWithEmail(
      String name, String email, String password) async {
    if (isClosed) return;
    emit(AuthLoading());

    try {
      debugPrint('📝 Starting email signup for: $email');

      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        if (!isClosed) emit(AuthError('Signup failed'));
        return;
      }

      // Update display name
      await user.updateDisplayName(name);

      // Create comprehensive user profile in Firestore
      final userModel = UserModel.create(
        uid: user.uid,
        email: email,
        username: name,
        role: UserRole.user, // Default role
        isEmailVerified: false,
      );

      await _firestore
          .collection("users")
          .doc(user.uid)
          .set(userModel.toFirestore());

      debugPrint('✅ User profile created in Firestore');

      // Send email verification
      await user.sendEmailVerification();

      // Sign out until verified
      await _auth.signOut();

      if (!isClosed) emit(UserSingupButNotVerified());
    } catch (e) {
      debugPrint('❌ Signup error: $e');
      if (!isClosed) emit(AuthError(_getErrorMessage(e)));
    }
  }

  // Helper method to get or create user profile
  Future<UserModel?> _getOrCreateUserProfile(User firebaseUser) async {
  try {
    debugPrint('🔍 Getting user profile for: ${firebaseUser.uid}');

    final docSnapshot =
        await _firestore.collection('users').doc(firebaseUser.uid).get();

    if (docSnapshot.exists && docSnapshot.data() != null) {
      debugPrint('✅ User profile found in Firestore');
      return UserModel.fromFirestore(docSnapshot);
    }

    // 🚨 Only create default user for *new signups*
    // For admin, you should manually insert doc in Firestore first
    debugPrint('📝 Creating new user profile in Firestore (default user role)');
    final userModel = UserModel.create(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      username: firebaseUser.displayName ??
          firebaseUser.email?.split('@').first ??
          'User',
      role: UserRole.user,
      isEmailVerified: firebaseUser.emailVerified,
      photoURL: firebaseUser.photoURL,
    );

    await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .set(userModel.toFirestore());

    return userModel;
  } catch (e) {
    debugPrint('❌ Error getting/creating user profile: $e');
    return null;
  }
}


  // Helper method to update last login
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(), // Use server timestamp
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Last login updated');
    } catch (e) {
      debugPrint('⚠️ Failed to update last login: $e');
      // Don't throw error, just log it
    }
  }

  // Helper method to get user-friendly error messages
  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'weak-password':
          return 'Please choose a stronger password.';
        case 'network-request-failed':
          return 'Network error. Please check your connection.';
        case 'invalid-credential':
          return 'Invalid credentials. Please check your email and password.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with this email but different sign-in method.';
        default:
          return error.message ?? 'Authentication failed. Please try again.';
      }
    }
    return error.toString();
  }

  // Method to check current auth state
  Future<void> checkAuthState() async {
    if (isClosed) return;

    try {
      final user = _auth.currentUser;
      if (user == null) {
        emit(AuthInitial());
        return;
      }

      if (!user.emailVerified) {
        emit(UserNotVerified());
        return;
      }

      // Get user profile
      final userProfile = await _getOrCreateUserProfile(user);
      if (userProfile == null) {
        if (!isClosed) emit(AuthError("Failed to load user profile"));
        return;
      }

      // Check if active
      if (!userProfile.isActive) {
        await signOut();
        return;
      }

      // Emit appropriate state
      if (isClosed) return;
      if (userProfile.isAdmin) {
        emit(AdminSignIn(user: userProfile));
      } else {
        emit(UserSignIn(user: userProfile));
      }
    } catch (e) {
      debugPrint('❌ Error checking auth state: $e');
      if (!isClosed) emit(AuthInitial());
    }
  }

  // Method to verify email (for UI to call after user clicks verification link)
  Future<void> verifyEmail() async {
    if (isClosed) return;
    emit(AuthLoading());

    try {
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;

      if (user != null && user.emailVerified) {
        // Update Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'isEmailVerified': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await checkAuthState(); // This will emit the correct state
      } else {
        if (!isClosed) emit(UserNotVerified());
      }
    } catch (e) {
      debugPrint('❌ Error verifying email: $e');
      if (!isClosed) emit(AuthError(_getErrorMessage(e)));
    }
  }

  @override
  Future<void> close() {
    // Clean up any streams or resources here if needed
    return super.close();
  }
}
