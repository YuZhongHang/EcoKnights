import 'package:auth_bloc/theming/colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import 'package:flutter/foundation.dart';
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

  // Enhanced debug function with better formatting
  Future<void> debugUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('=== DEBUG USER ROLE (AdminUserManagement) ===');

    if (user != null) {
      debugPrint('Current user UID: ${user.uid}');
      debugPrint('Current user email: ${user.email}');

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          debugPrint('Document exists: ${userDoc.data()}');

          final userModel = UserModel.fromFirestore(userDoc);
          debugPrint('User role: ${userModel.role}');
          debugPrint('Role name: ${userModel.role.name}');
          debugPrint('Is admin: ${userModel.isAdmin}');
          debugPrint('Is active: ${userModel.isActive}');
          debugPrint('Username: ${userModel.username}');
        } else {
          debugPrint('ERROR: User document does not exist in Firestore!');
          debugPrint('Expected document path: users/${user.uid}');
        }
      } catch (e) {
        debugPrint('ERROR loading user document: $e');
      }
    } else {
      debugPrint('ERROR: No authenticated user found!');
    }
    debugPrint('=== END DEBUG ===');
  }

  void _refreshUsers() {
    setState(() {
      _usersFuture = FirestoreService.getAllUsers();
    });
  }

  // Enhanced search and filter functionality
  List<UserModel> _filterUsers(List<UserModel> users) {
    return users.where((user) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          user.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (user.phoneNumber
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ??
              false);

      // Role filter
      final matchesRole = _filterRole == null || user.role == _filterRole;

      // Active status filter
      final matchesActiveStatus =
          _filterActiveStatus == null || user.isActive == _filterActiveStatus;

      return matchesSearch && matchesRole && matchesActiveStatus;
    }).toList();
  }

  void _showEditDialog(UserModel user) {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController(text: user.username);
    final phoneController = TextEditingController(text: user.phoneNumber ?? '');
    UserRole selectedRole = user.role;
    bool isActive = user.isActive;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Username is required';
                      }
                      if (value.trim().length < 3) {
                        return 'Username must be at least 3 characters';
                      }
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
                    validator: (value) {
                      if (value != null &&
                          value.isNotEmpty &&
                          value.length < 8) {
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
                        setDialogState(() {
                          selectedRole = role;
                        });
                      }
                    },
                    items: UserRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role.name),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: SwitchListTile(
                      title: const Text("Active Status"),
                      subtitle: Text(
                          isActive ? "User is active" : "User is inactive"),
                      value: isActive,
                      onChanged: (val) {
                        setDialogState(() {
                          isActive = val;
                        });
                      },
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
                if (formKey.currentState!.validate()) {
                  try {
                    setState(() => _isLoading = true);

                    final updatedUser = user.copyWith(
                      username: usernameController.text.trim(),
                      phoneNumber: phoneController.text.trim().isEmpty
                          ? null
                          : phoneController.text.trim(),
                      role: selectedRole,
                      isActive: isActive,
                    );

                    await FirestoreService.updateUser(updatedUser);

                    if (mounted) {
                      Navigator.pop(context);
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

  void _deleteUser(UserModel user) async {
    // Prevent deleting current user or other admins (optional safety check)
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Are you sure you want to delete this user?"),
            const SizedBox(height: 8),
            Text("Username: ${user.username}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("Email: ${user.email}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              "This action cannot be undone!",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _isLoading = true);
        await FirestoreService.deleteUser(user.uid);
        _refreshUsers();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User deleted successfully'),
              backgroundColor: Colors.green,
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
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Users',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Role filter
              const Text('Filter by Role:'),
              DropdownButton<UserRole?>(
                value: _filterRole,
                isExpanded: true,
                onChanged: (role) {
                  setSheetState(() => _filterRole = role);
                },
                items: [
                  const DropdownMenuItem<UserRole?>(
                    value: null,
                    child: Text('All Roles'),
                  ),
                  ...UserRole.values.map((role) {
                    return DropdownMenuItem<UserRole?>(
                      value: role,
                      child: Text(role.name),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),

              // Active status filter
              const Text('Filter by Status:'),
              DropdownButton<bool?>(
                value: _filterActiveStatus,
                isExpanded: true,
                onChanged: (status) {
                  setSheetState(() => _filterActiveStatus = status);
                },
                items: const [
                  DropdownMenuItem<bool?>(
                    value: null,
                    child: Text('All Statuses'),
                  ),
                  DropdownMenuItem<bool?>(
                    value: true,
                    child: Text('Active Only'),
                  ),
                  DropdownMenuItem<bool?>(
                    value: false,
                    child: Text('Inactive Only'),
                  ),
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
                    child: const Text('Clear Filters'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Refresh with new filters
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
        title: Text("Manage Users", style: TextStyles.adminDashboardTitle,),
        backgroundColor: ColorsManager.gray,
        foregroundColor: ColorsManager.lightYellow,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
            tooltip: "Filter Users",
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshUsers,
            tooltip: "Refresh",
          ),
          if (kDebugMode) // Only show debug button in debug mode
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: debugUserRole,
              tooltip: "Debug User Role",
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search users...',
                labelStyle: const TextStyle(color: ColorsManager.lightYellow), // Label text color
                hintText: 'Search by username, email, or phone',
                hintStyle: const TextStyle(color: ColorsManager.greyGreen),  // Hint text color
                prefixIcon: const Icon(Icons.search, color: ColorsManager.lightYellow),
                border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0), // Rounded corners
                borderSide: const BorderSide(color: ColorsManager.gray), // Border color
                ),
                enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: ColorsManager.gray),
                ),
                focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: ColorsManager.greyGreen, width: 2.0), // Border when focused
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
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Active filters display
          if (_filterRole != null || _filterActiveStatus != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Text('Filters: '),
                  if (_filterRole != null)
                    Chip(
                      label: Text(_filterRole!.name),
                      onDeleted: () => setState(() => _filterRole = null),
                    ),
                  if (_filterActiveStatus != null)
                    Chip(
                      label: Text(_filterActiveStatus! ? 'Active' : 'Inactive'),
                      onDeleted: () =>
                          setState(() => _filterActiveStatus = null),
                    ),
                ],
              ),
            ),

          // Users list
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text("Error: ${snapshot.error}"),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshUsers,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("No users found"),
                      ],
                    ),
                  );
                }

                final allUsers = snapshot.data!;
                final filteredUsers = _filterUsers(allUsers);

                if (filteredUsers.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("No users match your search criteria"),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), 
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [ColorsManager.greyGreen, ColorsManager.gray],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Card(
                        color: Colors.transparent, 
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                            user.isAdmin ? ColorsManager.mainBlue : ColorsManager.lightYellow,
                            child: Icon(
                              user.isAdmin
                                ? Icons.admin_panel_settings
                                : Icons.person,
                            color: 
                              user.isAdmin ? Colors.white : ColorsManager.darkBlue,
                            ),
                          ),
                          title: Text(
                            user.username,
                            style: TextStyles.adminManageUser.copyWith (
                              color: user.isActive ? ColorsManager.darkBlue : ColorsManager.lightYellow,
                              )
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            Text(
                                "${user.email} • ${user.phoneNumber ?? 'No phone'}",
                                style: TextStyle(
                                  color: ColorsManager.mainBlue
                                )
                                ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        user.isAdmin ? ColorsManager.mainBlue : ColorsManager.lightYellow,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    user.role.name,
                                    style: TextStyle(
                                      color: 
                                        user.isAdmin ? Colors.white : ColorsManager.darkBlue,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: user.isActive
                                        ? Colors.green
                                        : ColorsManager.lightYellow,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    user.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      color: user.isActive
                                      ? Colors.white
                                      : ColorsManager.darkBlue,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: ColorsManager.lightYellow),
                              onPressed: () => _showEditDialog(user),
                              tooltip: 'Edit User',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: ColorsManager.zhYellow),
                              onPressed: () => _deleteUser(user),
                              tooltip: 'Delete User',
                            ),
                          ],
                        ),
                      ),
                      )
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
              tooltip: 'Refresh Users',
              child: const Icon(Icons.refresh),
            ),
    );
  }
}
