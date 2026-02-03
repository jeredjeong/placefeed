import 'package:cloud_firestore/cloud_firestore.dart';

class UserRole {
  final String uid;
  final String role; // e.g., 'user', 'admin'

  UserRole({required this.uid, required this.role});

  factory UserRole.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return UserRole(
      uid: snapshot.id,
      role: data?['role'] ?? 'user', // Default role is 'user'
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "role": role,
    };
  }
}
