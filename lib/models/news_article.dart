import 'package:cloud_firestore/cloud_firestore.dart';

class NewsArticle {
  final String id;
  final String title;
  final String source;
  final String content;
  final String imageUrl;
  final String url;
  final Timestamp publishedAt;

  // 새로 추가된 필드
  final String locationText;
  final int importance;

  NewsArticle({
    required this.id,
    required this.title,
    required this.source,
    required this.content,
    required this.imageUrl,
    required this.url,
    required this.publishedAt,
    // 생성자에 추가
    required this.locationText,
    required this.importance,
  });

  // Firestore 데이터를 NewsArticle 객체로 변환하는 factory 생성자
  factory NewsArticle.fromMap(String id, Map<String, dynamic> data) {
    return NewsArticle(
      id: id,
      title: data['title'] ?? '제목 없음',
      source: data['source'] ?? '출처 없음',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      url: data['url'] ?? '',
      publishedAt: data['publishedAt'] as Timestamp? ?? Timestamp.now(),
      // 새로 추가된 필드 매핑
      locationText: data['locationText'] ?? '위치 정보 없음',
      importance: (data['importance'] ?? 0).toInt(),
    );
  }

  // Method to convert a NewsArticle to a map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'source': source,
      'content': content,
      'imageUrl': imageUrl,
      'url': url,
      'publishedAt': publishedAt,
      'locationText': locationText,
      'importance': importance,
    };
  }
}
