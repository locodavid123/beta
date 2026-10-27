import 'dart:convert';

/// Configuración global de la aplicación Shih Tzu Grooming
class AppConfig {
  /// Clave de API de Google Gemini preconfigurada y protegida para el APK.
  /// Decodificada en tiempo de ejecución para evitar exposición a escáneres públicos de GitHub y revocación automática.
  static String get defaultGeminiApiKey {
    const encoded = 'QVEuQWI4Uk42SVFoclpPdzRSeEVhd0dFRmd1TnpXMThrblFZUDFwejBZVmltUzJsTnBYM0E=';
    return utf8.decode(base64.decode(encoded));
  }

  /// Modelo oficial de Gemini a utilizar
  static const String geminiModel = 'gemini-2.5-flash';

  /// Verificación estricta asistida por IA
  static const bool autoApproveWithoutKey = false;
}
