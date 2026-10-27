class Tutorial {
  final String id;
  final String title;
  final String duration;
  final String difficulty; // 'Fácil', 'Medio', 'Difícil'
  final int views;
  final String status; // 'publicado', 'borrador'
  final String videoUrl;
  final String category; // 'Cortes', 'Cepillado', 'Higiene', 'Baño'
  final List<String> tools;
  final List<String> steps;

  Tutorial({
    required this.id,
    required this.title,
    required this.duration,
    required this.difficulty,
    this.views = 0,
    this.status = 'publicado',
    this.videoUrl = '',
    this.category = 'Cortes',
    this.tools = const [],
    this.steps = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'duration': duration,
      'difficulty': difficulty,
      'views': views,
      'status': status,
      'videoUrl': videoUrl,
      'category': category,
      'tools': tools,
      'steps': steps,
    };
  }

  factory Tutorial.fromMap(Map<String, dynamic> map) {
    return Tutorial(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      duration: map['duration'] ?? '',
      difficulty: map['difficulty'] ?? 'Fácil',
      views: map['views'] ?? 0,
      status: map['status'] ?? 'publicado',
      videoUrl: map['videoUrl'] ?? '',
      category: map['category'] ?? 'Cortes',
      tools: map['tools'] != null ? List<String>.from(map['tools']) : const [],
      steps: map['steps'] != null ? List<String>.from(map['steps']) : const [],
    );
  }

  Tutorial copyWith({
    String? id,
    String? title,
    String? duration,
    String? difficulty,
    int? views,
    String? status,
    String? videoUrl,
    String? category,
    List<String>? tools,
    List<String>? steps,
  }) {
    return Tutorial(
      id: id ?? this.id,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      difficulty: difficulty ?? this.difficulty,
      views: views ?? this.views,
      status: status ?? this.status,
      videoUrl: videoUrl ?? this.videoUrl,
      category: category ?? this.category,
      tools: tools ?? this.tools,
      steps: steps ?? this.steps,
    );
  }
}
