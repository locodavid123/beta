import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/auth_gate.dart';
import '../../client/screens/navigation_holder.dart';
import '../../root/screens/root_dashboard_screen.dart';
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
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (state.userRole == 'root') {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const RootDashboardScreen()),
                (route) => false,
              );
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                (route) => false,
              );
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Panel de Administración',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
            ),
            Text(
              state.userRole == 'root' ? 'Superusuario' : 'Admin General',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'home') {
                if (state.userRole == 'root') {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const RootDashboardScreen()),
                    (route) => false,
                  );
                } else {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                    (route) => false,
                  );
                }
              } else if (value == 'client') {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const NavigationHolder()),
                  (route) => false,
                );
              } else if (value == 'logout') {
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
              }
            },
            offset: const Offset(0, 48),
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'home',
                child: Row(
                  children: [
                    Icon(Icons.home_outlined, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Volver al panel principal'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'client',
                child: Row(
                  children: [
                    Icon(Icons.visibility_outlined, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Vista Cliente (Pruebas)'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_outlined, color: AppTheme.redAccent),
                    SizedBox(width: 8),
                    Text('Cerrar sesión', style: TextStyle(color: AppTheme.redAccent)),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                      border: Border.all(color: Colors.white30, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        state.userRole == 'root' ? 'RT' : 'AG',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      state.userRole == 'root' ? 'ROOT' : 'ADMIN',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
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
