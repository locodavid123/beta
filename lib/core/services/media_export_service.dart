import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class MediaExportService {
  /// Resolves an image path (either assets/... or local file) and returns its raw bytes.
  static Future<Uint8List> getImageBytes(String imagePath) async {
    if (imagePath.startsWith('assets/')) {
      final byteData = await rootBundle.load(imagePath);
      return byteData.buffer.asUint8List();
    } else {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception("El archivo de imagen no existe: $imagePath");
      }
      return await file.readAsBytes();
    }
  }

  /// Copies or extracts the image to a temporary file suitable for sharing or saving.
  static Future<File> getExportableFile(String imagePath, {String? customFileName}) async {
    final bytes = await getImageBytes(imagePath);
    final tempDir = await getTemporaryDirectory();
    final fileName = customFileName ?? 'shih_tzu_cut_${DateTime.now().millisecondsSinceEpoch}.png';
    final targetFile = File('${tempDir.path}/$fileName');
    await targetFile.writeAsBytes(bytes);
    return targetFile;
  }

  /// Saves the image to the device's documents or downloads folder.
  /// Returns the absolute path where the file was saved.
  static Future<String> saveImageToDevice({
    required String imagePath,
    required String petName,
    required String styleName,
  }) async {
    try {
      final bytes = await getImageBytes(imagePath);
      
      Directory? targetDir;
      try {
        if (!kIsWeb && Platform.isAndroid) {
          targetDir = await getExternalStorageDirectory();
        }
      } catch (_) {}

      targetDir ??= await getApplicationDocumentsDirectory();

      // Clean file name
      final safePet = petName.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(' ', '_');
      final safeStyle = styleName.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(' ', '_');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'ShihTzu_${safePet}_${safeStyle}_$timestamp.png';

      final savedFile = File('${targetDir.path}/$fileName');
      await savedFile.writeAsBytes(bytes);

      if (kDebugMode) {
        print("Image saved successfully to: ${savedFile.path}");
      }
      return savedFile.path;
    } catch (e) {
      if (kDebugMode) {
        print("Error saving image: $e");
      }
      rethrow;
    }
  }

  /// Shares the creation (image + text description) using the system share sheet.
  static Future<void> shareCreation({
    required String imagePath,
    required String petName,
    required String styleName,
    String? customText,
  }) async {
    try {
      final safePet = petName.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(' ', '_');
      final safeStyle = styleName.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(' ', '_');
      final fileName = 'ShihTzu_${safePet}_$safeStyle.png';

      final file = await getExportableFile(imagePath, customFileName: fileName);
      final shareText = customText ??
          '¡Mira cómo luce $petName con el corte "$styleName" diseñado en Shih Tzu App! 🐕✂️✨';

      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: 'Corte de Estilismo Shih Tzu: $styleName',
          files: [XFile(file.path, mimeType: 'image/png', name: fileName)],
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print("Error sharing creation: $e");
      }
      // Fallback to text-only share if file share fails
      final fallbackText = customText ??
          '¡Mira cómo luce $petName con el corte "$styleName" diseñado en Shih Tzu App! 🐕✂️';
      await SharePlus.instance.share(
        ShareParams(text: fallbackText),
      );
    }
  }
}
