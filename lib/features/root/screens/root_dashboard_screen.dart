import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/auth_gate.dart';
import '../../client/screens/navigation_holder.dart';
import '../../admin/screens/admin_catalog_screen.dart';
import '../../admin/screens/admin_tutorials_screen.dart';
import 'root_users_screen.dart';
import 'root_config_screen.dart';
import 'root_logs_screen.dart';
import 'root_roles_screen.dart';

class RootDashboardScreen extends StatefulWidget {
  const RootDashboardScreen({super.key});

  @override
  State<RootDashboardScreen> createState() => _RootDashboardScreenState();
}

class _RootDashboardScreenState extends State<RootDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final adminsCount = 3;
    final usersCount = 127;
    final stylesCount = state.styles.length;
    final simsCount = 838 + state.creations.length;

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
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const RootDashboardScreen()),
              (route) => false,
            );
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Panel de Control Root',
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
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const RootDashboardScreen()),
                  (route) => false,
                );
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
                    content: const Text('¿Estás seguro de que quieres salir del Panel Root?'),
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
                    child: const Center(
                      child: Text(
                        'RA',
                        style: TextStyle(
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
                    child: const Text(
                      'ROOT',
                      style: TextStyle(
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
            // Warning box (Acceso Total del Sistema)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.redAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.redAccent.withValues(alpha: 0.2), width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.redAccent, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Acceso Total del Sistema',
                          style: TextStyle(
                            color: AppTheme.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tienes control completo sobre todos los módulos, usuarios y configuraciones de Shih Tzu App.',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats grid row (Panel 1)
            Row(
              children: [
                _buildStatBlock(
                  context,
                  title: '$adminsCount',
                  subtitle: 'Admins',
                  icon: Icons.admin_panel_settings_outlined,
                  iconColor: Colors.deepPurpleAccent,
                ),
                const SizedBox(width: 10),
                _buildStatBlock(
                  context,
                  title: '$usersCount',
                  subtitle: 'Usuarios',
                  icon: Icons.group_outlined,
                  iconColor: Colors.blueAccent,
                ),
                const SizedBox(width: 10),
                _buildStatBlock(
                  context,
                  title: '$stylesCount',
                  subtitle: 'Estilos',
                  icon: Icons.palette_outlined,
                  iconColor: Colors.orangeAccent,
                ),
                const SizedBox(width: 10),
                _buildStatBlock(
                  context,
                  title: '$simsCount',
                  subtitle: 'Sims',
                  icon: Icons.auto_awesome_outlined,
                  iconColor: Colors.greenAccent,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Módulos del Sistema
            Text(
              'Módulos del Sistema',
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
                  _buildModuleItem(
                    context,
                    icon: Icons.people_outline_outlined,
                    iconColor: Colors.blueAccent,
                    title: 'Gestión de Usuarios',
                    subtitle: 'Clientes, admins y roles',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RootUsersScreen()),
                      );
                    },
                  ),
                  _buildDivider(isDark),
                  _buildModuleItem(
                    context,
                    icon: Icons.palette_outlined,
                    iconColor: Colors.orangeAccent,
                    title: 'Gestión de Estilos',
                    subtitle: 'Catálogo de estilos artísticos',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminCatalogScreen()),
                      );
                    },
                  ),
                  _buildDivider(isDark),
                  _buildModuleItem(
                    context,
                    icon: Icons.video_collection_outlined,
                    iconColor: Colors.pinkAccent,
                    title: 'Tutoriales',
                    subtitle: 'Vídeos de peluquería',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminTutorialsScreen()),
                      );
                    },
                  ),
                  _buildDivider(isDark),
                  _buildModuleItem(
                    context,
                    icon: Icons.settings_outlined,
                    iconColor: Colors.teal,
                    title: 'API & Configuración',
                    subtitle: 'Gemini API Key, flags del sistema',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RootConfigScreen()),
                      );
                    },
                  ),
                  _buildDivider(isDark),
                  _buildModuleItem(
                    context,
                    icon: Icons.bar_chart_outlined,
                    iconColor: Colors.indigoAccent,
                    title: 'Logs & Métricas',
                    subtitle: 'Actividad de sistema en tiempo real',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RootLogsScreen()),
                      );
                    },
                  ),
                  _buildDivider(isDark),
                  _buildModuleItem(
                    context,
                    icon: Icons.security_outlined,
                    iconColor: AppTheme.goldAccent,
                    title: 'Roles & Permisos',
                    subtitle: 'Asignar root, admin, cliente',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RootRolesScreen()),
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
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

  Widget _buildModuleItem(
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
