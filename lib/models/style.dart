class ArtStyle {
  final String id;
  final String name;
  final String category;
  final String imagePath;
  final String description;
  final bool isHot;

  ArtStyle({
    required this.id,
    required this.name,
    required this.category,
    required this.imagePath,
    required this.description,
    this.isHot = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'imagePath': imagePath,
      'description': description,
      'isHot': isHot,
    };
  }

  factory ArtStyle.fromMap(Map<String, dynamic> map) {
    return ArtStyle(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      imagePath: map['imagePath'] ?? '',
      description: map['description'] ?? '',
      isHot: map['isHot'] ?? false,
    );
  }
}
