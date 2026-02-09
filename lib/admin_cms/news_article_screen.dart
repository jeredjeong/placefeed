import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
import 'package:myapp/admin_cms/admin_layout.dart';
import 'package:myapp/models/news_article.dart'; // Import the NewsArticle model

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
            // StreamBuilder to listen to the news_articles collection
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('news_articles')
                    .orderBy('publishedAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No news articles found.'));
                  }

                  final articles = snapshot.data!.docs.map((doc) {
                    return NewsArticle.fromMap(doc.id, doc.data() as Map<String, dynamic>);
                  }).toList();

                  return SingleChildScrollView(
                    child: PaginatedDataTable(
                      header: const Text('Found News Articles'),
                      columns: const [
                        DataColumn(label: Text('Title')),
                        DataColumn(label: Text('Source')),
                        DataColumn(label: Text('Importance')),
                        DataColumn(label: Text('Location')),
                        DataColumn(label: Text('Published At')),
                        DataColumn(label: Text('Actions')),
                      ],
                      source: NewsArticleDataSource(articles, context),
                      rowsPerPage: 15,
                      showCheckboxColumn: false,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NewsArticleDataSource extends DataTableSource {
  final List<NewsArticle> _articles;
  final BuildContext context;

  NewsArticleDataSource(this._articles, this.context);

  @override
  DataRow? getRow(int index) {
    if (index >= _articles.length) {
      return null;
    }
    final article = _articles[index];
    return DataRow(cells: [
      DataCell(
        SizedBox(
          width: 250, // Max width for title
          child: Text(
            article.title,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
        onTap: () => _launchURL(article.url),
      ),
      DataCell(Text(article.source)),
      DataCell(Text(article.importance.toString())),
      DataCell(Text(article.locationText)),
      DataCell(Text(DateFormat('yyyy-MM-dd HH:mm').format(article.publishedAt.toDate()))),
      DataCell(
        IconButton(
          icon: const Icon(Icons.open_in_new),
          tooltip: 'Open Article URL',
          onPressed: () => _launchURL(article.url),
        ),
      ),
    ]);
  }

  void _launchURL(String url) async {
    if (url.isEmpty) return;
    if (!await launchUrl(Uri.parse(url))) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _articles.length;

  @override
  int get selectedRowCount => 0;
}
