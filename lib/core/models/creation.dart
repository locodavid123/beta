class Creation {
  final String id;
  final String petId;
  final String petName;
  final String styleId;
  final String styleName;
  final String imagePath;
  final DateTime date;
  final int likes;
  final bool isAiGenerated;
  final String description;

  Creation({
    required this.id,
    required this.petId,
    required this.petName,
    required this.styleId,
    required this.styleName,
    required this.imagePath,
    required this.date,
    required this.likes,
    this.isAiGenerated = true,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'petName': petName,
      'styleId': styleId,
      'styleName': styleName,
      'imagePath': imagePath,
      'date': date.toIso8601String(),
      'likes': likes,
      'isAiGenerated': isAiGenerated,
      'description': description,
    };
  }

  factory Creation.fromMap(Map<String, dynamic> map) {
    return Creation(
      id: map['id'] ?? '',
      petId: map['petId'] ?? '',
      petName: map['petName'] ?? '',
      styleId: map['styleId'] ?? '',
      styleName: map['styleName'] ?? '',
      imagePath: map['imagePath'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      likes: map['likes'] ?? 0,
      isAiGenerated: map['isAiGenerated'] ?? true,
      description: map['description'] ?? '',
    );
  }
}
