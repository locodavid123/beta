class ModerationReport {
  final String id;
  final String userEmail;
  final String reason;
  final String creationId;
  final String creationImagePath;
  final String priority; // 'Alta', 'Media', 'Baja'
  final DateTime date;
  final bool isResolved;

  ModerationReport({
    required this.id,
    required this.userEmail,
    required this.reason,
    required this.creationId,
    required this.creationImagePath,
    required this.priority,
    required this.date,
    this.isResolved = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userEmail': userEmail,
      'reason': reason,
      'creationId': creationId,
      'creationImagePath': creationImagePath,
      'priority': priority,
      'date': date.toIso8601String(),
      'isResolved': isResolved ? 1 : 0,
    };
  }

  factory ModerationReport.fromMap(Map<String, dynamic> map) {
    return ModerationReport(
      id: map['id'] ?? '',
      userEmail: map['userEmail'] ?? '',
      reason: map['reason'] ?? '',
      creationId: map['creationId'] ?? '',
      creationImagePath: map['creationImagePath'] ?? '',
      priority: map['priority'] ?? 'Media',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      isResolved: (map['isResolved'] == 1 || map['isResolved'] == true),
    );
  }
}
