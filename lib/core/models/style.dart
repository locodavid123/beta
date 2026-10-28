class ArtStyle {
  final String id;
  final String name;
  final String category;
  final String imagePath;
  final String description;
  final bool isHot;
  final String status; // 'activo', 'borrador', 'archivado'
  final String promptTemplate;
  final String coatType; // 'Pelo Largo', 'Pelo Corto', 'Ambos'
  final String difficulty; // 'Fácil', 'Medio', 'Difícil'
  final int uses;
  final String tutorialId;
  final String videoUrl;

  ArtStyle({
    required this.id,
    required this.name,
    required this.category,
    required this.imagePath,
    required this.description,
    this.isHot = false,
    this.status = 'activo',
    this.promptTemplate = '',
    this.coatType = 'Ambos',
    this.difficulty = 'Medio',
    this.uses = 0,
    this.tutorialId = '',
    this.videoUrl = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'imagePath': imagePath,
      'description': description,
      'isHot': isHot,
      'status': status,
      'promptTemplate': promptTemplate,
      'coatType': coatType,
      'difficulty': difficulty,
      'uses': uses,
      'tutorialId': tutorialId,
      'videoUrl': videoUrl,
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
      status: map['status'] ?? 'activo',
      promptTemplate: map['promptTemplate'] ?? '',
      coatType: map['coatType'] ?? 'Ambos',
      difficulty: map['difficulty'] ?? 'Medio',
      uses: map['uses'] ?? 0,
      tutorialId: map['tutorialId'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
    );
  }

  ArtStyle copyWith({
    String? id,
    String? name,
    String? category,
    String? imagePath,
    String? description,
    bool? isHot,
    String? status,
    String? promptTemplate,
    String? coatType,
    String? difficulty,
    int? uses,
    String? tutorialId,
    String? videoUrl,
  }) {
    return ArtStyle(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
      isHot: isHot ?? this.isHot,
      status: status ?? this.status,
      promptTemplate: promptTemplate ?? this.promptTemplate,
      coatType: coatType ?? this.coatType,
      difficulty: difficulty ?? this.difficulty,
      uses: uses ?? this.uses,
      tutorialId: tutorialId ?? this.tutorialId,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }
}

