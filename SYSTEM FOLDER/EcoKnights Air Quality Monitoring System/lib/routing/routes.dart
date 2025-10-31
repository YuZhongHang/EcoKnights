class Routes {
  // Splash and initial routes
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';

  // Authentication routes
  static const String loginScreen = '/login';
  static const String signupScreen = '/signup';
  static const String forgetScreen = '/forgot-password';
  static const String createPassword = '/create-password';
  static const String emailVerification = '/email-verification';
  static const String resetPassword = '/reset-password';

  // Main app routes
  static const String home = '/';
  static const String homeScreen = '/home'; // Alternative path to home
  
  // User routes
  static const String profileScreen = '/profile';
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';
  static const String notifications = '/notifications';

  // Admin routes
  static const String adminHome = '/admin';
  static const String adminUserManagement = '/admin/users';
  static const String adminSettings = '/admin/settings';
  static const String adminAnalytics = '/admin/analytics';
  static const String adminLogs = '/admin/logs';
  static const String adminContentManagement = '/admin/content';
  static const String adminNotifications = '/admin/notifications';
  static const String adminBackup = '/admin/backup';

  // Error and utility routes
  static const String error = '/error';
  static const String notFound = '/not-found';
  static const String maintenance = '/maintenance';

  // Feature routes (add your app-specific routes here)
  static const String search = '/search';
  static const String favorites = '/favorites';
  static const String history = '/history';
  
  // Route groups for easier management
  static const List<String> authRoutes = [
    loginScreen,
    signupScreen,
    forgetScreen,
    createPassword,
    emailVerification,
    resetPassword,
  ];

  static const List<String> protectedRoutes = [
    home,
    homeScreen,
    profileScreen,
    editProfile,
    settings,
    notifications,
    search,
    favorites,
    history,
  ];

  static const List<String> adminRoutes = [
    adminHome,
    adminUserManagement,
    adminSettings,
    adminAnalytics,
    adminLogs,
    adminContentManagement,
    adminNotifications,
    adminBackup,
  ];

  static const List<String> publicRoutes = [
    splash,
    onboarding,
    error,
    notFound,
    maintenance,
  ];

  // Helper methods
  static bool isAuthRoute(String route) => authRoutes.contains(route);
  static bool isProtectedRoute(String route) => protectedRoutes.contains(route);
  static bool isAdminRoute(String route) => adminRoutes.contains(route);
  static bool isPublicRoute(String route) => publicRoutes.contains(route);

  // Get initial route based on app state
  static String getInitialRoute({
    bool isFirstTime = false,
    bool isLoggedIn = false,
    bool isAdmin = false,
  }) {
    if (isFirstTime) return onboarding;
    if (!isLoggedIn) return loginScreen;
    if (isAdmin) return adminHome; // You can change this to adminHome if preferred
    return home;
  }

  // Get route title for app bar
  static String getRouteTitle(String route) {
    switch (route) {
      case loginScreen:
        return 'Login';
      case signupScreen:
        return 'Sign Up';
      case forgetScreen:
        return 'Forgot Password';
      case createPassword:
        return 'Create Password';
      case emailVerification:
        return 'Verify Email';
      case resetPassword:
        return 'Reset Password';
      case home:
      case homeScreen:
        return 'Home';
      case profileScreen:
        return 'Profile';
      case editProfile:
        return 'Edit Profile';
      case settings:
        return 'Settings';
      case notifications:
        return 'Notifications';
      case adminHome:
        return 'Admin Dashboard';
      case adminUserManagement:
        return 'User Management';
      case adminSettings:
        return 'Admin Settings';
      case adminAnalytics:
        return 'Analytics';
      case adminLogs:
        return 'Admin Logs';
      case adminContentManagement:
        return 'Content Management';
      case adminNotifications:
        return 'Push Notifications';
      case adminBackup:
        return 'Backup & Restore';
      case search:
        return 'Search';
      case favorites:
        return 'Favorites';
      case history:
        return 'History';
      default:
        return 'App';
    }
  }

  // Get route icon for navigation
  static String getRouteIcon(String route) {
    switch (route) {
      case home:
      case homeScreen:
        return 'home';
      case profileScreen:
        return 'person';
      case settings:
        return 'settings';
      case notifications:
        return 'notifications';
      case adminHome:
        return 'admin_panel_settings';
      case adminUserManagement:
        return 'people';
      case search:
        return 'search';
      case favorites:
        return 'favorite';
      case history:
        return 'history';
      default:
        return 'page';
    }
  }

  // Check if route requires specific permissions
  static List<String> getRequiredPermissions(String route) {
    if (isAdminRoute(route)) {
      switch (route) {
        case adminUserManagement:
          return ['manage_users'];
        case adminSettings:
          return ['manage_settings'];
        case adminAnalytics:
          return ['view_analytics'];
        case adminLogs:
          return ['view_logs'];
        case adminContentManagement:
          return ['manage_content'];
        case adminNotifications:
          return ['send_notifications'];
        case adminBackup:
          return ['manage_backups'];
        default:
          return ['admin_access'];
      }
    }
    return [];
  }

  // Generate route path with parameters
  static String generatePath(String route, {Map<String, String>? params}) {
    if (params == null || params.isEmpty) return route;
    
    var path = route;
    var query = <String>[];
    
    for (var entry in params.entries) {
      if (path.contains(':${entry.key}')) {
        path = path.replaceAll(':${entry.key}', entry.value);
      } else {
        query.add('${entry.key}=${Uri.encodeComponent(entry.value)}');
      }
    }
    
    if (query.isNotEmpty) {
      path += '?${query.join('&')}';
    }
    
    return path;
  }

  // Parse route parameters from path
  static Map<String, String> parseParameters(String path) {
    final uri = Uri.parse(path);
    return uri.queryParameters;
  }
}