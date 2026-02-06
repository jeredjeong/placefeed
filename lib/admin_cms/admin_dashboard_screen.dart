import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // After signing out, navigate back to the login screen
              if (context.mounted) {
                context.go('/admin');
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to the Admin Dashboard!'),
            Text('Logged in as: ${FirebaseAuth.instance.currentUser?.email ?? 'N/A'}'),
            const SizedBox(height: 20),
            const Text('Admin Dashboard - Coming Soon!'),
            // TODO: Implement CMS features
          ],
        ),
      ),
    );
  }
}