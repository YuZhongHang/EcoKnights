import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String phoneNumber; // 👈 changed: no longer nullable
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

  /// 🔹 Convenience getters for role checks
  bool get isAdmin => role == UserRole.admin || role == UserRole.superAdmin;
  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isModerator => role == UserRole.moderator;
  bool get isUser => role == UserRole.user;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.phoneNumber = "", // 👈 default empty string if not set
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

  /// 🔹 Parse Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return UserModel(
      uid: data['uid'] ?? doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      phoneNumber: data['phoneNumber'] ?? "", // 👈 always include
      role: UserRole.fromString(data['role']),
      isActive: data['isActive'] ?? true,
      isEmailVerified: data['isEmailVerified'] ?? false,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      lastLoginAt: _parseTimestamp(data['lastLoginAt']),
      deactivatedAt: _parseTimestamp(data['deactivatedAt']),
      reactivatedAt: _parseTimestamp(data['reactivatedAt']),
      photoURL: data['photoURL'],
      metadata: data['metadata'],
      permissions: data['permissions'] != null
          ? List<String>.from(data['permissions'])
          : null,
    );
  }

  /// 🔹 For new user creation
  factory UserModel.create({
    required String uid,
    required String email,
    required String username,
    String phoneNumber = "", // 👈 default included
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
      phoneNumber: phoneNumber.trim(),
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

  /// 🔹 Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    final data = <String, dynamic>{
      'uid': uid,
      'email': email,
      'username': username,
      'phoneNumber': phoneNumber, // 👈 always written to Firestore
      'role': role.name,
      'isActive': isActive,
      'isEmailVerified': isEmailVerified,
      'updatedAt': Timestamp.now(),
    };

    if (createdAt != null) data['createdAt'] = Timestamp.fromDate(createdAt!);
    if (lastLoginAt != null) {
      data['lastLoginAt'] = Timestamp.fromDate(lastLoginAt!);
    }
    if (deactivatedAt != null) {
      data['deactivatedAt'] = Timestamp.fromDate(deactivatedAt!);
    }
    if (reactivatedAt != null) {
      data['reactivatedAt'] = Timestamp.fromDate(reactivatedAt!);
    }
    if (photoURL != null) data['photoURL'] = photoURL;
    if (metadata != null) data['metadata'] = metadata;
    if (permissions != null) data['permissions'] = permissions;

    return data;
  }

  /// 🔹 Copy with
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
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber, // 👈 never null
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      deactivatedAt: deactivatedAt ?? this.deactivatedAt,
      reactivatedAt: reactivatedAt ?? this.reactivatedAt,
      photoURL: photoURL ?? this.photoURL,
      metadata: metadata ?? this.metadata,
      permissions: permissions ?? this.permissions,
    );
  }

  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    if (timestamp is String) return DateTime.tryParse(timestamp);
    return null;
  }
}

// Existing UserRole stays the same
enum UserRole {
  user('User'),
  moderator('Moderator'),
  admin('Admin'),
  superAdmin('Super Admin');

  const UserRole(this.displayName);
  final String displayName;

  static UserRole fromString(String? roleString) {
    if (roleString == null) return UserRole.user;
    switch (roleString.toLowerCase().trim()) {
      case 'moderator':
        return UserRole.moderator;
      case 'admin':
        return UserRole.admin;
      case 'superadmin':
      case 'super_admin':
        return UserRole.superAdmin;
      default:
        return UserRole.user;
    }
  }
}
