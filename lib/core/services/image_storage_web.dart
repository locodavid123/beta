// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

Future<Uint8List> readImagePath(String path) async {
  if (path.startsWith('data:')) {
    final comma = path.indexOf(',');
    if (comma < 0) {
      throw const FormatException('Invalid image data URL.');
    }
    return base64Decode(path.substring(comma + 1));
  }

  final request = await html.HttpRequest.request(
    path,
    responseType: 'arraybuffer',
  );
  final response = request.response;
  if (response is ByteBuffer) {
    return response.asUint8List();
  }
  throw const FormatException('The image response was not binary data.');
}

Future<String> saveImageBytes(Uint8List bytes, String mimeType) async =>
    'data:$mimeType;base64,${base64Encode(bytes)}';
