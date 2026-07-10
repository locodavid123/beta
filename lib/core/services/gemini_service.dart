import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiResult {
  final bool isShihTzu;
  final String breed;
  final String message;

  GeminiResult({
    required this.isShihTzu,
    required this.breed,
    required this.message,
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

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': 'Analiza esta imagen de un perro. Determina si es de raza Shih Tzu (también conocido como Shitzu, Shitsu, Shihtzu o Shih-tzu). '
                      'Sé muy flexible: si el perro es de raza Shih Tzu, o una mezcla donde predomine el Shih Tzu, o se parece mucho, el resultado "isShihTzu" debe ser true. '
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
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        String detail = response.body;
        try {
          final errorJson = jsonDecode(response.body);
          if (errorJson['error']?['message'] != null) {
            detail = errorJson['error']['message'];
          }
        } catch (_) {}
        return GeminiResult(
          isShihTzu: false,
          breed: 'Error',
          message: 'Error de la API de Gemini (Status: ${response.statusCode}). Detalle: $detail',
        );
      }

      final responseBody = jsonDecode(response.body);
      final text = responseBody['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;

      if (text == null || text.trim().isEmpty) {
        return GeminiResult(
          isShihTzu: false,
          breed: 'Desconocido',
          message: 'No se obtuvo respuesta del análisis de imagen.',
        );
      }

      // Robust JSON extraction finding the first { and last }
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
      );
    } catch (e) {
      return GeminiResult(
        isShihTzu: false,
        breed: 'Error',
        message: 'Error al conectar con la verificación de IA: $e',
      );
    }
  }
}
