class Pet {
  final String id;
  final String name;
  final String breed;
  final String age;
  final String gender;
  final String notes;
  final String imagePath;
  final bool isVerifiedByAI;
  final String userEmail;

  Pet({
    required this.id,
    required this.name,
    required this.breed,
    required this.age,
    required this.gender,
    required this.notes,
    required this.imagePath,
    this.isVerifiedByAI = false,
    required this.userEmail,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'age': age,
      'gender': gender,
      'notes': notes,
      'imagePath': imagePath,
      'isVerifiedByAI': isVerifiedByAI,
      'userEmail': userEmail,
    };
  }

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      breed: map['breed'] ?? '',
      age: map['age'] ?? '',
      gender: map['gender'] ?? '',
      notes: map['notes'] ?? '',
      imagePath: map['imagePath'] ?? '',
      isVerifiedByAI: map['isVerifiedByAI'] ?? false,
      userEmail: map['userEmail'] ?? '',
    );
  }
}
