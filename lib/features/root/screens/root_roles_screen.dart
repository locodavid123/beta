import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'root_users_screen.dart';

class RootRolesScreen extends StatelessWidget {
  const RootRolesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Roles & Permisos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Jerarquía de acceso del sistema',
                style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              // Root Card
              _buildHierarchyCard(
                context,
                title: 'Root',
                badgeText: 'SUPER',
                badgeColor: AppTheme.goldAccent,
                description: 'Control total del sistema. Sin restricciones.',
                permissions: [
                  'Gestionar todos los usuarios',
                  'Modificar configuración del sistema',
                  'Ver logs completos',
                  'Asignar roles',
                  'Acceso a zona de peligro',
                ],
                cardBorderColor: AppTheme.goldAccent,
                isDark: isDark,
              ),
              const SizedBox(height: 18),

              // Admin Card
              _buildHierarchyCard(
                context,
                title: 'Admin',
                description: 'Gestión de contenido y usuarios clientes.',
                permissions: [
                  'Gestionar estilos y tutoriales',
                  'Ver historial global',
                  'Moderar contenido',
                  'Ver métricas básicas',
                ],
                isDark: isDark,
              ),
              const SizedBox(height: 18),

              // Cliente Card
              _buildHierarchyCard(
                context,
                title: 'Cliente',
                description: 'Acceso a funciones de usuario final.',
                permissions: [
                  'Subir fotos de mascotas',
                  'Generar estilos con IA',
                  'Ver su historial',
                  'Editar su perfil',
                ],
                isDark: isDark,
              ),
              const SizedBox(height: 32),

              // Assign Role Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to root users screen to manage roles
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RootUsersScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F0A1C), // Deep Indigo / Dark Purple
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Asignar rol a usuario',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHierarchyCard(
    BuildContext context, {
    required String title,
    String? badgeText,
    Color? badgeColor,
    required String description,
    required List<String> permissions,
    Color? cardBorderColor,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: cardBorderColor != null
            ? Border.all(color: cardBorderColor.withValues(alpha: 0.6), width: 1.5)
            : Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 8),
              if (badgeText != null && badgeColor != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Permissions Bullet Points
          ...permissions.map((perm) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check, color: AppTheme.greenAccent, size: 14),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      perm,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
