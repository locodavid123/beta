class CoatDiagnosisResult {
  final bool isShihTzu;
  final String detectedBreed;
  final String breedVerificationMessage;
  final int overallScore; // 0 - 100
  final String scoreLevel; // Excelente, Muy Bueno, Requiere Atención
  final String tearStainStatus; // Limpio, Leve, Moderado, Notorio
  final String tearStainAdvice;
  final String eyeRiskStatus; // Seguro / Despejado, Precaución, Peligro de roce
  final String eyeRiskAdvice;
  final String coatCondition; // Sedoso, Enredos Leves, etc.
  final String mattingRisk; // Bajo, Medio, Alto
  final String recommendedStyleId; // corte_cachorro, corte_oso, etc.
  final String recommendedStyleName;
  final String recommendedStyleReason;
  final String faceShape;
  final List<String> keyObservations;
  final List<String> groomingActionPlan;
  final String groomerAdvice;

  CoatDiagnosisResult({
    this.isShihTzu = true,
    this.detectedBreed = 'Shih Tzu',
    this.breedVerificationMessage = 'Raza verificada: Cumple con los rasgos faciales y de manto de Shih Tzu.',
    required this.overallScore,
    required this.scoreLevel,
    required this.tearStainStatus,
    required this.tearStainAdvice,
    required this.eyeRiskStatus,
    required this.eyeRiskAdvice,
    required this.coatCondition,
    required this.mattingRisk,
    required this.recommendedStyleId,
    required this.recommendedStyleName,
    required this.recommendedStyleReason,
    required this.faceShape,
    required this.keyObservations,
    required this.groomingActionPlan,
    required this.groomerAdvice,
  });

  Map<String, dynamic> toMap() {
    return {
      'isShihTzu': isShihTzu,
      'detectedBreed': detectedBreed,
      'breedVerificationMessage': breedVerificationMessage,
      'overallScore': overallScore,
      'scoreLevel': scoreLevel,
      'tearStainStatus': tearStainStatus,
      'tearStainAdvice': tearStainAdvice,
      'eyeRiskStatus': eyeRiskStatus,
      'eyeRiskAdvice': eyeRiskAdvice,
      'coatCondition': coatCondition,
      'mattingRisk': mattingRisk,
      'recommendedStyleId': recommendedStyleId,
      'recommendedStyleName': recommendedStyleName,
      'recommendedStyleReason': recommendedStyleReason,
      'faceShape': faceShape,
      'keyObservations': keyObservations,
      'groomingActionPlan': groomingActionPlan,
      'groomerAdvice': groomerAdvice,
    };
  }

  factory CoatDiagnosisResult.fromMap(Map<String, dynamic> map) {
    final breed = map['detectedBreed']?.toString() ?? 'Shih Tzu';
    final breedLower = breed.toLowerCase();
    bool isBreedShihTzu = map['isShihTzu'] == true;
    if (breedLower.contains('shih tzu') ||
        breedLower.contains('shitzu') ||
        breedLower.contains('shitsu') ||
        breedLower.contains('shihtzu') ||
        breedLower.contains('shih-tzu')) {
      isBreedShihTzu = true;
    }

    return CoatDiagnosisResult(
      isShihTzu: isBreedShihTzu,
      detectedBreed: isBreedShihTzu ? 'Shih Tzu' : breed,
      breedVerificationMessage: map['breedVerificationMessage'] ??
          (isBreedShihTzu
              ? 'Raza verificada: Cumple con los rasgos faciales de Shih Tzu.'
              : 'Se identificó la raza $breed. Esta app está especializada en Shih Tzu.'),
      overallScore: map['overallScore'] is int
          ? map['overallScore']
          : int.tryParse(map['overallScore']?.toString() ?? '85') ?? 85,
      scoreLevel: map['scoreLevel'] ?? 'Muy Bueno',
      tearStainStatus: map['tearStainStatus'] ?? 'Leve',
      tearStainAdvice: map['tearStainAdvice'] ??
          'Limpiar con suero fisiológico y mantener el área seca a diario.',
      eyeRiskStatus: map['eyeRiskStatus'] ?? 'Despejado y Seguro',
      eyeRiskAdvice: map['eyeRiskAdvice'] ??
          'Mantener recortados o recogidos los pelos perioculares para proteger la córnea.',
      coatCondition: map['coatCondition'] ?? 'Manto denso y suave',
      mattingRisk: map['mattingRisk'] ?? 'Bajo',
      recommendedStyleId: map['recommendedStyleId'] ?? 'corte_cachorro',
      recommendedStyleName:
          map['recommendedStyleName'] ?? 'Corte Cachorro (Puppy Cut)',
      recommendedStyleReason: map['recommendedStyleReason'] ??
          'Proporciona máxima comodidad, higiene en los lagrimales y fácil cepillado.',
      faceShape: map['faceShape'] ?? 'Carita Crisantemo Clásica',
      keyObservations: List<String>.from(map['keyObservations'] ?? [
        'Lagrimales con ligera oxidación común en la raza.',
        'Ojos expresivos con área periorbital despejada.',
        'Pelaje con buena densidad y textura saludable.',
      ]),
      groomingActionPlan: List<String>.from(map['groomingActionPlan'] ?? [
        'Cepillado diario con carda suave sin bolitas en las puntas.',
        'Secar lagrimales por la mañana y noche con paño de microfibra.',
        'Baño quincenal con champú nutritivo especial para pelo largo.',
      ]),
      groomerAdvice: map['groomerAdvice'] ??
          'Rebajar puente nasal con tijera curva de punta roma y marcar contorno de orejas.',
    );
  }
}
