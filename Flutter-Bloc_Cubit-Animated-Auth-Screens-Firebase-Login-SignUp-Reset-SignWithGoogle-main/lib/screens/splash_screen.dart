// screens/splash/splash_screen.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../routing/routes.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _safetyTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkAuthAndNavigate();
    _startSafetyTimer();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  void _startSafetyTimer() {
    // Safety timeout - if still loading after 20 seconds, force navigation
    _safetyTimer = Timer(const Duration(seconds: 20), () {
      if (mounted) {
        debugPrint(
            'DEBUG: Safety timeout reached, forcing navigation to login');
        _navigateToLogin();
      }
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      // Wait for animations to complete
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;

      // Check if user is authenticated
      User? firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        debugPrint('DEBUG: No Firebase user found');
        _navigateToLogin();
        return;
      }

      debugPrint('DEBUG: Firebase user found: ${firebaseUser.uid}');

      // Check if email is verified
      if (!firebaseUser.emailVerified) {
        debugPrint('DEBUG: Email not verified');
        _navigateToLogin();
        return;
      }

      debugPrint('DEBUG: Getting user profile from Firestore...');

      // TEMPORARY: Direct Firestore call for debugging
      UserModel? userProfile;
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .get()
            .timeout(const Duration(seconds: 10));

        debugPrint('DEBUG: Document exists: ${doc.exists}');

        if (doc.exists && doc.data() != null) {
          userProfile = UserModel.fromFirestore(doc);
          debugPrint('DEBUG: UserModel created from document');
        } else {
          debugPrint('DEBUG: Document does not exist');
          userProfile = null;
        }
      } catch (e) {
        debugPrint('DEBUG: Direct Firestore error: $e');
        userProfile = null;
      }

      if (userProfile == null) {
        debugPrint('DEBUG: User profile is null or timeout occurred');
        _navigateToLogin();
        return;
      }

      // FIXED: Correct string interpolation syntax
      debugPrint(
          'DEBUG: User profile loaded, role: ${userProfile.isAdmin ? "admin" : "user"}');

      // Don't await updateLastLogin to avoid blocking navigation
      FirestoreService.updateLastLogin().catchError((e) {
        debugPrint('DEBUG: Failed to update last login: $e');
      });

      // Cancel safety timer since we're about to navigate
      _safetyTimer?.cancel();

      // Navigate based on user role
      if (userProfile.isAdmin) {
        debugPrint('DEBUG: Navigating to admin home');
        _navigateToAdminHome();
      } else {
        debugPrint('DEBUG: Navigating to user home');
        _navigateToHome();
      }
    } catch (e) {
      debugPrint('DEBUG: Error during auth check: $e');
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      _safetyTimer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(Routes.loginScreen);
        }
      });
    }
  }

  void _navigateToHome() {
    if (mounted) {
      _safetyTimer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(Routes.home);
        }
      });
    }
  }

  void _navigateToAdminHome() {
    if (mounted) {
      _safetyTimer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(Routes.adminHome);
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _safetyTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo
                    Container(
                      width: 120.w,
                      height: 120.h,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.security,
                        size: 60.sp,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // App Name
                    Text(
                      'EcoKnights',
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                        letterSpacing: 2,
                      ),
                    ),

                    SizedBox(height: 8.h),

                    // App Tagline
                    Text(
                      'Air Quality Monitoring System',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    SizedBox(height: 40.h),

                    // Loading Indicator
                    SizedBox(
                      width: 35.w,
                      height: 35.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue.shade600,
                        ),
                      ),
                    ),

                    SizedBox(height: 16.h),

                    Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
