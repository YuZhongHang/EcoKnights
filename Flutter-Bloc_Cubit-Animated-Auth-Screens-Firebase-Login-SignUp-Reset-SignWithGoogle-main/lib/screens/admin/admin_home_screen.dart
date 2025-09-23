import 'package:auth_bloc/screens/home/ui/home_screen.dart';
import 'package:auth_bloc/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/user_model.dart';
import 'admin_user_management.dart';
import '../profile/edit_profile_screen.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  UserModel? currentUser;
  Map<String, int> userStats = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    try {
      setState(() => isLoading = true);

      // Load current user data
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          currentUser = UserModel.fromFirestore(userDoc);
        }
      }

      // Load user statistics
      await _loadUserStats();
    } catch (e) {
      debugPrint('Error loading admin data: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loadUserStats() async {
    try {
      final usersQuery =
          await FirebaseFirestore.instance.collection('users').get();

      final stats = <String, int>{
        'total': 0,
        'active': 0,
        'inactive': 0,
        'admins': 0,
        'users': 0,
      };

      for (var doc in usersQuery.docs) {
        try {
          final user = UserModel.fromFirestore(doc);

          stats['total'] = stats['total']! + 1;

          if (user.isActive) {
            stats['active'] = stats['active']! + 1;
          } else {
            stats['inactive'] = stats['inactive']! + 1;
          }

          if (user.isAdmin) {
            stats['admins'] = stats['admins']! + 1;
          } else {
            stats['users'] = stats['users']! + 1;
          }
        } catch (e) {
          debugPrint('Error parsing user document: $e');
        }
      }

      if (mounted) {
        setState(() => userStats = stats);
      }
    } catch (e) {
      debugPrint('Error loading user stats: $e');
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorsManager.lightYellow,
        title: const Text(
          'Confirm Logout',
          style: TextStyle(
            fontFamily: 'Georgia',
            color: ColorsManager.mainBlue,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.nunitoSans(
            color: ColorsManager.gray,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunitoSans(
                color: ColorsManager.mainBlue,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.mainBlue),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Logout',
              style: GoogleFonts.nunitoSans(
                color: ColorsManager.lightYellow,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error logging out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToUserManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminUserManagement()),
    );
  }

  void _navigateToViewProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    ).then((_) => _loadAdminData());
  }

  // Admin action items
  List<AdminActionItem> get _adminActions => [
        AdminActionItem(
          title: 'View Profile',
          subtitle: 'Update your info',
          icon: Icons.account_circle,
          color: Colors.pink,
          onTap: _navigateToViewProfile,
        ),
        AdminActionItem(
          title: 'Manage Users',
          subtitle: 'View, edit, and delete users',
          icon: Icons.people,
          color: Colors.blue,
          onTap: _navigateToUserManagement,
        ),
        AdminActionItem(
          title: 'Analytics',
          subtitle: 'View app analytics and reports',
          icon: Icons.analytics,
          color: Colors.orange,
          onTap: () => _showComingSoon('Analytics'),
        ),
        AdminActionItem(
          title: 'Notifications',
          subtitle: 'Send push notifications',
          icon: Icons.notifications,
          color: Colors.indigo,
          onTap: () => _showComingSoon('Notifications'),
        ),
      ];

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.darkBlue,
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: TextStyles.adminDashboardTitle,
        ),
        backgroundColor: ColorsManager.gray,
        foregroundColor: ColorsManager.lightYellow,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
            tooltip: 'Home Page',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAdminData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeSection(),
                    const SizedBox(height: 24),
                    _buildQuickActionsSection(),
                    const SizedBox(height: 24),
                    _buildAdminActionsGrid(),
                  ],
                ),
              ),
            ),
    );
  }

  // --- UI Builders ---

  Widget _buildWelcomeSection() {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [ColorsManager.gray, ColorsManager.mainBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.admin_panel_settings,
                size: 48, color: ColorsManager.lightYellow),
            const SizedBox(height: 16),
            Text(
              'Welcome, ${currentUser?.username ?? 'Admin'}!',
              style: TextStyles.adminDashboardCardTitle,
            ),
            const SizedBox(height: 8),
            Text(
              'You have administrator privileges to manage the system',
              style: GoogleFonts.nunitoSans(
                  fontSize: 16, color: ColorsManager.lightYellow),
            ),
            if (currentUser?.email != null) ...[
              const SizedBox(height: 8),
              Text(
                'Logged in as: ${currentUser!.email}',
                style: GoogleFonts.nunitoSans(
                    fontSize: 14, color: ColorsManager.greyGreen),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [ColorsManager.greyGreen, ColorsManager.gray],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ColorsManager.lightYellow,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 12, color: ColorsManager.lightYellow),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyles.adminDashboardTitle,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ColorsManager.greyGreen, ColorsManager.gray],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: ElevatedButton.icon(
                  onPressed: _navigateToUserManagement,
                  icon: const Icon(Icons.people,
                      color: ColorsManager.lightYellow),
                  label: Text(
                    'Manage Users',
                    style: GoogleFonts.nunitoSans(
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            ColorsManager.lightYellow, // Wrap inside TextStyle
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.transparent, // Make button transparent
                    shadowColor:
                        Colors.transparent, // Remove shadow to show gradient
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ColorsManager.greyGreen, ColorsManager.gray],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: ElevatedButton.icon(
                  onPressed: _loadAdminData,
                  icon: const Icon(Icons.refresh,
                      color: ColorsManager.lightYellow),
                  label: Text(
                    'Refresh Data',
                    style: GoogleFonts.nunitoSans(
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            ColorsManager.lightYellow, // Wrap inside TextStyle
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.transparent, // Make button transparent
                    shadowColor:
                        Colors.transparent, // Remove shadow to show gradient
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminActionsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Admin Tools',
          style: TextStyles.adminDashboardTitle,
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _adminActions.length,
          itemBuilder: (context, index) {
            final action = _adminActions[index];
            return Card(
              elevation: 3,
              child: InkWell(
                onTap: action.onTap,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [ColorsManager.greyGreen, ColorsManager.gray],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(action.icon,
                          size: 36, color: ColorsManager.lightYellow),
                      const SizedBox(height: 8),
                      Text(
                        action.title,
                        style: GoogleFonts.nunitoSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ColorsManager.lightYellow,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        action.subtitle,
                        style: GoogleFonts.nunitoSans(
                            fontSize: 10, color: ColorsManager.gray93Color),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// Helper class for admin actions
class AdminActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  AdminActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
