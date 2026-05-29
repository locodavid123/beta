import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/auth_gate.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = Provider.of<AppStateProvider>(context, listen: false);
    _apiKeyController.text = state.geminiApiKey;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  void _showApiKeyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final state = Provider.of<AppStateProvider>(context);
        return AlertDialog(
          title: const Text('API Key de Gemini'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ingresa tu clave personal de Google Gemini para habilitar respuestas personalizadas e interacciones de IA reales.',
                style: TextStyle(fontSize: 13, height: 1.3),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _apiKeyController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                state.setGeminiApiKey(_apiKeyController.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('API Key guardada con éxito.')),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final state = Provider.of<AppStateProvider>(context);
        return SimpleDialog(
          title: const Text('Seleccionar Idioma'),
          children: ['Español', 'English', 'Português'].map((lang) {
            return SimpleDialogOption(
              onPressed: () {
                state.setLanguage(lang);
                Navigator.pop(context);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(lang),
                  if (state.language == lang)
                    const Icon(Icons.check, color: AppTheme.primaryColor),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showQualityDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final state = Provider.of<AppStateProvider>(context);
        return SimpleDialog(
          title: const Text('Calidad de Imagen'),
          children: ['Baja (rápido)', 'Media', 'Alta (más lento)'].map((q) {
            return SimpleDialogOption(
              onPressed: () {
                state.setImageQuality(q);
                Navigator.pop(context);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(q),
                  if (state.imageQuality == q)
                    const Icon(Icons.check, color: AppTheme.primaryColor),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        children: [
          // APARIENCIA
          _buildSectionHeader('Apariencia'),
          _buildSettingCard([
            _buildSwitchTile(
              icon: Icons.dark_mode_outlined,
              title: 'Modo Oscuro',
              subtitle: 'Tema de la aplicación',
              value: state.isDarkMode,
              onChanged: (val) => state.toggleDarkMode(val),
            ),
            _buildDivider(isDark),
            _buildNavigationTile(
              icon: Icons.language_outlined,
              title: 'Idioma',
              trailingText: state.language,
              onTap: _showLanguageDialog,
            ),
          ]),
          const SizedBox(height: 24),

          // NOTIFICACIONES
          _buildSectionHeader('Notificaciones'),
          _buildSettingCard([
            _buildSwitchTile(
              icon: Icons.notifications_active_outlined,
              title: 'Notificaciones push',
              subtitle: 'Alertas de la app',
              value: state.pushNotifications,
              onChanged: (val) => state.setPushNotifications(val),
            ),
            _buildDivider(isDark),
            _buildSwitchTile(
              icon: Icons.mail_outline_outlined,
              title: 'Correos',
              subtitle: 'Novedades y ofertas',
              value: state.emailNotifications,
              onChanged: (val) => state.setEmailNotifications(val),
            ),
          ]),
          const SizedBox(height: 24),

          // IA & GENERACIÓN
          _buildSectionHeader('IA & Generación'),
          _buildSettingCard([
            _buildNavigationTile(
              icon: Icons.tune_outlined,
              title: 'Calidad de imagen',
              trailingText: state.imageQuality,
              onTap: _showQualityDialog,
            ),
            _buildDivider(isDark),
            _buildNavigationTile(
              icon: Icons.key_outlined,
              title: 'API Key de Gemini',
              trailingText: state.geminiApiKey.isNotEmpty ? '••••••••' : 'Configurar',
              onTap: _showApiKeyDialog,
            ),
          ]),
          const SizedBox(height: 24),

          // CUENTA
          _buildSectionHeader('Cuenta'),
          _buildSettingCard([
            _buildNavigationTile(
              icon: Icons.delete_sweep_outlined,
              iconColor: AppTheme.redAccent,
              title: 'Limpiar historial',
              trailingText: 'Borrar creaciones locales',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('¿Limpiar historial?'),
                    content: const Text('Esta acción borrará todas tus creaciones guardadas localmente. No se puede deshacer.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          state.clearHistory();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Historial limpiado con éxito.')),
                          );
                        },
                        child: const Text('Borrar todo', style: TextStyle(color: AppTheme.redAccent)),
                      ),
                    ],
                  ),
                );
              },
            ),
            _buildDivider(isDark),
            _buildNavigationTile(
              icon: Icons.logout_outlined,
              iconColor: AppTheme.redAccent,
              title: 'Cerrar sesión',
              titleColor: AppTheme.redAccent,
              trailingText: '',
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
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingCard(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: isDark ? AppTheme.cardDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 48,
      endIndent: 12,
      color: isDark ? Colors.grey[800] : Colors.grey[100],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.grey, fontSize: 11),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    Color iconColor = AppTheme.primaryColor,
    required String title,
    Color? titleColor,
    required String trailingText,
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
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: titleColor,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            trailingText,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[400]),
        ],
      ),
      onTap: onTap,
    );
  }
}
