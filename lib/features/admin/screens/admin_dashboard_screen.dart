import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/auth_gate.dart';
import 'admin_catalog_screen.dart';
import 'admin_history_screen.dart';
import 'admin_tutorials_screen.dart';
import 'admin_moderation_screen.dart';
import 'admin_users_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final usersCount = 127;
    final stylesCount = state.styles.length;
    final simsCount = 838 + state.creations.length;
    final tutorialsCount = state.tutorials.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              state.userRole == 'root' ? 'Panel Root' : 'Panel ADMIN',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              state.userRole == 'root' ? 'Superusuario' : 'Administrador General',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        centerTitle: true,
        automaticallyImplyLeading: false, // No back navigation
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('¿Cerrar sesión?'),
                  content: const Text('¿Estás seguro de que quieres salir de la aplicación?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await state.logoutUser();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const AuthGate()),
                            (route) => false,
                          );
                        }
                      },
                      child: const Text('Salir', style: TextStyle(color: AppTheme.redAccent)),
                    ),
                  ],
                ),
              );
            },
          ),
          // Admin Avatar
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryLight.withValues(alpha: 0.2),
              border: Border.all(color: AppTheme.primaryLight, width: 1.5),
            ),
            child: Center(
              child: Text(
                state.userRole == 'root' ? 'RT' : 'AG',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Text(
              state.userRole == 'root' 
                  ? 'Bienvenido, Superusuario.' 
                  : 'Bienvenido, Admin General.',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 4),
            const Text(
              'Gestiona el contenido y usuarios de Stylize Me.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Stats Grid Row (Panel 1 layout)
            Row(
              children: [
                _buildStatBlock(
                  context,
                  title: '$usersCount',
                  subtitle: 'Usuarios',
                  icon: Icons.group_outlined,
                  iconColor: Colors.blueAccent,
                ),
                const SizedBox(width: 12),
                _buildStatBlock(
                  context,
                  title: '$stylesCount',
                  subtitle: 'Estilos',
                  icon: Icons.palette_outlined,
                  iconColor: Colors.orangeAccent,
                ),
                const SizedBox(width: 12),
                _buildStatBlock(
                  context,
                  title: '$simsCount',
                  subtitle: 'Simulaciones',
                  icon: Icons.auto_awesome_outlined,
                  iconColor: Colors.greenAccent,
                ),
                const SizedBox(width: 12),
                _buildStatBlock(
                  context,
                  title: '$tutorialsCount',
                  subtitle: 'Tutoriales',
                  icon: Icons.video_collection_outlined,
                  iconColor: Colors.pinkAccent,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Herramientas de Gestión
            Text(
              'Herramientas de Gestión',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildToolItem(
                    context,
                    icon: Icons.palette_outlined,
                    iconColor: AppTheme.primaryColor,
                    title: 'Gestionar Catálogo',
                    subtitle: 'Crear, editar y eliminar estilos',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminCatalogScreen()),
                      );
                    },
                  ),
                  _buildDivider(isDark),
                  _buildToolItem(
                    context,
                    icon: Icons.history_edu_outlined,
                    iconColor: Colors.orangeAccent,
                    title: 'Historial Global',
                    subtitle: 'Ver todas las simulaciones',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminHistoryScreen()),
                      );
                    },
                  ),
                  _buildDivider(isDark),
                  _buildToolItem(
                    context,
                    icon: Icons.video_collection_outlined,
                    iconColor: Colors.pinkAccent,
                    title: 'Gestionar Tutoriales',
                    subtitle: 'Vídeos educativos de peluquería',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminTutorialsScreen()),
                      );
                    },
                  ),
                  _buildDivider(isDark),
                  _buildToolItem(
                    context,
                    icon: Icons.gavel_outlined,
                    iconColor: AppTheme.redAccent,
                    title: 'Moderación',
                    subtitle: 'Comentarios y reportes',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminModerationScreen()),
                      );
                    },
                  ),
                  _buildDivider(isDark),
                  _buildToolItem(
                    context,
                    icon: Icons.bar_chart_outlined,
                    iconColor: Colors.teal,
                    title: 'Estadísticas',
                    subtitle: 'Métricas de uso de la plataforma',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminModerationScreen()),
                      );
                    },
                  ),
                  _buildDivider(isDark),
                  _buildToolItem(
                    context,
                    icon: Icons.people_outline_outlined,
                    iconColor: Colors.blueAccent,
                    title: 'Usuarios Clientes',
                    subtitle: 'Ver y gestionar cuentas de clientes',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminUsersScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBlock(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolItem(
    BuildContext context, {
    required IconData icon,
    Color iconColor = AppTheme.primaryColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.grey, fontSize: 11),
      ),
      trailing: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.arrow_forward_ios, size: 12, color: iconColor),
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 56,
      endIndent: 12,
      color: isDark ? Colors.grey[800] : Colors.grey[100],
    );
  }
}
