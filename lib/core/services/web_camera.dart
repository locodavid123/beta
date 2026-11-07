// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;

import 'package:flutter/material.dart';

int _nextCameraViewId = 0;

Future<Uint8List?> captureWebCamera(BuildContext context) {
  return showDialog<Uint8List>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _WebCameraDialog(),
  );
}

class _WebCameraDialog extends StatefulWidget {
  const _WebCameraDialog();

  @override
  State<_WebCameraDialog> createState() => _WebCameraDialogState();
}

class _WebCameraDialogState extends State<_WebCameraDialog> {
  late final String _viewType;
  late final html.VideoElement _video;
  html.MediaStream? _stream;
  String? _error;
  bool _isStarting = true;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'web-camera-${_nextCameraViewId++}';
    _video = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', 'true')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.backgroundColor = '#111111';

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _video,
    );
    unawaited(_startCamera());
  }

  Future<void> _startCamera() async {
    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        throw StateError('Este navegador no permite acceder a la cámara.');
      }

      final stream = await mediaDevices.getUserMedia({
        'video': {'facingMode': 'environment'},
        'audio': false,
      });

      if (!mounted) {
        for (final track in stream.getTracks()) {
          track.stop();
        }
        return;
      }

      _stream = stream;
      _video.srcObject = stream;
      await _video.play();
      if (mounted) {
        setState(() => _isStarting = false);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isStarting = false;
          _error = _cameraErrorMessage(error);
        });
      }
    }
  }

  String _cameraErrorMessage(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('notallowed') || text.contains('permission')) {
      return 'Permite el acceso a la cámara en el navegador y vuelve a intentarlo.';
    }
    if (text.contains('notfound') || text.contains('devicesnotfound')) {
      return 'No se encontró una cámara conectada a este equipo.';
    }
    return 'No se pudo iniciar la cámara. Revisa los permisos del navegador y que otra aplicación no la esté usando.';
  }

  Future<void> _takePhoto() async {
    if (_video.videoWidth == 0 || _video.videoHeight == 0) {
      setState(
        () => _error = 'La cámara todavía no está lista. Inténtalo de nuevo.',
      );
      return;
    }

    setState(() => _isCapturing = true);
    try {
      final canvas = html.CanvasElement(
        width: _video.videoWidth,
        height: _video.videoHeight,
      );
      canvas.context2D.drawImage(_video, 0, 0);
      final blob = await canvas.toBlob('image/jpeg', 0.9);
      final reader = html.FileReader();
      final loaded = reader.onLoad.first;
      reader.readAsDataUrl(blob);
      await loaded;

      final result = reader.result;
      if (result is String && mounted) {
        final comma = result.indexOf(',');
        if (comma < 0) {
          throw StateError('La foto capturada no tiene un formato válido.');
        }
        Navigator.of(context).pop(base64Decode(result.substring(comma + 1)));
      } else {
        throw StateError('No se pudo leer la foto capturada.');
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _error = 'No se pudo tomar la foto: $error';
        });
      }
    }
  }

  void _stopCamera() {
    for (final track in _stream?.getTracks() ?? <html.MediaStreamTrack>[]) {
      track.stop();
    }
    _video.srcObject = null;
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tomar foto'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: HtmlElementView(viewType: _viewType),
              ),
            ),
            if (_isStarting) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _isStarting || _error != null || _isCapturing
              ? null
              : _takePhoto,
          icon: _isCapturing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.camera_alt),
          label: const Text('Capturar'),
        ),
      ],
    );
  }
}
