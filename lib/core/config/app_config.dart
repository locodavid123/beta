/// Configuración global de la aplicación Shih Tzu Grooming
class AppConfig {
  /// Clave de API de Google Gemini permanente para el APK.
  /// Grabada de fábrica para que ningún usuario nuevo necesite ingresarla;
  /// queda activa y permanente desde el primer segundo de instalación.
  static const String defaultGeminiApiKey = 'AIzaSyBFWudgJBWvzc1uJiZxOOLE1lJAtnX3D5A';

  /// Cuando está en true, si la clave no estuviera o fallara la conexión,
  /// la app valida automáticamente al perrito de forma transparente y amigable,
  /// sin mostrar alertas técnicas ni interrumpir al usuario.
  static const bool autoApproveWithoutKey = true;
}
