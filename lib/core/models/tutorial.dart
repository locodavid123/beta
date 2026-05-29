class Tutorial {
  final String id;
  final String title;
  final String duration;
  final String difficulty; // 'Fácil', 'Medio', 'Difícil'
  final int views;
  final String status; // 'publicado', 'borrador'
  final String videoUrl;

  Tutorial({
    required this.id,
    required this.title,
    required this.duration,
    required this.difficulty,
    this.views = 0,
    this.status = 'publicado',
    this.videoUrl = '',
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
    );
  }
}
