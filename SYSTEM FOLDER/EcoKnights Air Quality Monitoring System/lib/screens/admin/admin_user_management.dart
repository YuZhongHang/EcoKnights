import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

class AdminUserManagement extends StatefulWidget {
  const AdminUserManagement({super.key});

  @override
  State<AdminUserManagement> createState() => _AdminUserManagementState();
}

class _AdminUserManagementState extends State<AdminUserManagement> {
  late Future<List<UserModel>> _usersFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  UserRole? _filterRole;
  bool? _filterActiveStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    debugUserRole();
    _refreshUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> debugUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('=== DEBUG USER ROLE (AdminUserManagement) ===');

    if (user != null) {
      debugPrint('Current user UID: ${user.uid}');
      debugPrint('Current user email: ${user.email}');
      try {
        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userModel = UserModel.fromFirestore(userDoc);
          debugPrint('User role: ${userModel.role}');
          debugPrint('Role name: ${userModel.role.name}');
          debugPrint('Is admin: ${userModel.isAdmin}');
          debugPrint('Is active: ${userModel.isActive}');
          debugPrint('Username: ${userModel.username}');
        } else {
          debugPrint('User document does not exist for uid ${user.uid}');
        }
      } catch (e) {
        debugPrint('Error loading user doc: $e');
      }
    } else {
      debugPrint('No authenticated user found!');
    }
    debugPrint('=== END DEBUG ===');
  }

  void _refreshUsers() {
    setState(() {
      _usersFuture = FirestoreService.getAllUsers();
    });
  }

  List<UserModel> _filterUsers(List<UserModel> users) {
    return users.where((user) {
      final matchesSearch = _searchQuery.isEmpty ||
          user.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (user.phoneNumber?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      final matchesRole = _filterRole == null || user.role == _filterRole;
      final matchesActive = _filterActiveStatus == null || user.isActive == _filterActiveStatus;
      return matchesSearch && matchesRole && matchesActive;
    }).toList();
  }

  // ======== EDIT DIALOG ========
  void _showEditDialog(UserModel user) {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController(text: user.username);
    final phoneController = TextEditingController(text: user.phoneNumber ?? '');
    UserRole selectedRole = user.role;
    bool isActive = user.isActive;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogOnly) => AlertDialog(
          backgroundColor: ColorsManager.lightYellow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Edit User: ${user.email}",
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: ColorsManager.gray,
            ),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Username
                  TextFormField(
                    controller: usernameController,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 14,
                      color: ColorsManager.gray,
                    ),
                    decoration: InputDecoration(
                      labelText: "Username",
                      labelStyle: GoogleFonts.nunitoSans(
                        color: ColorsManager.gray,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: ColorsManager.gray),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: ColorsManager.greyGreen),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Username is required';
                      }
                      if (v.trim().length < 3) return 'At least 3 characters';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Phone Number
                  TextFormField(
                    controller: phoneController,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 14,
                      color: ColorsManager.gray,
                    ),
                    decoration: InputDecoration(
                      labelText: "Phone Number",
                      labelStyle: GoogleFonts.nunitoSans(
                        color: ColorsManager.gray,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: ColorsManager.gray),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: ColorsManager.greyGreen),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v != null && v.isNotEmpty && v.length < 8) {
                        return 'Invalid phone number';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Role Dropdown
                  DropdownButtonFormField<UserRole>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      labelText: "Role",
                      labelStyle: GoogleFonts.nunitoSans(
                        color: ColorsManager.gray,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: ColorsManager.gray),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: ColorsManager.greyGreen),
                      ),
                    ),
                    onChanged: (role) {
                      if (role != null) {
                        setDialogOnly(() => selectedRole = role);
                      }
                    },
                    items: UserRole.values
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(
                              r.name,
                              style: GoogleFonts.nunitoSans(
                                color: ColorsManager.gray,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 16),

                  // Active Status Switch
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        "Active Status",
                        style: GoogleFonts.nunitoSans(
                          fontWeight: FontWeight.w500,
                          color: ColorsManager.gray,
                        ),
                      ),
                      subtitle: Text(
                        isActive ? "User is active" : "User is inactive",
                        style: GoogleFonts.nunitoSans(
                          color: isActive
                              ? const Color(0xFF4CAF50)
                              : ColorsManager.gray,
                        ),
                      ),
                      value: isActive,
                      onChanged: (val) =>
                          setDialogOnly(() => isActive = val),
                      activeColor: const Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ),
          ),

          actionsPadding: const EdgeInsets.only(right: 16, bottom: 10),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: GoogleFonts.nunitoSans(color: ColorsManager.gray),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.mainBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                if (mounted) setState(() => _isLoading = true);

                final updated = user.copyWith(
                  username: usernameController.text.trim(),
                  phoneNumber: phoneController.text.trim().isEmpty
                      ? null
                      : phoneController.text.trim(),
                  role: selectedRole,
                  isActive: isActive,
                );

                try {
                  await FirestoreService.updateUser(updated);
                  if (mounted) {
                    Navigator.pop(context);
                    _refreshUsers();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User updated successfully'),
                        backgroundColor: ColorsManager.mainBlue,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating user: $e'),
                        backgroundColor: ColorsManager.zhYellow,
                      ),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ColorsManager.lightYellow,
                      ),
                    )
                  : Text(
                      "Save",
                      style: GoogleFonts.nunitoSans(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ======== DELETE ========
  Future<void> _deleteUser(UserModel user) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (user.uid == currentUser?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot delete your own account'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Delete ${user.username}? This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (mounted) setState(() => _isLoading = true);
    try {
      await FirestoreService.deleteUser(user.uid);
      _refreshUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User deleted successfully'),
            backgroundColor: Color.fromARGB(255, 226, 225, 207),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Filter Users',
                  style: GoogleFonts.nunitoSans(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButton<UserRole?>(
                value: _filterRole,
                isExpanded: true,
                hint: Text('Filter by Role', style: GoogleFonts.nunitoSans()),
                onChanged: (role) => setSheetState(() => _filterRole = role),
                items: [
                  DropdownMenuItem(value: null, child: Text('All Roles', style: GoogleFonts.nunitoSans())),
                  ...UserRole.values.map(
                    (r) => DropdownMenuItem<UserRole?>(
                      value: r,
                      child: Text(r.name, style: GoogleFonts.nunitoSans()),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              DropdownButton<bool?>(
                value: _filterActiveStatus,
                isExpanded: true,
                hint: Text('Filter by Status', style: GoogleFonts.nunitoSans()),
                onChanged: (status) => setSheetState(() => _filterActiveStatus = status),
                items: [
                  DropdownMenuItem(value: null, child: Text('All Statuses', style: GoogleFonts.nunitoSans())),
                  DropdownMenuItem(value: true, child: Text('Active Only', style: GoogleFonts.nunitoSans())),
                  DropdownMenuItem(value: false, child: Text('Inactive Only', style: GoogleFonts.nunitoSans())),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filterRole = null;
                        _filterActiveStatus = null;
                      });
                      Navigator.pop(context);
                    },
                    child: Text('Clear', style: GoogleFonts.nunitoSans()),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                      Navigator.pop(context);
                    },
                    child: Text('Apply', style: GoogleFonts.nunitoSans(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.darkBlue,
      appBar: AppBar(
        title: Text("Manage Users",
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            )),
        backgroundColor: ColorsManager.gray,
        foregroundColor: ColorsManager.lightYellow,
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilterBottomSheet),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshUsers),
          if (kDebugMode)
            IconButton(icon: const Icon(Icons.bug_report), onPressed: debugUserRole),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.nunitoSans(),
              decoration: InputDecoration(
                labelText: 'Search users...',
                labelStyle: GoogleFonts.nunitoSans(color: ColorsManager.gray),
                prefixIcon: const Icon(
                  Icons.search,
                  color: ColorsManager.gray,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ColorsManager.gray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: ColorsManager.greyGreen, width: 2),
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final users = snapshot.data ?? [];
                final filtered = _filterUsers(users);
                if (filtered.isEmpty) {
                  return Center(
                      child: Text('No users found', style: GoogleFonts.nunitoSans()));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final u = filtered[i];
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [ColorsManager.gray, ColorsManager.greyGreen],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showEditDialog(u),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: u.isAdmin
                                  ? ColorsManager.mainBlue
                                  : ColorsManager.lightYellow,
                              child: Icon(
                                u.isAdmin
                                    ? Icons.admin_panel_settings
                                    : Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              u.username,
                              style: GoogleFonts.nunitoSans(
                                color: u.isActive
                                    ? Colors.white
                                    : ColorsManager.lightYellow,
                              ),
                            ),
                            subtitle: Text(
                              '${u.email} • ${u.phoneNumber ?? "No phone"}',
                              style: GoogleFonts.nunitoSans(color: Colors.white70),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: ColorsManager.lightYellow),
                                  onPressed: () => _showEditDialog(u),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: ColorsManager.zhYellow),
                                  onPressed: () => _deleteUser(u),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isLoading
          ? const CircularProgressIndicator()
          : FloatingActionButton(
            backgroundColor: ColorsManager.lightYellow, 
              onPressed: _refreshUsers,
              child: const Icon(Icons.refresh, color: ColorsManager.zhYellow),
            ),
    );
  }
}
