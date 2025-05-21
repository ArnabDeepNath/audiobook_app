class Category {
  final String id;
  final String name;
  final String image;
  final String position;

  Category({
    required this.id,
    required this.name,
    required this.image,
    required this.position,
  });

  bool get isAssamese {
    // Assamese Unicode range (includes Bengali since they share the same script)
    RegExp assameseRegex = RegExp(r'[\u0980-\u09FF]');
    return assameseRegex.hasMatch(name);
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      position: json['position']?.toString() ?? '0',
    );
  }
}
