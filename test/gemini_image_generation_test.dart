import 'dart:convert';
import 'dart:typed_data';

import 'package:beta/core/services/gemini_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test(
    'grooming generation sends the dog and style reference images',
    () async {
      final dogImage = Uint8List.fromList([1, 2, 3]);
      final styleImage = Uint8List.fromList([4, 5, 6]);
      final client = _ImageGenerationClient({
        'outputs': [
          {
            'type': 'image',
            'mime_type': 'image/png',
            'data': base64Encode([7, 8, 9]),
          },
        ],
      });

      final result = await GeminiService.generateGroomingSimulation(
        dogImage: dogImage,
        dogImagePath: 'dog.jpg',
        styleReferenceImage: styleImage,
        styleImagePath: 'style.png',
        petName: 'Luna',
        breed: 'Shih Tzu',
        styleName: 'Corte cachorro',
        styleDescription: 'Corte corto uniforme',
        stylePromptTemplate: '',
        coatColor: 'Dorado y blanco',
        apiKey: 'test-key',
        client: client,
      );

      expect(client.request, isNotNull);
      final body = jsonDecode(client.request!.body) as Map<String, dynamic>;
      expect(body['model'], GeminiService.imageGenerationModel);
      final input = body['input'] as List<dynamic>;
      expect(input, hasLength(3));
      expect(input[1]['data'], base64Encode(dogImage));
      expect(input[1]['mime_type'], 'image/jpeg');
      expect(input[2]['data'], base64Encode(styleImage));
      expect(input[2]['mime_type'], 'image/png');
      expect(result.bytes, [7, 8, 9]);
      expect(result.mimeType, 'image/png');
    },
  );

  test('image response parser rejects responses without generated images', () {
    expect(
      () => GeneratedImageResult.fromApiResponse({'outputs': []}),
      throwsFormatException,
    );
  });
}

class _ImageGenerationClient extends http.BaseClient {
  _ImageGenerationClient(this.responseBody);

  final Map<String, dynamic> responseBody;
  http.Request? request;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    this.request = request as http.Request;
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(responseBody))),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}
