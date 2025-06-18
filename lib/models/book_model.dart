class Book {
  final String id;
  final String title;
  final String description;
  final String folder;
  final String image;
  final String fileType;
  final String filePath;
  final String time;
  final String visibility;
  final String shopCategorie;
  final String bookAuthorId;
  final String tagIds;
  final String authorId;
  final bool completed;
  final int? currentPosition;
  final String isFree;
  final String language;
  final String abbr; // Language abbreviation field

  Book({
    required this.id,
    required this.title,
    required this.description,
    required this.folder,
    required this.image,
    required this.fileType,
    required this.filePath,
    required this.time,
    required this.visibility,
    required this.shopCategorie,
    required this.bookAuthorId,
    required this.tagIds,
    required this.authorId,
    required this.isFree,
    required this.language,
    required this.abbr,
    this.completed = false,
    this.currentPosition,
  });

  // Getter to check if book is in Assamese
  bool get isAssamese => abbr.toLowerCase() == 'as';

  // Getter to check if book is in English
  bool get isEnglish => abbr.toLowerCase() == 'en';

  // Getter to get standardized language code
  String get languageCode => abbr.toLowerCase();

  factory Book.fromJson(Map<String, dynamic> json) {
    String cleanDescription =
        (json['description'] ?? '').replaceAll(RegExp(r'<[^>]*>'), '');

    // Helper function to safely convert to string
    String safeToString(dynamic value) => value?.toString() ?? '';

    return Book(
      id: safeToString(json['id']),
      title: (json['title'] ?? '').toString(),
      description: cleanDescription,
      folder: (json['folder'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      fileType: (json['file_type'] ?? '').toString(),
      filePath: (json['file_path'] ?? '').toString(),
      time: (json['time'] ?? '').toString(),
      visibility: safeToString(json['visibility']),
      shopCategorie: safeToString(json['shop_categorie']),
      bookAuthorId: safeToString(json['book_author_id']),
      tagIds: safeToString(json['tag_ids']),
      authorId: safeToString(json['author_id']),
      isFree: (json['is_free'] ?? 'no').toString().toLowerCase(),
      language: (json['language'] ?? 'as').toString(),
      abbr: (json['abbr'] ?? 'as')
          .toString(), // Get language abbreviation from API
      completed: json['completed'] ?? false,
      currentPosition: json['current_position'] is int
          ? json['current_position']
          : json['current_position'] != null
              ? int.tryParse(json['current_position'].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'folder': folder,
      'image': image,
      'file_type': fileType,
      'file_path': filePath,
      'time': time,
      'visibility': visibility,
      'shop_categorie': shopCategorie,
      'book_author_id': bookAuthorId,
      'tag_ids': tagIds,
      'author_id': authorId,
      'is_free': isFree,
      'language': language,
      'abbr': abbr,
      'completed': completed,
      'current_position': currentPosition,
    };
  }
}
