// services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> registerDevice(String uniqueId, String userId) async {
    await _db.collection("devices").doc(uniqueId).set({
      "uniqueId": uniqueId,
      "owner": userId,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  // Users collection reference
  static CollectionReference get _usersCollection => _db.collection('users');

  // Admin logs collection reference
  static CollectionReference get _adminLogsCollection =>
      _db.collection('admin_logs');

  // Cache for current user to avoid repeated Firestore calls
  static UserModel? _currentUserCache;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // Create or update user profile
  static Future<void> createOrUpdateUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set(user.toFirestore());

      // Clear cache if updating current user
      if (user.uid == _auth.currentUser?.uid) {
        _clearCache();
      }
    } catch (e) {
      throw Exception('Failed to create/update user: $e');
    }
  }

  // Get user by ID with optional caching
  static Future<UserModel?> getUserById(
    String uid, {
    bool useCache = false,
  }) async {
    try {
      // Use cache for current user if enabled and valid
      if (useCache &&
          uid == _auth.currentUser?.uid &&
          _currentUserCache != null &&
          _cacheTimestamp != null &&
          DateTime.now().difference(_cacheTimestamp!) < _cacheValidDuration) {
        return _currentUserCache;
      }

      DocumentSnapshot doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        final user = UserModel.fromFirestore(doc);

        // Cache current user data
        if (uid == _auth.currentUser?.uid) {
          _currentUserCache = user;
          _cacheTimestamp = DateTime.now();
        }

        return user;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Clear cache
  static void _clearCache() {
    _currentUserCache = null;
    _cacheTimestamp = null;
  }

  // Get current user profile with caching
  static Future<UserModel?> getCurrentUserProfile({
    bool useCache = true,
  }) async {
    User? firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    return await getUserById(firebaseUser.uid, useCache: useCache);
  }

  // Check if current user is admin with caching
  static Future<bool> isCurrentUserAdmin({bool useCache = true}) async {
    UserModel? user = await getCurrentUserProfile(useCache: useCache);
    return user?.isAdmin ?? false;
  }

  // ADMIN FUNCTIONS

  // Get all users with pagination and filtering
  static Future<List<UserModel>> getAllUsers({
    int? limit,
    DocumentSnapshot? startAfter,
    UserRole? roleFilter,
    bool? activeFilter,
  }) async {
    try {
      // Check if current user is admin
      bool isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        throw Exception('Access denied: Admin privileges required');
      }

      Query query = _usersCollection.orderBy('createdAt', descending: true);

      // Apply filters
      if (roleFilter != null) {
        query = query.where('role', isEqualTo: roleFilter.name);
      }
      if (activeFilter != null) {
        query = query.where('isActive', isEqualTo: activeFilter);
      }

      // Apply pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      if (limit != null) {
        query = query.limit(limit);
      }

      QuerySnapshot querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }

  // Enhanced search users with multiple fields and fuzzy matching
  static Future<List<UserModel>> searchUsers(
    String searchTerm, {
    int limit = 50,
    List<String> searchFields = const ['email', 'username', 'phoneNumber'],
  }) async {
    try {
      bool isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        throw Exception('Access denied: Admin privileges required');
      }

      if (searchTerm.isEmpty) {
        return await getAllUsers(limit: limit);
      }

      final searchTermLower = searchTerm.toLowerCase().trim();
      Set<UserModel> users = {};

      // Search by email (case-insensitive)
      if (searchFields.contains('email')) {
        try {
          QuerySnapshot emailQuery = await _usersCollection
              .where('email', isGreaterThanOrEqualTo: searchTermLower)
              .where('email', isLessThan: '${searchTermLower}z')
              .limit(limit)
              .get();

          for (var doc in emailQuery.docs) {
            users.add(UserModel.fromFirestore(doc));
          }
        } catch (e) {
          print('Email search failed: $e');
        }
      }

      // Search by username
      if (searchFields.contains('username')) {
        try {
          QuerySnapshot nameQuery = await _usersCollection
              .where('username', isGreaterThanOrEqualTo: searchTerm)
              .where('username', isLessThan: '${searchTerm}z')
              .limit(limit)
              .get();

          for (var doc in nameQuery.docs) {
            users.add(UserModel.fromFirestore(doc));
          }
        } catch (e) {
          print('Username search failed: $e');
        }
      }

      // Search by phone number
      if (searchFields.contains('phoneNumber')) {
        try {
          QuerySnapshot phoneQuery = await _usersCollection
              .where('phoneNumber', isGreaterThanOrEqualTo: searchTerm)
              .where('phoneNumber', isLessThan: '${searchTerm}z')
              .limit(limit)
              .get();

          for (var doc in phoneQuery.docs) {
            users.add(UserModel.fromFirestore(doc));
          }
        } catch (e) {
          print('Phone search failed: $e');
        }
      }

      // If no specific field searches worked, do a broader search
      if (users.isEmpty) {
        try {
          QuerySnapshot allUsersQuery = await _usersCollection
              .orderBy('createdAt', descending: true)
              .limit(200) // Get more users for client-side filtering
              .get();

          for (var doc in allUsersQuery.docs) {
            try {
              final user = UserModel.fromFirestore(doc);
              if (_userMatchesSearch(user, searchTermLower)) {
                users.add(user);
              }
            } catch (e) {
              print('Error processing user doc: $e');
            }
          }
        } catch (e) {
          print('Broad search failed: $e');
        }
      }

      return users.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  // Helper method for client-side search matching
  static bool _userMatchesSearch(UserModel user, String searchTermLower) {
    return user.email.toLowerCase().contains(searchTermLower) ||
        user.username.toLowerCase().contains(searchTermLower) ||
        (user.phoneNumber.toLowerCase().contains(searchTermLower) ?? false);
  }

  // Update user with optimistic updates and rollback on failure
  static Future<void> updateUser(UserModel user) async {
    try {
      bool isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        throw Exception('Access denied: Admin privileges required');
      }

      // Get original user data for potential rollback
      UserModel? originalUser = await getUserById(user.uid);

      // Update in Firestore
      await _usersCollection.doc(user.uid).update(user.toFirestore());

      // Clear cache if updating current user
      if (user.uid == _auth.currentUser?.uid) {
        _clearCache();
      }

      // Log the action with more details
      await _logAdminAction('update_user', user.uid, {
        'updatedFields': _getUpdatedFields(originalUser, user),
        'newUsername': user.username,
        'newRole': user.role.name,
        'newActiveStatus': user.isActive,
      });
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Helper to identify what fields were changed
  static Map<String, dynamic> _getUpdatedFields(
    UserModel? original,
    UserModel updated,
  ) {
    if (original == null) return {'all': 'new_user'};

    Map<String, dynamic> changes = {};

    if (original.username != updated.username) {
      changes['username'] = {'from': original.username, 'to': updated.username};
    }
    if (original.role != updated.role) {
      changes['role'] = {'from': original.role.name, 'to': updated.role.name};
    }
    if (original.isActive != updated.isActive) {
      changes['isActive'] = {'from': original.isActive, 'to': updated.isActive};
    }
    if (original.phoneNumber != updated.phoneNumber) {
      changes['phoneNumber'] = {
        'from': original.phoneNumber,
        'to': updated.phoneNumber,
      };
    }

    return changes;
  }

  // Update user profile (for current user) with validation
  static Future<void> updateCurrentUserProfile({
    String? displayName,
    String? photoURL,
    String? phoneNumber,
  }) async {
    try {
      User? firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        throw Exception('No authenticated user');
      }

      UserModel? currentUser = await getCurrentUserProfile(useCache: false);
      if (currentUser == null) {
        throw Exception('User profile not found');
      }

      // Validate inputs
      if (displayName != null && displayName.trim().length < 2) {
        throw Exception('Display name must be at least 2 characters');
      }

      // Create updated user model
      UserModel updatedUser = currentUser.copyWith(
        username: displayName?.trim(),
        photoURL: photoURL,
        phoneNumber: phoneNumber?.trim(),
        updatedAt: DateTime.now(), // Fixed: Use DateTime instead of Timestamp
      );

      await _usersCollection
          .doc(firebaseUser.uid)
          .update(updatedUser.toFirestore());
      _clearCache(); // Clear cache after update
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Soft delete user (mark as inactive instead of hard delete)
  static Future<void> deactivateUser(String uid) async {
    try {
      bool isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        throw Exception('Access denied: Admin privileges required');
      }

      // Don't allow deactivating self
      if (uid == _auth.currentUser?.uid) {
        throw Exception('Cannot deactivate your own account');
      }

      // Get user data before deactivation for logging
      UserModel? userToDeactivate = await getUserById(uid);
      if (userToDeactivate == null) {
        throw Exception('User not found');
      }

      await _usersCollection.doc(uid).update({
        'isActive': false,
        'deactivatedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Log the action
      await _logAdminAction('deactivate_user', uid, {
        'userEmail': userToDeactivate.email,
        'userDisplayName': userToDeactivate.username,
        'previouslyActive': userToDeactivate.isActive,
      });
    } catch (e) {
      throw Exception('Failed to deactivate user: $e');
    }
  }

  // Reactivate user
  static Future<void> reactivateUser(String uid) async {
    try {
      bool isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        throw Exception('Access denied: Admin privileges required');
      }

      UserModel? userToReactivate = await getUserById(uid);
      if (userToReactivate == null) {
        throw Exception('User not found');
      }

      await _usersCollection.doc(uid).update({
        'isActive': true,
        'reactivatedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Log the action
      await _logAdminAction('reactivate_user', uid, {
        'userEmail': userToReactivate.email,
        'userDisplayName': userToReactivate.username,
      });
    } catch (e) {
      throw Exception('Failed to reactivate user: $e');
    }
  }

  // Hard delete user (admin only) - use with caution
  static Future<void> deleteUser(String uid) async {
    try {
      bool isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        throw Exception('Access denied: Admin privileges required');
      }

      // Don't allow deleting self
      if (uid == _auth.currentUser?.uid) {
        throw Exception('Cannot delete your own account');
      }

      // Get user data before deletion for logging
      UserModel? userToDelete = await getUserById(uid);

      await _usersCollection.doc(uid).delete();

      // Log the action
      await _logAdminAction('delete_user', uid, {
        'deletedUserEmail': userToDelete?.email,
        'deletedUserDisplayName': userToDelete?.username,
        'deletedUserRole': userToDelete?.role.name,
      });
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // Update user role with additional validation
  static Future<void> updateUserRole(String uid, UserRole newRole) async {
    try {
      // Don't allow changing own role
      if (uid == _auth.currentUser?.uid) {
        throw Exception('Cannot change your own role');
      }

      // Get current user data
      UserModel? currentUser = await getUserById(uid);
      if (currentUser == null) {
        throw Exception('User not found');
      }

      await _usersCollection.doc(uid).update({
        'role': newRole.name,
        'updatedAt': Timestamp.now(),
      });

      // Log the action
      await _logAdminAction('update_user_role', uid, {
        'oldRole': currentUser.role.name,
        'newRole': newRole.name,
        'userEmail': currentUser.email,
      });
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  // Get users by role with pagination
  static Future<List<UserModel>> getUsersByRole(
    UserRole role, {
    int? limit,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      bool isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        throw Exception('Access denied: Admin privileges required');
      }

      Query query = _usersCollection
          .where('role', isEqualTo: role.name)
          .orderBy('createdAt', descending: true);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      if (limit != null) {
        query = query.limit(limit);
      }

      QuerySnapshot querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get users by role: $e');
    }
  }

  // Get all admins
  static Future<List<UserModel>> getAllAdmins() async {
    try {
      bool isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        throw Exception('Access denied: Admin privileges required');
      }

      QuerySnapshot querySnapshot = await _usersCollection
          .where(
            'role',
            whereIn: [UserRole.admin.name],
          )
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get admins: $e');
    }
  }

  // Update last login time
  static Future<void> updateLastLogin() async {
    User? firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      try {
        await _usersCollection.doc(firebaseUser.uid).update({
          'lastLoginAt': Timestamp.now(),
        });
        _clearCache(); // Clear cache after update
      } catch (e) {
        print('Failed to update last login: $e');
        // Don't throw - this is not critical
      }
    }
  }

  // Update email verification status
  static Future<void> updateEmailVerificationStatus(
    String uid,
    bool isVerified,
  ) async {
    try {
      await _usersCollection.doc(uid).update({
        'isEmailVerified': isVerified,
        'updatedAt': Timestamp.now(),
      });

      // Clear cache if updating current user
      if (uid == _auth.currentUser?.uid) {
        _clearCache();
      }
    } catch (e) {
      throw Exception('Failed to update email verification status: $e');
    }
  }

  // Enhanced user statistics with more metrics
  static Future<Map<String, int>> getUserStatistics() async {
    try {
      bool isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        throw Exception('Access denied: Admin privileges required');
      }

      // Get all users in one query for better performance
      QuerySnapshot allUsersQuery = await _usersCollection.get();

      final stats = <String, int>{
        'total': 0,
        'active': 0,
        'inactive': 0,
        'admins': 0,
        'users': 0,
        'verified': 0,
        'unverified': 0,
        'recentlyActive': 0, // Last 30 days
      };

      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      for (var doc in allUsersQuery.docs) {
        try {
          final user = UserModel.fromFirestore(doc);
          stats['total'] = stats['total']! + 1;

          // Active/Inactive
          if (user.isActive) {
            stats['active'] = stats['active']! + 1;
          } else {
            stats['inactive'] = stats['inactive']! + 1;
          }

          // Roles - Fixed: Added all UserRole cases
          switch (user.role) {
            case UserRole.admin:
              stats['admins'] = stats['admins']! + 1;
              break;
            case UserRole.user:
              stats['users'] = stats['users']! + 1;
              break;
          }

          // Email verification
          if (user.isEmailVerified) {
            stats['verified'] = stats['verified']! + 1;
          } else {
            stats['unverified'] = stats['unverified']! + 1;
          }

          // Recently active (last 30 days) - Fixed: Check for null and convert properly
          if (user.lastLoginAt != null) {
            DateTime lastLoginDateTime;
            if (user.lastLoginAt is Timestamp) {
              lastLoginDateTime = (user.lastLoginAt as Timestamp).toDate();
            } else if (user.lastLoginAt is DateTime) {
              lastLoginDateTime = user.lastLoginAt as DateTime;
            } else {
              continue; // Skip if we can't convert
            }

            if (lastLoginDateTime.isAfter(thirtyDaysAgo)) {
              stats['recentlyActive'] = stats['recentlyActive']! + 1;
            }
          }
        } catch (e) {
          print('Error processing user stats for doc ${doc.id}: $e');
        }
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get user statistics: $e');
    }
  }

  // ADMIN LOGGING - Enhanced

  // Log admin actions with more context
  static Future<void> _logAdminAction(
    String action,
    String targetUserId,
    Map<String, dynamic> details,
  ) async {
    try {
      String? adminId = _auth.currentUser?.uid;

      // Get admin user info for better logging
      UserModel? adminUser = await getCurrentUserProfile();

      await _adminLogsCollection.add({
        'adminId': adminId,
        'adminEmail': adminUser?.email,
        'adminUsername': adminUser?.username,
        'action': action,
        'targetUserId': targetUserId,
        'timestamp': Timestamp.now(),
        'details': details,
        'userAgent':
            'Ecoknight', // You could enhance this with actual device info
      });
    } catch (e) {
      // Log error but don't throw - don't break the main operation
      print('Failed to log admin action: $e');
    }
  }

  // Get admin logs with better filtering
  static Future<List<Map<String, dynamic>>> getAdminLogs({
    int limit = 100,
    String? adminId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      bool isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        throw Exception('Access denied: Admin privileges required');
      }

      Query query = _adminLogsCollection.orderBy('timestamp', descending: true);

      // Apply filters
      if (adminId != null) {
        query = query.where('adminId', isEqualTo: adminId);
      }
      if (action != null) {
        query = query.where('action', isEqualTo: action);
      }
      if (startDate != null) {
        query = query.where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }
      if (endDate != null) {
        query = query.where(
          'timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      QuerySnapshot querySnapshot = await query.limit(limit).get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      throw Exception('Failed to get admin logs: $e');
    }
  }

  // Health check - verify service is working
  static Future<bool> healthCheck() async {
    try {
      // Simple query to test connectivity
      await _usersCollection.limit(1).get();
      return true;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  // Clear all caches (useful for testing or memory management)
  static void clearAllCaches() {
    _clearCache();
  }
}
