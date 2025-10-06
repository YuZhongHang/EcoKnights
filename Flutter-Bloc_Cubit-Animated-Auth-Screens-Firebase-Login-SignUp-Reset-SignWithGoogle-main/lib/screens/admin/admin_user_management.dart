import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  bool _isLoading = false; // Global loading for Save/Delete

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
          (user.phoneNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

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
          title: Text("Edit User: ${user.email}"),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: "Username",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Username is required';
                      if (v.trim().length < 3) return 'At least 3 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: "Phone Number",
                      border: OutlineInputBorder(),
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
                  DropdownButtonFormField<UserRole>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: "Role",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (role) {
                      if (role != null) {
                        setDialogOnly(() => selectedRole = role);
                      }
                    },
                    items: UserRole.values
                        .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: SwitchListTile(
                      title: const Text("Active Status"),
                      subtitle: Text(isActive ? "User is active" : "User is inactive"),
                      value: isActive,
                      onChanged: (val) => setDialogOnly(() => isActive = val),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
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
                    Navigator.pop(context); // close dialog
                    _refreshUsers();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating user: $e'),
                        backgroundColor: Colors.red,
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
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Save"),
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
          const SnackBar(content: Text('User deleted successfully'), backgroundColor: Color.fromARGB(255, 226, 225, 207)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting user: $e'), backgroundColor: Colors.red),
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
              const Text('Filter Users', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButton<UserRole?>(
                value: _filterRole,
                isExpanded: true,
                hint: const Text('Filter by Role'),
                onChanged: (role) => setSheetState(() => _filterRole = role),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Roles')),
                  ...UserRole.values
                      .map((r) => DropdownMenuItem<UserRole?>(value: r, child: Text(r.name)))
                ],
              ),
              const SizedBox(height: 16),
              DropdownButton<bool?>(
                value: _filterActiveStatus,
                isExpanded: true,
                hint: const Text('Filter by Status'),
                onChanged: (status) => setSheetState(() => _filterActiveStatus = status),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Statuses')),
                  DropdownMenuItem(value: true, child: Text('Active Only')),
                  DropdownMenuItem(value: false, child: Text('Inactive Only')),
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
                    child: const Text('Clear'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // refresh with filters
                      Navigator.pop(context);
                    },
                    child: const Text('Apply'),
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
        title: Text("Manage Users", style: TextStyles.adminDashboardTitle),
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
              decoration: InputDecoration(
                labelText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                  return const Center(child: Text('No users found'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final u = filtered[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: u.isAdmin
                            ? ColorsManager.mainBlue
                            : ColorsManager.lightYellow,
                        child: Icon(
                          u.isAdmin ? Icons.admin_panel_settings : Icons.person,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(u.username,
                          style: TextStyle(
                              color: u.isActive
                                  ? Colors.white
                                  : ColorsManager.lightYellow)),
                      subtitle: Text('${u.email} • ${u.phoneNumber ?? "No phone"}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: ColorsManager.lightYellow),
                            onPressed: () => _showEditDialog(u),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteUser(u),
                          ),
                        ],
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
              onPressed: _refreshUsers,
              child: const Icon(Icons.refresh),
            ),
    );
  }
}
