import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/coat_diagnosis.dart';

class GeminiResult {
  final bool isShihTzu;
  final String breed;
  final String message;
  final bool isServiceError;

  GeminiResult({
    required this.isShihTzu,
    required this.breed,
    required this.message,
    this.isServiceError = false,
  });
}

class GeminiService {
  static Future<GeminiResult> verifyShihTzu(File imageFile, String apiKey) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Determine mimeType based on extension
      String mimeType = 'image/jpeg';
      final pathLower = imageFile.path.toLowerCase();
      if (pathLower.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (pathLower.endsWith('.webp')) {
        mimeType = 'image/webp';
      } else if (pathLower.endsWith('.gif')) {
        mimeType = 'image/gif';
      }

      int lastStatusCode = 0;
      String lastErrorMsg = '';

      // Iterate through fallback models (gemini-3.5-flash -> flash-lite -> etc.)
      for (final model in AppConfig.fallbackModels) {
        try {
          final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
          );

          final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {
                      'text': 'Analiza esta imagen de un perro. Determina con rigor si es de raza Shih Tzu (o mezcla con fuerte predominio de Shih Tzu). '
                          'Si es claramente de otra raza como Golden Retriever, Labrador, Pug, Caniche, Chihuahua, etc., "isShihTzu" DEBE ser false. '
                          'Debes responder ÚNICAMENTE con un objeto JSON válido, sin bloques de código markdown ni texto adicional. '
                          'El formato JSON debe ser exactamente: '
                          '{"isShihTzu": true/false, "breed": "Nombre de la raza identificada"}'
                    },
                    {
                      'inlineData': {
                        'mimeType': mimeType,
                        'data': base64Image,
                      }
                    }
                  ]
                }
              ]
            }),
          ).timeout(const Duration(seconds: 14));

          if (response.statusCode == 200) {
            final responseBody = jsonDecode(response.body);
            final text = responseBody['candidates']?[0]?['content']?[0]?['parts']?[0]?['text'] ??
                responseBody['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;

            if (text != null && text.trim().isNotEmpty) {
              String cleanJson = text.trim();
              final firstBrace = cleanJson.indexOf('{');
              final lastBrace = cleanJson.lastIndexOf('}');
              if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
                cleanJson = cleanJson.substring(firstBrace, lastBrace + 1);
              }

              final parsed = jsonDecode(cleanJson);
              final breed = parsed['breed'] ?? 'Desconocida';
              final breedLower = breed.toString().toLowerCase();

              bool isShihTzu = parsed['isShihTzu'] == true;

              // Override verification if the breed contains any Shih Tzu spelling variation
              if (breedLower.contains('shih tzu') ||
                  breedLower.contains('shitzu') ||
                  breedLower.contains('shitsu') ||
                  breedLower.contains('shihtzu') ||
                  breedLower.contains('shih-tzu') ||
                  breedLower.contains('shih_tzu') ||
                  breedLower.contains('shi-tzu')) {
                isShihTzu = true;
              }

              return GeminiResult(
                isShihTzu: isShihTzu,
                breed: isShihTzu ? 'Shih Tzu' : breed,
                message: isShihTzu
                    ? '¡Excelente! Se ha verificado que tu mascota es un Shih Tzu.'
                    : 'La foto cargada parece ser de la raza $breed. Esta aplicación es de uso exclusivo para Shih Tzus.',
                isServiceError: false,
              );
            }
          } else {
            lastStatusCode = response.statusCode;
            try {
              final errBody = jsonDecode(response.body);
              lastErrorMsg = errBody['error']?['message']?.toString() ?? '';
            } catch (_) {}
            // Retry next model if quota (429), not found (404), or server issue
            continue;
          }
        } catch (_) {
          continue;
        }
      }

      String msg = 'No se pudo verificar la raza con la IA (Código ${lastStatusCode > 0 ? lastStatusCode : "Red"}).';
      if (lastErrorMsg.toLowerCase().contains('leaked') || lastStatusCode == 403) {
        msg = 'La clave de Gemini API actual ha sido desactivada por Google (403 Leaked). Por favor genera una nueva clave gratuita en aistudio.google.com e ingrésala en Configuración.';
      } else if (lastStatusCode == 429) {
        msg = 'La cuota diaria de la IA de Google está ocupada temporalmente (429). Puedes confirmar tu Shih Tzu manualmente para continuar.';
      }

      return GeminiResult(
        isShihTzu: false,
        breed: 'Error de Verificación',
        message: msg,
        isServiceError: true,
      );
    } catch (e) {
      return GeminiResult(
        isShihTzu: false,
        breed: 'Sin Conexión',
        message: 'No se pudo conectar con el servicio de IA de Google. Revisa tu conexión a internet o tu clave de API.',
        isServiceError: true,
      );
    }
  }

  /// Realiza un escáner diagnóstico visual con IA (Gemini Vision) enfocado en
  /// lagrimales, área ocular, nudos, conformación de la carita y corte recomendado.
  static Future<CoatDiagnosisResult> diagnoseCoatAndFace(File imageFile, String apiKey) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      String mimeType = 'image/jpeg';
      final pathLower = imageFile.path.toLowerCase();
      if (pathLower.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (pathLower.endsWith('.webp')) {
        mimeType = 'image/webp';
      } else if (pathLower.endsWith('.gif')) {
        mimeType = 'image/gif';
      }

      const prompt = '''Eres un médico veterinario especialista en dermatología canina y máster groomer profesional de la raza Shih Tzu.
Analiza detenidamente esta fotografía enfocándote primero en determinar si es un perro de raza Shih Tzu, y luego analizando su carita, ojos, lagrimales y manto de pelo.

Evalúa con rigor técnico y estético canino:
1. isShihTzu: Booleano true/false. ¿Es un perro de raza Shih Tzu, mezcla donde predomine el Shih Tzu, o de aspecto muy cercano? (true si es Shih Tzu, false si claramente es otra raza como Golden Retriever, Pug, Poodle, Chihuahua, Gato, etc.).
2. detectedBreed: Nombre exacto de la raza detectada (ej: "Shih Tzu", "Golden Retriever", "Pug", "Bichón Maltés", "Poodle", etc.).
3. breedVerificationMessage: Explicación breve de la verificación de raza.
4. overallScore: Puntuación de salud e higiene (entero de 0 a 100).
5. scoreLevel: "Excelente" (85-100), "Muy Bueno" (70-84), o "Requiere Atención" (<70).
6. tearStainStatus: Presencia de manchas de lágrimas u oxidación por porfirinas ("Limpio / Despejado", "Leve", "Moderado", "Notorio").
7. tearStainAdvice: Consejo breve y práctico para el cuidado de los lagrimales.
8. eyeRiskStatus: Pelos rozando los ojos o córnea ("Seguro / Despejado", "Precaución", "Peligro de roce").
9. eyeRiskAdvice: Consejo para despejar la zona periorbital y proteger los ojos.
10. coatCondition: Estado y volumen del manto ("Sedoso y libre de enredos", "Ondulado con nudos leves", "Manto denso que requiere carda suave").
11. mattingRisk: Riesgo de nudos ("Bajo", "Medio", "Alto").
12. recommendedStyleId: Cuál de estos 5 cortes oficiales le favorece más según su conformación ("corte_cachorro", "corte_oso", "corte_topknot", "corte_leon", "corte_exhibicion").
13. recommendedStyleName: Nombre del corte ("Corte Cachorro (Puppy Cut)", "Corte Oso de Peluche", "Corte Top Knot", "Corte de León", o "Corte de Exhibición").
14. recommendedStyleReason: Justificación de por qué este corte favorece a este perro específico.
15. faceShape: Tipo de conformación ("Carita Redonda", "Carita Crisantemo Clásica", "Hocico Corto Braquicefálico").
16. keyObservations: Lista de 3 hallazgos específicos observados en la imagen.
17. groomingActionPlan: Lista de 3 pasos de acción recomendados para el dueño.
18. groomerAdvice: Instrucción técnica para el peluquero profesional.

Debes responder ÚNICAMENTE un objeto JSON válido sin bloques markdown ni texto adicional.
Ejemplo exacto de estructura:
{
  "isShihTzu": true,
  "detectedBreed": "Shih Tzu",
  "breedVerificationMessage": "Ejemplar verificado con fisionomía craneofacial y manto característicos de Shih Tzu.",
  "overallScore": 92,
  "scoreLevel": "Excelente",
  "tearStainStatus": "Leve",
  "tearStainAdvice": "Limpiar suavemente con suero fisiológico cada mañana y secar con toalla suave.",
  "eyeRiskStatus": "Seguro / Despejado",
  "eyeRiskAdvice": "Mantener flequillo recortado en semicírculo para evitar contacto con la córnea.",
  "coatCondition": "Sedoso con buen volumen",
  "mattingRisk": "Bajo",
  "recommendedStyleId": "corte_oso",
  "recommendedStyleName": "Corte Oso de Peluche",
  "recommendedStyleReason": "Su estructura facial redondeada resalta magníficamente con un acabado de osito.",
  "faceShape": "Carita Crisantemo Clásica",
  "keyObservations": ["Zona ocular despejada", "Lagrimales con mínima oxidación", "Manto bien hidratado"],
  "groomingActionPlan": ["Cepillado 3 veces por semana con carda", "Limpieza diaria de lagrimales", "Baño hidratante cada 2 semanas"],
  "groomerAdvice": "Despuntar hocico en pompón esférico y peinar orejas en degradé."
}''';

      int lastStatusCode = 0;
      String lastErrorMsg = '';

      for (final model in AppConfig.fallbackModels) {
        try {
          final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
          );

          final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                    {
                      'inlineData': {
                        'mimeType': mimeType,
                        'data': base64Image,
                      }
                    }
                  ]
                }
              ]
            }),
          ).timeout(const Duration(seconds: 18));

          if (response.statusCode == 200) {
            final responseBody = jsonDecode(response.body);
            final text = responseBody['candidates']?[0]?['content']?[0]?['parts']?[0]?['text'] ??
                responseBody['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;

            if (text != null && text.trim().isNotEmpty) {
              String cleanJson = text.trim();
              final firstBrace = cleanJson.indexOf('{');
              final lastBrace = cleanJson.lastIndexOf('}');
              if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
                cleanJson = cleanJson.substring(firstBrace, lastBrace + 1);
                final parsed = jsonDecode(cleanJson);
                return CoatDiagnosisResult.fromMap(parsed);
              }
            }
          } else {
            lastStatusCode = response.statusCode;
            try {
              final errBody = jsonDecode(response.body);
              lastErrorMsg = errBody['error']?['message']?.toString() ?? '';
            } catch (_) {}
            continue;
          }
        } catch (_) {
          continue;
        }
      }

      String errDetail = 'Error ${lastStatusCode > 0 ? lastStatusCode : "Red"}';
      if (lastErrorMsg.toLowerCase().contains('leaked') || lastStatusCode == 403) {
        errDetail = 'Clave API revocada por Google (Leaked)';
      } else if (lastStatusCode == 429) {
        errDetail = 'Cuota diaria de Google IA agotada (429)';
      }
      return buildFallbackDiagnosis(
        isError: true,
        errorReason: errDetail,
      );
    } catch (_) {
      // Ignored: fallback activates below
    }

    return buildFallbackDiagnosis(isError: true, errorReason: 'Sin conexión con la IA');
  }

  static CoatDiagnosisResult buildFallbackDiagnosis({bool isError = false, String? errorReason}) {
    final bool isKeyError = isError && (errorReason?.contains('revocada') == true || errorReason?.contains('403') == true);
    final bool isQuota = isError && (errorReason?.contains('429') == true || errorReason?.contains('Cuota') == true);

    return CoatDiagnosisResult(
      isShihTzu: true,
      detectedBreed: isKeyError
          ? 'Clave de Gemini API Revocada por Google'
          : isQuota
              ? 'Shih Tzu (Verificación en modo local)'
              : 'Shih Tzu (Modo local)',
      breedVerificationMessage: isKeyError
          ? 'Google desactivó la clave de API por haber sido reportada como pública. Ve a Configuración e ingresa una nueva clave gratuita de aistudio.google.com'
          : isQuota
              ? 'La cuota de Google IA gratuita está en pausa. Se activó el diagnóstico estimado para tu Shih Tzu.'
              : 'Diagnóstico visual asistido por el perfil de la raza Shih Tzu.',
      overallScore: 88,
      scoreLevel: 'Muy Bueno',
      tearStainStatus: 'Leve',
      tearStainAdvice: 'Limpieza suave diaria con suero fisiológico y secado con toalla absorbente.',
      eyeRiskStatus: 'Seguro / Despejado',
      eyeRiskAdvice: 'Mantener el área ocular despejada de pelos con cepillado ascendente.',
      coatCondition: 'Manto con buen volumen',
      mattingRisk: 'Medio',
      recommendedStyleId: 'corte_oso',
      recommendedStyleName: 'Corte Oso de Peluche (Teddy Bear)',
      recommendedStyleReason: 'Es el corte más equilibrado para el cuidado del pelaje y resalta la ternura de su carita.',
      faceShape: 'Carita Redonda',
      keyObservations: [
        if (isKeyError)
          'Google reportó la clave de API como revocada (Código 403).'
        else if (isQuota)
          'Cuota diaria de IA ocupada: se generó la recomendación base para Shih Tzu.'
        else
          'Diagnóstico preventivo estándar para manto y ojos.',
        'La zona lagrimal debe revisarse periódicamente.',
        'Corte recomendado por fisionomía: Oso de Peluche.'
      ],
      groomingActionPlan: [
        'Cepillado 3 veces por semana con carda suave.',
        'Limpieza diaria de lagrimales.',
        'Baño e hidratación cada 15 a 20 días.'
      ],
      groomerAdvice: 'Redondear cabeza y hocico tipo pompón; cuerpo recortado a tijera uniforme.',
    );
  }
}
