import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/auth_gate.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../root/screens/root_dashboard_screen.dart';
import 'settings_screen.dart';
import 'add_pet_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Upper Purple Area
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Stack(
                children: [
                  // Settings icon top right
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white, size: 24),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                      },
                    ),
                  ),
                  
                  // Profile details in column
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Circular initials VL with camera icon
                        Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.2),
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: Center(
                                child: Text(
                                  state.userName.isNotEmpty
                                      ? state.userName.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                                      : 'VL',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            // Yellow camera overlay
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.goldAccent,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // User Name
                        Text(
                          state.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Email
                        Text(
                          state.userEmail,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Statistics Line (Creaciones, Mascotas, Créditos)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                elevation: 0,
                color: isDark ? AppTheme.cardDark : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn('${state.creations.length}', 'Creaciones'),
                      _buildDivider(isDark),
                      _buildStatColumn('${state.pets.length}', 'Mascotas'),
                      _buildDivider(isDark),
                      _buildStatColumn('${state.credits}', 'Créditos'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Mis Mascotas section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mis Mascotas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddPetScreen()),
                      );
                    },
                    icon: const Icon(Icons.add, size: 16, color: AppTheme.primaryColor),
                    label: const Text(
                      'Agregar',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Mascotas list
            state.pets.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Text(
                      'No tienes mascotas registradas.',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: state.pets.length,
                    itemBuilder: (context, index) {
                      final pet = state.pets[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.01),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                pet.imagePath,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pet.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${pet.breed} • ${pet.age}',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Editar ${pet.name} (Simulado)')),
                                );
                              },
                              child: const Text(
                                'Editar',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 24),

            if (state.userRole == 'admin' || state.userRole == 'root') ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Administración',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: _buildAccountItem(
                    context,
                    icon: Icons.admin_panel_settings_outlined,
                    iconColor: AppTheme.goldAccent,
                    title: state.userRole == 'root' ? 'Volver al Panel Root' : 'Volver al Panel Admin',
                    subtitle: 'Regresar a la consola de administración',
                    onTap: () {
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
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Cuenta section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Cuenta',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildAccountItem(
                      context,
                      icon: Icons.person_outline,
                      title: 'Editar perfil',
                      subtitle: 'Nombre y datos personales',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Editar perfil (Simulado)')),
                        );
                      },
                    ),
                    _buildDivider(isDark, horizontal: true),
                    _buildAccountItem(
                      context,
                      icon: Icons.lock_outline,
                      title: 'Privacidad',
                      subtitle: 'Contraseña y seguridad',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Privacidad (Simulado)')),
                        );
                      },
                    ),
                    _buildDivider(isDark, horizontal: true),
                    _buildAccountItem(
                      context,
                      icon: Icons.settings_outlined,
                      title: 'Ajustes',
                      subtitle: 'Preferencias de la aplicación',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                      },
                    ),
                    _buildDivider(isDark, horizontal: true),
                    _buildAccountItem(
                      context,
                      icon: Icons.logout_outlined,
                      iconColor: AppTheme.redAccent,
                      title: 'Cerrar sesión',
                      titleColor: AppTheme.redAccent,
                      subtitle: 'Salir de la aplicación',
                      onTap: () {
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark, {bool horizontal = false}) {
    if (horizontal) {
      return Divider(
        height: 1,
        color: isDark ? Colors.grey[800] : Colors.grey[200],
      );
    }
    return Container(
      width: 1,
      height: 30,
      color: isDark ? Colors.grey[800] : Colors.grey[200],
    );
  }

  Widget _buildAccountItem(
    BuildContext context, {
    required IconData icon,
    Color iconColor = AppTheme.primaryColor,
    required String title,
    Color? titleColor,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: titleColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }
}
