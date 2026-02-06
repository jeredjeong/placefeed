class NewsArticle {
  final String id;
  final String title;
  final String url;
  final String source;
  final DateTime publishedAt;
  final String snippet; // A short summary or snippet of the article content

  NewsArticle({
    required this.id,
    required this.title,
    required this.url,
    required this.source,
    required this.publishedAt,
    required this.snippet,
  });

  // Factory constructor for creating a NewsArticle from a map (e.g., from Firestore)
  factory NewsArticle.fromMap(Map<String, dynamic> data, String id) {
    return NewsArticle(
      id: id,
      title: data['title'] ?? 'No Title',
      url: data['url'] ?? '',
      source: data['source'] ?? 'Unknown',
      publishedAt: (data['publishedAt'] != null)
          ? DateTime.parse(data['publishedAt'] as String)
          : DateTime.now(), // Fallback to current time if null
      snippet: data['snippet'] ?? '',
    );
  }

  // Method to convert a NewsArticle to a map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'url': url,
      'source': source,
      'publishedAt': publishedAt.toIso8601String(),
      'snippet': snippet,
    };
  }
}
