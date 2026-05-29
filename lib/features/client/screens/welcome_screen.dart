import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgDark : AppTheme.bgLight,
        ),
        child: Column(
          children: [
            // Upper Purple Area
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(0),
                    bottomRight: Radius.circular(0),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // White Rounded Icon Card
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            width: 60,
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Title
                      Text(
                        'Stylize Me',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 34,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: 8),
                      // Subtitle
                      Text(
                        'Transforma a tu mascota\nen obra de arte con IA',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Row of badges
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildBadge(
                            context,
                            '✨ Gemini AI',
                            const Color(0xFFFFF3CD),
                            const Color(0xFF856404),
                          ),
                          const SizedBox(width: 8),
                          _buildBadge(
                            context,
                            '🎨 Estilos únicos',
                            const Color(0xFFE2E3E5),
                            const Color(0xFF383D41),
                          ),
                          const SizedBox(width: 8),
                          _buildBadge(
                            context,
                            '🐕 Shih Tzu',
                            const Color(0xFFD1ECF1),
                            const Color(0xFF0C5460),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom White Card
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(36),
                    topRight: Radius.circular(36),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        // Welcome text
                        Text(
                          'Bienvenido a Stylize Me',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontSize: 24,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'La app para reimaginar a tu Shih Tzu con estilos artísticos únicos generados por inteligencia artificial.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                    
                    Column(
                      children: [
                        // Comenzar ahora
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RegisterScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Comenzar ahora',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Iniciar sesión
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                                width: 1.5,
                              ),
                              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.06),
                              foregroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Ya tengo cuenta → Iniciar sesión',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Terms and conditions
                    Text(
                      'Al continuar aceptas nuestros Términos y Condiciones',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
