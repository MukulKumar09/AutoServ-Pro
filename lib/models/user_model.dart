// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, serviceAdvisor, accountant }

class UserModel {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final bool isActive;
  final DateTime? createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.isActive = true,
    this.createdAt,
  });

  String get roleLabel {
    switch (role) {
      case UserRole.admin:          return 'Admin';
      case UserRole.serviceAdvisor: return 'Service Advisor';
      case UserRole.accountant:     return 'Accountant';
    }
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid:       doc.id,
      email:     d['email']  ?? '',
      name:      d['name']   ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == (d['role'] ?? 'serviceAdvisor'),
        orElse: () => UserRole.serviceAdvisor,
      ),
      isActive:  d['isActive'] ?? true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'uid':       uid,
    'email':     email,
    'name':      name,
    'role':      role.name,
    'isActive':  isActive,
    'createdAt': FieldValue.serverTimestamp(),
  };

  UserModel copyWith({
    String? uid, String? email, String? name,
    UserRole? role, bool? isActive,
  }) => UserModel(
    uid:      uid      ?? this.uid,
    email:    email    ?? this.email,
    name:     name     ?? this.name,
    role:     role     ?? this.role,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt,
  );
}
