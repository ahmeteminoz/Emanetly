class EmanetComment {
  final String id;
  final String authorName;
  final double rating;
  final String content;
  final DateTime createdAt;

  EmanetComment({
    required this.id,
    required this.authorName,
    required this.rating,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authorName': authorName,
      'rating': rating,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EmanetComment.fromMap(Map<String, dynamic> map) {
    return EmanetComment(
      id: map['id'] ?? '',
      authorName: map['authorName'] ?? '',
      rating: (map['rating'] ?? 5.0).toDouble(),
      content: map['content'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
