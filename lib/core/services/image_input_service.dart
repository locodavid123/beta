import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

Future<String> persistPickedImage(XFile image) async {
  if (!kIsWeb) return image.path;
  final bytes = await image.readAsBytes();
  final mimeType = image.mimeType ?? 'image/jpeg';
  return 'data:$mimeType;base64,${base64Encode(bytes)}';
}

Future<String> persistGeneratedImage(Uint8List bytes, String mimeType) =>
    storage.saveImageBytes(bytes, mimeType);

Future<Uint8List> readImageBytes(String path) async {
  if (path.startsWith('assets/')) {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List();
  }
  return storage.readImagePath(path);
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
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: errorBuilder,
      );
    }

    return FutureBuilder<Uint8List>(
      future: readImageBytes(path),
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
