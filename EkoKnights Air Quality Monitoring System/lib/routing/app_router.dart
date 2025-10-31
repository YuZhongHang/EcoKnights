import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../logic/cubit/auth_cubit.dart';
import '../screens/create_password/ui/create_password.dart';
import '../screens/forget/ui/forget_screen.dart';
import '../screens/home/ui/home_screen.dart';
import '../screens/login/ui/login_screen.dart';
import '../screens/signup/ui/sign_up_sceen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/admin/admin_user_management.dart';
import '../screens/splash_screen.dart';
import '../screens/error_screen.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'routes.dart';

class AppRouter {
  late AuthCubit authCubit;
  static UserModel? _cachedCurrentUser;

  AppRouter() {
    authCubit = AuthCubit();
  }

  Route? generateRoute(RouteSettings settings) {
    // Debug logging
    debugPrint('Navigating to: ${settings.name}');

    try {
      switch (settings.name) {
        case Routes.splash:
          return _createRoute(const SplashScreen());

        case Routes.loginScreen:
          return _createAuthRoute(const LoginScreen());

        case Routes.signupScreen:
          return _createAuthRoute(const SignUpScreen());

        case Routes.forgetScreen:
          return _createAuthRoute(const ForgetScreen());

        case Routes.createPassword:
          return _handleCreatePasswordRoute(settings);

        case Routes.home:
        case Routes.homeScreen:
          return _createProtectedRoute(const HomeScreen());

        case Routes.profileScreen:
          return _createProtectedRoute(const ProfileScreen());

        // Admin routes
        case Routes.adminHome:
          return _createAdminRoute(const AdminHomeScreen());

        case Routes.adminUserManagement:
          return _createAdminRoute(const AdminUserManagement());

        // Error route
        case Routes.error:
          return _createRoute(_buildErrorScreen(settings.arguments));

        default:
          return _handleUnknownRoute(settings.name);
      }
    } catch (e, stackTrace) {
      debugPrint('Error in route generation: $e');
      debugPrint('Stack trace: $stackTrace');
      return _createRoute(_buildErrorScreen('Navigation error: $e'));
    }
  }

  // Create basic route without auth checks
  MaterialPageRoute _createRoute(Widget screen, {RouteSettings? settings}) {
    return MaterialPageRoute(
      builder: (_) => screen,
      settings: settings,
    );
  }

  // Create route for auth screens (login, signup, etc.)
  MaterialPageRoute _createAuthRoute(Widget screen) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: authCubit,
        child: screen,
      ),
    );
  }

  // Create route for protected screens (require authentication)
  MaterialPageRoute _createProtectedRoute(Widget screen) {
    return MaterialPageRoute(
      builder: (_) => FutureBuilder<User?>(
        future: _getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.data == null) {
            // User not authenticated, redirect to login
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed(Routes.loginScreen);
            });
            return const SizedBox.shrink();
          }

          return BlocProvider.value(
            value: authCubit,
            child: screen,
          );
        },
      ),
    );
  }

  // Create route for admin screens (require admin role)
  MaterialPageRoute _createAdminRoute(Widget screen) {
    return MaterialPageRoute(
      builder: (_) => FutureBuilder<UserModel?>(
        future: _getCurrentUserWithRole(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Verifying admin access...'),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorScreen(
                'Error verifying access: ${snapshot.error}');
          }

          final user = snapshot.data;

          if (user == null) {
            // User not authenticated, redirect to login
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed(Routes.loginScreen);
            });
            return const SizedBox.shrink();
          }

          if (!user.isAdmin) {
            // User not admin, show access denied
            return _buildAccessDeniedScreen();
          }

          return BlocProvider.value(
            value: authCubit,
            child: screen,
          );
        },
      ),
    );
  }

  // Handle create password route with arguments
  MaterialPageRoute? _handleCreatePasswordRoute(RouteSettings settings) {
    final arguments = settings.arguments;

    if (arguments is! List || arguments.length < 2) {
      debugPrint('Invalid arguments for CreatePassword route');
      return _createRoute(
        _buildErrorScreen('Invalid arguments for password creation'),
      );
    }

    try {
      return MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: authCubit,
          child: CreatePassword(
            googleUser: arguments[0],
            credential: arguments[1],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error creating CreatePassword route: $e');
      return _createRoute(
        _buildErrorScreen('Error setting up password creation'),
      );
    }
  }

  // Handle unknown routes
  MaterialPageRoute _handleUnknownRoute(String? routeName) {
    debugPrint('Unknown route: $routeName');

    // Determine fallback route based on auth state
    return MaterialPageRoute(
      builder: (_) => FutureBuilder<User?>(
        future: _getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          Widget fallbackScreen;
          if (snapshot.data == null) {
            fallbackScreen = const LoginScreen();
          } else {
            fallbackScreen = const HomeScreen();
          }

          return BlocProvider.value(
            value: authCubit,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Page Not Found'),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              body: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Page Not Found',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The page "$routeName" could not be found.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: authCubit,
                            child: fallbackScreen,
                          ),
                        ),
                      );
                    },
                    child: Text(
                        snapshot.data == null ? 'Go to Login' : 'Go to Home'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper method to get current Firebase user
  Future<User?> _getCurrentUser() async {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  // Helper method to get current user with role information
  Future<UserModel?> _getCurrentUserWithRole() async {
    try {
      // Use cached user if available and recent
      if (_cachedCurrentUser != null) {
        return _cachedCurrentUser;
      }

      final user = await FirestoreService.getCurrentUserProfile(useCache: true);
      _cachedCurrentUser = user;

      // Clear cache after 5 minutes
      Future.delayed(const Duration(minutes: 5), () {
        _cachedCurrentUser = null;
      });

      return user;
    } catch (e) {
      debugPrint('Error getting current user with role: $e');
      return null;
    }
  }

  // Build error screen widget - FIXED: Added missing context parameter
  Widget _buildErrorScreen(dynamic error) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'An Error Occurred',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            // FIXED: Wrapped in Builder to get proper context
            Builder(
              builder: (context) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        Routes.home,
                        (route) => false,
                      );
                    },
                    child: const Text('Go Home'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushReplacementNamed(Routes.home);
                      }
                    },
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build access denied screen - FIXED: Removed context parameter
  Widget _buildAccessDeniedScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'You do not have permission to access this page.\nAdmin privileges are required.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            // FIXED: Wrapped in Builder to get proper context
            Builder(
              builder: (context) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        Routes.home,
                        (route) => false,
                      );
                    },
                    child: const Text('Go Home'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        Routes.loginScreen,
                        (route) => false,
                      );
                    },
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to clear cached user (call when user data changes)
  static void clearUserCache() {
    _cachedCurrentUser = null;
  }

  // Method to programmatically navigate with error handling
  static Future<void> navigateTo(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool clearStack = false,
  }) async {
    try {
      if (clearStack) {
        await Navigator.of(context).pushNamedAndRemoveUntil(
          routeName,
          (route) => false,
          arguments: arguments,
        );
      } else {
        await Navigator.of(context).pushNamed(
          routeName,
          arguments: arguments,
        );
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      // Show error dialog or navigate to error page
      if (context.mounted) {
        Navigator.of(context).pushNamed(
          Routes.error,
          arguments: 'Navigation failed: $e',
        );
      }
    }
  }

  // Method to handle deep links or dynamic routes
  Route? handleDeepLink(String path, Map<String, String>? queryParams) {
    debugPrint('Handling deep link: $path with params: $queryParams');

    // Parse the path and convert to route
    if (path.startsWith('/admin')) {
      if (path == '/admin') {
        return generateRoute(const RouteSettings(name: Routes.adminHome));
      } else if (path == '/admin/users') {
        return generateRoute(
            const RouteSettings(name: Routes.adminUserManagement));
      }
    }

    // Handle user profile with ID
    if (path.startsWith('/profile/') && path.length > '/profile/'.length) {
      final userId = path.substring('/profile/'.length);
      return generateRoute(RouteSettings(
        name: Routes.profileScreen,
        arguments: {'userId': userId},
      ));
    }

    // Default handling
    final routeName = path.isEmpty ? Routes.home : path;
    return generateRoute(RouteSettings(name: routeName));
  }

  // Dispose method to clean up resources
  void dispose() {
    authCubit.close();
    _cachedCurrentUser = null;
  }
}
