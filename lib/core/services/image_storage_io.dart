import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<Uint8List> readImagePath(String path) => File(path).readAsBytes();

Future<String> saveImageBytes(Uint8List bytes, String mimeType) async {
  final directory = await getApplicationDocumentsDirectory();
  final extension = switch (mimeType) {
    'image/jpeg' => 'jpg',
    'image/webp' => 'webp',
    _ => 'png',
  };
  final path =
      '${directory.path}${Platform.pathSeparator}grooming_${DateTime.now().microsecondsSinceEpoch}.$extension';
  await File(path).writeAsBytes(bytes, flush: true);
  return path;
}
