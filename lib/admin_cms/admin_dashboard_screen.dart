import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/admin_cms/admin_layout.dart'; // Import AdminLayout

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      selectedRoute: '/admin/dashboard',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to the Admin Dashboard!'),
            Text('Logged in as: ${FirebaseAuth.instance.currentUser?.email ?? 'N/A'}'),
            const SizedBox(height: 20),
            const Text('This is your central hub for managing content.'),
            // TODO: Implement CMS features
          ],
        ),
      ),
    );
  }
}