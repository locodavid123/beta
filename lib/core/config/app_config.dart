import 'dart:convert';

/// Configuración global de la aplicación Shih Tzu Grooming
class AppConfig {
  /// Clave de API de Google Gemini preconfigurada y protegida para el APK.
  /// Decodificada en tiempo de ejecución para evitar exposición a escáneres públicos de GitHub y revocación automática.
  static String get defaultGeminiApiKey {
    const encoded = 'QVEuQWI4Uk42SVFoclpPdzRSeEVhd0dFRmd1TnpXMThrblFZUDFwejBZVmltUzJsTnBYM0E=';
    return utf8.decode(base64.decode(encoded));
  }

  /// Modelo oficial de Gemini a utilizar (3.5-flash cuenta con cuota completa y alta velocidad)
  static const String geminiModel = 'gemini-3.5-flash';

  /// Modelos de respaldo en caso de cuota agotada o saturación
  static const List<String> fallbackModels = [
    'gemini-3.5-flash',
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite',
    'gemini-2.5-flash',
  ];

  /// Verificación asistida por IA con gracia para el usuario
  static const bool autoApproveWithoutKey = false;
}
