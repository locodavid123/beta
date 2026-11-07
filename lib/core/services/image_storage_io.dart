import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

Future<Uint8List> readImagePath(String path) async {
  final uri = Uri.tryParse(path);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    final response = await http.get(uri).timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'No se pudo descargar la imagen (HTTP ${response.statusCode}).',
        uri: uri,
      );
    }
    return response.bodyBytes;
  }
  return File(path).readAsBytes();
}
