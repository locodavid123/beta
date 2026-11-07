import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'image_storage_io.dart'
    if (dart.library.html) 'image_storage_web.dart'
    as storage;
import 'web_camera_stub.dart'
    if (dart.library.html) 'web_camera.dart'
    as web_camera;

Future<XFile?> pickImage(
  BuildContext context,
  ImageSource source, {
  double? maxWidth,
  double? maxHeight,
  int? imageQuality,
}) async {
  if (kIsWeb && source == ImageSource.camera) {
    final bytes = await web_camera.captureWebCamera(context);
    if (bytes == null) return null;
    return XFile.fromData(
      bytes,
      mimeType: 'image/jpeg',
      name: 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }

  return ImagePicker().pickImage(
    source: source,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
    imageQuality: imageQuality,
  );
}

Future<String> persistPickedImage(
  XFile image, {
  bool catalogImage = false,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw StateError('Inicia sesión para guardar imágenes en Firebase.');
  }

  final bytes = await image.readAsBytes();
  final mimeType = image.mimeType ?? _mimeTypeFromName(image.name);
  final extension = image.name.contains('.')
      ? image.name.split('.').last
      : 'jpg';
  final folder = catalogImage ? 'catalog_uploads' : 'user_uploads';
  final reference = FirebaseStorage.instance.ref(
    '$folder/${user.uid}/${DateTime.now().microsecondsSinceEpoch}.$extension',
  );
  final snapshot = await reference.putData(
    bytes,
    SettableMetadata(contentType: mimeType),
  );
  return snapshot.ref.getDownloadURL();
}

String _mimeTypeFromName(String name) {
  final lowerName = name.toLowerCase();
  if (lowerName.endsWith('.png')) return 'image/png';
  if (lowerName.endsWith('.webp')) return 'image/webp';
  if (lowerName.endsWith('.gif')) return 'image/gif';
  return 'image/jpeg';
}

Future<Uint8List> readImageBytes(String path) async {
  final normalizedPath = path.trim();
  if (normalizedPath.startsWith('assets/')) {
    final data = await rootBundle.load(normalizedPath);
    return data.buffer.asUint8List();
  }
  return storage.readImagePath(normalizedPath);
}

class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
  });

  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final imagePath = path.trim();
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: errorBuilder,
      );
    }

    return FutureBuilder<Uint8List>(
      future: readImageBytes(imagePath),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return errorBuilder?.call(
                context,
                snapshot.error!,
                snapshot.stackTrace,
              ) ??
              const Icon(Icons.broken_image_outlined);
        }
        if (!snapshot.hasData) {
          return SizedBox(
            width: width,
            height: height,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return Image.memory(
          snapshot.data!,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: errorBuilder,
        );
      },
    );
  }
}

class PickedImage extends StatelessWidget {
  const PickedImage({
    super.key,
    required this.image,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final XFile image;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: image.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Icon(Icons.broken_image_outlined);
        }
        if (!snapshot.hasData) {
          return SizedBox(
            width: width,
            height: height,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return Image.memory(
          snapshot.data!,
          fit: fit,
          width: width,
          height: height,
        );
      },
    );
  }
}
