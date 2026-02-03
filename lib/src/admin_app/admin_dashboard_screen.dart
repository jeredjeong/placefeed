import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:myapp/src/services/auth_service.dart';
import 'package:myapp/src/models/article.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _deleteArticle(String articleId) async {
    final bool? confirm = await showDialog<bool>( // Specify return type to avoid lint warning
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this article?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _firestore.collection('articles').doc(articleId).delete();
        if (mounted) { // Ensure context is still mounted before using
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Article deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) { // Ensure context is still mounted before using
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete article: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PlaceFeed Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (mounted) {
                context.go('/login'); // Redirect to login after logout
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar for future navigation (e.g., User Management, Settings)
          Container(
            width: 200,
            color: Theme.of(context).cardColor,
            child: ListView(
              children: const [
                ListTile(
                  leading: Icon(Icons.article),
                  title: Text('Articles'),
                  selected: true,
                ),
                ListTile(
                  leading: Icon(Icons.people),
                  title: Text('Users'),
                  enabled: false, // Placeholder, not implemented yet
                ),
                // Add more admin navigation items here
              ],
            ),
          ),
          // Main content area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Manage Articles',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to a dedicated screen for adding/editing
                          context.go('/admin/article_form');
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add New Article'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _firestore.collection('articles').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final articles = snapshot.data!.docs.map((doc) => Article.fromFirestore(doc, null)).toList();

                        if (articles.isEmpty) {
                          return const Center(child: Text('No articles found.'));
                        }

                        return ListView.builder(
                          itemCount: articles.length,
                          itemBuilder: (context, index) {
                            final article = articles[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      article.title,
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(article.description),
                                    const SizedBox(height: 8),
                                    Text('Source: ${article.source} | Published: ${DateFormat.yMd().add_jm().format(article.publishedAt)}'),
                                    Text('Importance: ${article.importance} | Zoom Range: ${article.minZoom}-${article.maxZoom}'),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: OverflowBar(
                                        children: <Widget>[ // Explicitly define type as <Widget>
                                          TextButton(
                                            onPressed: () {
                                              context.go('/admin/article_form?id=${article.id}');
                                            },
                                            child: const Text('Edit'),
                                          ),
                                          TextButton(
                                            onPressed: () => _deleteArticle(article.id),
                                            child: const Text('Delete'),
                                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}