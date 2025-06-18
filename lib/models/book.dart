class Tag {
  final String id;
  final String name;

  Tag({
    required this.id,
    required this.name,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class Book {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final List<Tag> bookTags;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    this.bookTags = const [],
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      coverUrl: json['coverUrl'],
      bookTags: (json['tags'] as List?)
              ?.map((tagJson) => Tag.fromJson(tagJson))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'tags': bookTags.map((tag) => tag.toJson()).toList(),
    };
  }
}
