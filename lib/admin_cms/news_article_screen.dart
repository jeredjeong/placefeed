import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:myapp/admin_cms/admin_layout.dart';
import 'package:myapp/models/news_article.dart'; // Import the NewsArticle model

enum TimeRange {
  last24Hours,
  lastWeek,
  custom,
}

class NewsArticleScreen extends StatefulWidget {
  const NewsArticleScreen({super.key});

  @override
  State<NewsArticleScreen> createState() => _NewsArticleScreenState();
}

class _NewsArticleScreenState extends State<NewsArticleScreen> {
  TimeRange _selectedTimeRange = TimeRange.last24Hours;
  DateTime _startDate = DateTime.now().subtract(const Duration(hours: 24));
  DateTime _endDate = DateTime.now();
  List<NewsArticle> _newsArticles = [];
  bool _isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchNewsArticles();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _fetchNewsArticles() async {
    setState(() {
      _isLoading = true;
      _newsArticles = []; // Clear previous results
    });

    try {
      // Simulate fetching from Firestore based on time range
      Query query = _firestore.collection('news_articles');

      // Adjust start and end dates based on selected time range
      DateTime actualStartDate = _startDate;
      DateTime actualEndDate = _endDate;

      if (_selectedTimeRange == TimeRange.last24Hours) {
        actualStartDate = DateTime.now().subtract(const Duration(hours: 24));
        actualEndDate = DateTime.now();
      } else if (_selectedTimeRange == TimeRange.lastWeek) {
        actualStartDate = DateTime.now().subtract(const Duration(days: 7));
        actualEndDate = DateTime.now();
      }
      // For custom, _startDate and _endDate are already set by date pickers.

      query = query.where('publishedAt', isGreaterThanOrEqualTo: actualStartDate.toIso8601String());
      query = query.where('publishedAt', isLessThanOrEqualTo: actualEndDate.toIso8601String());

      final QuerySnapshot snapshot = await query.get();

      // Dummy data for now if Firestore is empty or for testing purposes
      if (snapshot.docs.isEmpty) {
        _newsArticles = _generateDummyArticles(actualStartDate, actualEndDate);
      } else {
        _newsArticles = snapshot.docs.map((doc) => NewsArticle.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      }

    } catch (e) {
      print('Error fetching news articles: $e');
      // Fallback to dummy data on error
      _newsArticles = _generateDummyArticles(_startDate, _endDate);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<NewsArticle> _generateDummyArticles(DateTime start, DateTime end) {
    List<NewsArticle> dummy = [];
    for (int i = 0; i < 5; i++) {
      dummy.add(NewsArticle(
        id: 'dummy_$i',
        title: 'Dummy News Article $i',
        url: 'https://example.com/news/$i',
        source: 'Dummy Source',
        publishedAt: start.add(Duration(days: i % ((end.difference(start).inDays == 0 ? 1 : end.difference(start).inDays) + 1))),
        snippet: 'This is a snippet for dummy news article $i.',
      ));
    }
    return dummy;
  }

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
            // Time scale selection
            Row(
              children: [
                SegmentedButton<TimeRange>(
                  segments: const <ButtonSegment<TimeRange>>[
                    ButtonSegment<TimeRange>(
                      value: TimeRange.last24Hours,
                      label: Text('Last 24h'),
                    ),
                    ButtonSegment<TimeRange>(
                      value: TimeRange.lastWeek,
                      label: Text('Last Week'),
                    ),
                    ButtonSegment<TimeRange>(
                      value: TimeRange.custom,
                      label: Text('Custom'),
                    ),
                  ],
                  selected: <TimeRange>{_selectedTimeRange},
                  onSelectionChanged: (Set<TimeRange> newSelection) {
                    setState(() {
                      _selectedTimeRange = newSelection.first;
                    });
                  },
                ),
                const SizedBox(width: 20),
                if (_selectedTimeRange == TimeRange.custom)
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => _selectDate(context, true),
                        child: Text('Start: ${DateFormat('yyyy-MM-dd').format(_startDate)}'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _selectDate(context, false),
                        child: Text('End: ${DateFormat('yyyy-MM-dd').format(_endDate)}'),
                      ),
                    ],
                  ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: _fetchNewsArticles,
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: PaginatedDataTable(
                      header: const Text('Found News Articles'),
                      columns: const [
                        DataColumn(label: Text('Title')),
                        DataColumn(label: Text('Source')),
                        DataColumn(label: Text('Published At')),
                        DataColumn(label: Text('Snippet')),
                        DataColumn(label: Text('Actions')),
                      ],
                      source: NewsArticleDataSource(_newsArticles, context),
                      rowsPerPage: 10,
                      showCheckboxColumn: false,
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
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200), // Max width for title
          child: Text(
            article.title,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
        onTap: () => _launchURL(article.url),
      ),
      DataCell(Text(article.source)),
      DataCell(Text(DateFormat('yyyy-MM-dd HH:mm').format(article.publishedAt))),
      DataCell(
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300), // Max width for snippet
          child: Text(
            article.snippet,
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
          ),
        ),
      ),
      DataCell(
        IconButton(
          icon: const Icon(Icons.open_in_new),
          onPressed: () => _launchURL(article.url),
        ),
      ),
    ]);
  }

  void _launchURL(String url) async {
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
