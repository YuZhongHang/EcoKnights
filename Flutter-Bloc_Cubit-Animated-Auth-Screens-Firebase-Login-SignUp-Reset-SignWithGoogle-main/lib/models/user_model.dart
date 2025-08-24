import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String? phoneNumber;
  final UserRole role;
  final bool isActive;
  final bool isEmailVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;
  final DateTime? deactivatedAt;
  final DateTime? reactivatedAt;
  final String? photoURL;
  final Map<String, dynamic>? metadata;
  final List<String>? permissions;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.phoneNumber,
    this.role = UserRole.user,
    this.isActive = true,
    this.isEmailVerified = false,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.deactivatedAt,
    this.reactivatedAt,
    this.photoURL,
    this.metadata,
    this.permissions,
  });

  // Enhanced fromFirestore with extensive debugging
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>?;

      if (data == null) {
        debugPrint('❌ [UserModel] Document data is null for document ${doc.id}');
        throw Exception('Document data is null for document ${doc.id}');
      }

      debugPrint('🔍 [UserModel] Raw Firestore data for ${doc.id}: $data');

      // Validate required fields
      if (!data.containsKey('email') || data['email'] == null || (data['email'] as String).isEmpty) {
        debugPrint('❌ [UserModel] Missing required field: email');
        throw Exception('Missing required field: email');
      }

      // Debug role parsing specifically
      final roleValue = data['role'];
      debugPrint('🔍 [UserModel] Raw role value: $roleValue (type: ${roleValue.runtimeType})');
      
      final parsedRole = UserRole.fromString(roleValue);
      debugPrint('🔍 [UserModel] Parsed role: $parsedRole');
      debugPrint('🔍 [UserModel] Role name: ${parsedRole.name}');
      debugPrint('🔍 [UserModel] Role display name: ${parsedRole.displayName}');

      final userModel = UserModel(
        uid: data['uid'] ?? doc.id,
        email: _validateAndSanitizeEmail(data['email']),
        username: _validateAndSanitizeString(data['username'], 'username', minLength: 1),
        phoneNumber: _sanitizePhoneNumber(data['phoneNumber']),
        role: parsedRole,
        isActive: data['isActive'] ?? true,
        isEmailVerified: data['isEmailVerified'] ?? false,
        createdAt: _parseTimestamp(data['createdAt']),
        updatedAt: _parseTimestamp(data['updatedAt']),
        lastLoginAt: _parseTimestamp(data['lastLoginAt']),
        deactivatedAt: _parseTimestamp(data['deactivatedAt']),
        reactivatedAt: _parseTimestamp(data['reactivatedAt']),
        photoURL: _sanitizeUrl(data['photoURL']),
        metadata: _parseMetadata(data['metadata']),
        permissions: _parsePermissions(data['permissions']),
      );

      // Debug the final UserModel
      debugPrint('✅ [UserModel] Created UserModel:');
      debugPrint('   UID: ${userModel.uid}');
      debugPrint('   Email: ${userModel.email}');
      debugPrint('   Role: ${userModel.role}');
      debugPrint('   Role Name: ${userModel.role.name}');
      debugPrint('   isAdmin: ${userModel.isAdmin}');
      debugPrint('   isActive: ${userModel.isActive}');

      return userModel;
    } catch (e, stack) {
      debugPrint('❌ [UserModel] Failed to parse UserModel from Firestore document ${doc.id}: $e');
      debugPrint('Stack: $stack');
      throw Exception('Failed to parse UserModel from Firestore document ${doc.id}: $e\nStack: $stack');
    }
  }

  // Helper methods (keeping your existing ones)
  static String _validateAndSanitizeEmail(dynamic email) {
    if (email == null) throw Exception('Email cannot be null');
    final emailStr = email.toString().trim().toLowerCase();
    if (emailStr.isEmpty) throw Exception('Email cannot be empty');
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(emailStr)) {
      throw Exception('Invalid email format: $emailStr');
    }
    return emailStr;
  }

  static String _validateAndSanitizeString(dynamic value, String fieldName, {int minLength = 0, int maxLength = 255}) {
    if (value == null) return '';
    final str = value.toString().trim();
    if (str.length < minLength) {
      throw Exception('$fieldName must be at least $minLength characters');
    }
    if (str.length > maxLength) {
      throw Exception('$fieldName cannot exceed $maxLength characters');
    }
    return str;
  }

  static String? _sanitizePhoneNumber(dynamic phone) {
    if (phone == null) return null;
    final phoneStr = phone.toString().trim();
    if (phoneStr.isEmpty) return null;
    
    final cleanedPhone = phoneStr.replaceAll(RegExp(r'[^\d+\-\s\(\)]'), '');
    if (cleanedPhone.length < 8) return null;
    
    return cleanedPhone;
  }

  static String? _sanitizeUrl(dynamic url) {
    if (url == null) return null;
    final urlStr = url.toString().trim();
    if (urlStr.isEmpty) return null;
    
    if (!RegExp(r'^https?://').hasMatch(urlStr)) {
      return null;
    }
    
    return urlStr;
  }

  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Map<String, dynamic>? _parseMetadata(dynamic metadata) {
    if (metadata == null) return null;
    if (metadata is Map<String, dynamic>) return metadata;
    return null;
  }

  static List<String>? _parsePermissions(dynamic permissions) {
    if (permissions == null) return null;
    if (permissions is List) {
      return permissions.map((e) => e.toString()).toList();
    }
    return null;
  }

  // Factory constructor for creating new users
  factory UserModel.create({
    required String uid,
    required String email,
    required String username,
    String? phoneNumber,
    UserRole role = UserRole.user,
    bool isEmailVerified = false,
    String? photoURL,
    Map<String, dynamic>? metadata,
    List<String>? permissions,
  }) {
    final now = DateTime.now();
    return UserModel(
      uid: uid,
      email: email.trim().toLowerCase(),
      username: username.trim(),
      phoneNumber: phoneNumber?.trim(),
      role: role,
      isActive: true,
      isEmailVerified: isEmailVerified,
      createdAt: now,
      updatedAt: now,
      photoURL: photoURL?.trim(),
      metadata: metadata,
      permissions: permissions,
    );
  }

  // FIXED: Consistent role storage
  Map<String, dynamic> toFirestore() {
    final data = <String, dynamic>{
      'uid': uid,
      'email': email,
      'username': username,
      'role': role.name, // FIXED: Use role.name instead of role.name.toLowerCase()
      'isActive': isActive,
      'isEmailVerified': isEmailVerified,
      'updatedAt': Timestamp.now(),
    };

    debugPrint('🔍 [UserModel] toFirestore() role value: ${role.name}');

    // Only include non-null values
    if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
    if (createdAt != null) data['createdAt'] = Timestamp.fromDate(createdAt!);
    if (lastLoginAt != null) data['lastLoginAt'] = Timestamp.fromDate(lastLoginAt!);
    if (deactivatedAt != null) data['deactivatedAt'] = Timestamp.fromDate(deactivatedAt!);
    if (reactivatedAt != null) data['reactivatedAt'] = Timestamp.fromDate(reactivatedAt!);
    if (photoURL != null) data['photoURL'] = photoURL;
    if (metadata != null) data['metadata'] = metadata;
    if (permissions != null) data['permissions'] = permissions;

    return data;
  }

  // Your existing copyWith method
  UserModel copyWith({
    String? email,
    String? username,
    String? phoneNumber,
    UserRole? role,
    bool? isActive,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    DateTime? deactivatedAt,
    DateTime? reactivatedAt,
    String? photoURL,
    Map<String, dynamic>? metadata,
    List<String>? permissions,
    bool clearPhoneNumber = false,
    bool clearPhotoURL = false,
    bool clearMetadata = false,
    bool clearPermissions = false,
    bool clearDeactivatedAt = false,
    bool clearReactivatedAt = false,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      username: username ?? this.username,
      phoneNumber: clearPhoneNumber ? null : (phoneNumber ?? this.phoneNumber),
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      deactivatedAt: clearDeactivatedAt ? null : (deactivatedAt ?? this.deactivatedAt),
      reactivatedAt: clearReactivatedAt ? null : (reactivatedAt ?? this.reactivatedAt),
      photoURL: clearPhotoURL ? null : (photoURL ?? this.photoURL),
      metadata: clearMetadata ? null : (metadata ?? this.metadata),
      permissions: clearPermissions ? null : (permissions ?? this.permissions),
    );
  }

  // Your existing validation methods
  bool get hasValidEmail => email.isNotEmpty && RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  bool get hasValidUsername => username.isNotEmpty && username.length >= 2 && username.length <= 50;
  bool get hasValidPhoneNumber => phoneNumber == null || (phoneNumber!.isNotEmpty && phoneNumber!.length >= 8);
  
  bool get isValid => hasValidEmail && hasValidUsername && hasValidPhoneNumber;

  bool get isCompleteProfile => hasValidEmail && hasValidUsername && (phoneNumber?.isNotEmpty ?? false);
  bool get isRecentlyCreated => createdAt != null && DateTime.now().difference(createdAt!).inDays < 7;
  bool get isRecentlyActive => lastLoginAt != null && DateTime.now().difference(lastLoginAt!).inDays < 30;
  bool get hasProfilePhoto => photoURL != null && photoURL!.isNotEmpty;

  // ENHANCED: Role checking methods with debugging
  bool get isAdmin {
    final result = role == UserRole.admin || role == UserRole.superAdmin;
    debugPrint('🔍 [UserModel] isAdmin check: role=$role, isAdmin=$result');
    return result;
  }
  
  bool get isSuperAdmin {
    final result = role == UserRole.superAdmin;
    debugPrint('🔍 [UserModel] isSuperAdmin check: role=$role, isSuperAdmin=$result');
    return result;
  }
  
  bool get isUser => role == UserRole.user;
  bool get isModerator => role == UserRole.moderator;

  // Your existing permission methods
  bool hasPermission(String permission) {
    if (isSuperAdmin) return true;
    return permissions?.contains(permission) ?? false;
  }

  bool hasAnyPermission(List<String> requiredPermissions) {
    if (isSuperAdmin) return true;
    if (permissions == null) return false;
    return requiredPermissions.any((permission) => permissions!.contains(permission));
  }

  bool hasAllPermissions(List<String> requiredPermissions) {
    if (isSuperAdmin) return true;
    if (permissions == null) return false;
    return requiredPermissions.every((permission) => permissions!.contains(permission));
  }

  // Your existing display methods
  String get displayName => username.isNotEmpty ? username : email.split('@').first;
  String get initials {
    if (username.isNotEmpty) {
      final parts = username.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return username.substring(0, 1).toUpperCase();
    }
    return email.substring(0, 1).toUpperCase();
  }

  String get roleDisplayName => role.displayName;

  String get statusText {
    if (!isActive && deactivatedAt != null) return 'Deactivated';
    if (!isActive) return 'Inactive';
    if (!isEmailVerified) return 'Email Unverified';
    return 'Active';
  }

  Duration? get accountAge => createdAt != null ? DateTime.now().difference(createdAt!) : null;
  Duration? get timeSinceLastLogin => lastLoginAt != null ? DateTime.now().difference(lastLoginAt!) : null;

  Map<String, dynamic> toJson() => toFirestore();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      phoneNumber: json['phoneNumber'],
      role: UserRole.fromString(json['role']),
      isActive: json['isActive'] ?? true,
      isEmailVerified: json['isEmailVerified'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      lastLoginAt: json['lastLoginAt'] != null ? DateTime.parse(json['lastLoginAt']) : null,
      deactivatedAt: json['deactivatedAt'] != null ? DateTime.parse(json['deactivatedAt']) : null,
      reactivatedAt: json['reactivatedAt'] != null ? DateTime.parse(json['reactivatedAt']) : null,
      photoURL: json['photoURL'],
      metadata: json['metadata'],
      permissions: json['permissions'] != null ? List<String>.from(json['permissions']) : null,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, username: $username, role: ${role.name}, '
           'isActive: $isActive, isEmailVerified: $isEmailVerified, '
           'createdAt: $createdAt, lastLoginAt: $lastLoginAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.uid == uid &&
        other.email == email &&
        other.username == username &&
        other.phoneNumber == phoneNumber &&
        other.role == role &&
        other.isActive == isActive &&
        other.isEmailVerified == isEmailVerified;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        email.hashCode ^
        username.hashCode ^
        (phoneNumber?.hashCode ?? 0) ^
        role.hashCode ^
        isActive.hashCode ^
        isEmailVerified.hashCode;
  }

  // Your existing utility methods
  UserModel markAsVerified() => copyWith(isEmailVerified: true);
  UserModel markAsUnverified() => copyWith(isEmailVerified: false);
  UserModel deactivate() => copyWith(isActive: false, deactivatedAt: DateTime.now());
  UserModel reactivate() => copyWith(
    isActive: true, 
    reactivatedAt: DateTime.now(), 
    clearDeactivatedAt: true
  );
  UserModel updateLastLogin() => copyWith(lastLoginAt: DateTime.now());
  UserModel changeRole(UserRole newRole) => copyWith(role: newRole);
  UserModel addPermission(String permission) {
    final currentPermissions = permissions ?? [];
    if (!currentPermissions.contains(permission)) {
      return copyWith(permissions: [...currentPermissions, permission]);
    }
    return this;
  }
  UserModel removePermission(String permission) {
    if (permissions == null) return this;
    final newPermissions = permissions!.where((p) => p != permission).toList();
    return copyWith(permissions: newPermissions);
  }
}

// ENHANCED: UserRole enum with better parsing
enum UserRole {
  user('User'),
  moderator('Moderator'),
  admin('Admin'),
  superAdmin('Super Admin');

  const UserRole(this.displayName);
  final String displayName;

  List<String> get defaultPermissions {
    switch (this) {
      case UserRole.user:
        return ['read_profile', 'update_profile'];
      case UserRole.moderator:
        return [
          'read_profile', 'update_profile',
          'view_users', 'moderate_content',
        ];
      case UserRole.admin:
        return [
          'read_profile', 'update_profile',
          'view_users', 'manage_users', 'moderate_content',
          'view_analytics', 'manage_settings',
        ];
      case UserRole.superAdmin:
        return ['*'];
    }
  }

  bool canPromoteTo(UserRole targetRole) {
    switch (this) {
      case UserRole.superAdmin:
        return true;
      case UserRole.admin:
        return targetRole == UserRole.user || targetRole == UserRole.moderator;
      case UserRole.moderator:
        return targetRole == UserRole.user;
      case UserRole.user:
        return false;
    }
  }

  bool canDemoteFrom(UserRole sourceRole) {
    switch (this) {
      case UserRole.superAdmin:
        return sourceRole != UserRole.superAdmin;
      case UserRole.admin:
        return sourceRole == UserRole.moderator || sourceRole == UserRole.user;
      case UserRole.moderator:
        return sourceRole == UserRole.user;
      case UserRole.user:
        return false;
    }
  }

  // ENHANCED: Better role parsing with debugging
  static UserRole fromString(String? roleString) {
    debugPrint('🔍 [UserRole] Parsing role string: "$roleString"');
    
    if (roleString == null || roleString.isEmpty) {
      debugPrint('🔍 [UserRole] Null/empty role, defaulting to user');
      return UserRole.user;
    }
    
    final normalizedRole = roleString.toLowerCase().trim();
    debugPrint('🔍 [UserRole] Normalized role: "$normalizedRole"');
    
    UserRole result;
    switch (normalizedRole) {
      case 'moderator':
      case 'mod':
        result = UserRole.moderator;
        break;
      case 'admin':
      case 'administrator':
        result = UserRole.admin;
        break;
      case 'superadmin': // FIXED: This should match what's stored
      case 'super_admin':
      case 'super admin':
      case 'root':
        result = UserRole.superAdmin;
        break;
      case 'user':
      default:
        result = UserRole.user;
        break;
    }
    
    debugPrint('🔍 [UserRole] Parsed result: $result (name: ${result.name})');
    return result;
  }

  List<UserRole> get manageableRoles {
    switch (this) {
      case UserRole.superAdmin:
        return [UserRole.user, UserRole.moderator, UserRole.admin];
      case UserRole.admin:
        return [UserRole.user, UserRole.moderator];
      case UserRole.moderator:
        return [UserRole.user];
      case UserRole.user:
        return [];
    }
  }

  bool canManage(UserRole targetRole) {
    return manageableRoles.contains(targetRole);
  }
}