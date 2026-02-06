import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;
  final String selectedRoute;

  const AdminLayout({super.key, required this.child, required this.selectedRoute});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                context.go('/admin');
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Navigation Bar
          Container(
            width: 250,
            color: Colors.grey[200],
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text('Dashboard'),
                  selected: selectedRoute == '/admin/dashboard',
                  onTap: () => context.go('/admin/dashboard'),
                ),
                ListTile(
                  leading: const Icon(Icons.article),
                  title: const Text('News Articles'),
                  selected: selectedRoute == '/admin/news',
                  onTap: () => context.go('/admin/news'),
                ),
                // Add more admin menu items here
              ],
            ),
          ),
          // Main Content Area
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}
