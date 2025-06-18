class Tag {
  final String id;
  final String name;
  final String subFor;
  final String position;
  final String createdAt;
  final String updatedAt;

  Tag({
    required this.id,
    required this.name,
    required this.subFor,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      subFor: json['sub_for'] ?? '',
      position: json['position'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}
