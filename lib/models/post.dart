// lib/models/post.dart

class Post {
  final int? id;
  final String title;
  final String body;
  final String author;
  final String createdAt;

  Post({
    this.id,
    required this.title,
    required this.body,
    required this.author,
    required this.createdAt,
  });

  /// Convert a Post into a Map for inserting into SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'author': author,
      'createdAt': createdAt,
    };
  }

  /// Create a Post from a Map retrieved from SQLite
  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] as int?,
      title: map['title'] as String,
      body: map['body'] as String,
      author: map['author'] as String,
      createdAt: map['createdAt'] as String,
    );
  }

  /// Create a copy of this Post with updated fields
  Post copyWith({
    int? id,
    String? title,
    String? body,
    String? author,
    String? createdAt,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Post{id: $id, title: $title, author: $author, createdAt: $createdAt}';
  }
}
