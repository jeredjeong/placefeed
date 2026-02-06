import 'package:flutter/material.dart';
import 'package:myapp/admin_cms/admin_layout.dart';

class NewsArticleScreen extends StatelessWidget {
  const NewsArticleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      selectedRoute: '/admin/news',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'News Article Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Time scale selection and search button (to be implemented)
            // Search results table (to be implemented)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('News Article Search and Display - Coming Soon!'),
                    Text('Here you will be able to search and manage news articles.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
