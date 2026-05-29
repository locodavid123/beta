import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/theme/app_theme.dart';

class RootConfigScreen extends StatefulWidget {
  const RootConfigScreen({super.key});

  @override
  State<RootConfigScreen> createState() => _RootConfigScreenState();
}

class _RootConfigScreenState extends State<RootConfigScreen> {
  final _apiKeyController = TextEditingController();
  
  // Simulated System Flags (in memory or SharedPreferences)
  bool _publicRegistration = true;
  bool _maintenanceMode = false;

  @override
  void initState() {
    super.initState();
    final state = Provider.of<AppStateProvider>(context, listen: false);
    _apiKeyController.text = state.geminiApiKey;
    _loadSystemFlags();
  }

  Future<void> _loadSystemFlags() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _publicRegistration = prefs.getBool('flag_public_registration') ?? true;
      _maintenanceMode = prefs.getBool('flag_maintenance_mode') ?? false;
    });
  }

  Future<void> _saveFlag(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
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
                'Ingresa tu clave de Google Gemini para habilitar respuestas de IA generativas globales del sistema.',
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
              onPressed: () async {
                await state.setGeminiApiKey(_apiKeyController.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Clave de API guardada con éxito.')),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
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
        title: const Text('Configuración del Sistema', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        children: [
          // API & Servicios
          _buildSectionHeader('API & SERVICIOS'),
          _buildCard([
            _buildActionTile(
              icon: Icons.key_outlined,
              title: 'Gemini API Key',
              subtitle: state.geminiApiKey.isNotEmpty ? '••••••••••••••••' : 'Configurar clave de IA',
              onTap: _showApiKeyDialog,
            ),
            _buildDivider(isDark),
            _buildStatusTile(
              icon: Icons.cloud_queue_outlined,
              title: 'Firebase Project',
              subtitle: 'shitzu-5820f',
              statusLabel: 'Activo',
              statusColor: AppTheme.greenAccent,
            ),
            _buildDivider(isDark),
            _buildStatusTile(
              icon: Icons.storage_outlined,
              title: 'Firebase Storage',
              subtitle: 'Almacenamiento de imágenes',
              statusLabel: 'Activo',
              statusColor: AppTheme.greenAccent,
            ),
            _buildDivider(isDark),
            _buildStatusTile(
              icon: Icons.verified_user_outlined,
              title: 'App Check',
              subtitle: 'Verificación de seguridad',
              statusLabel: 'Activo',
              statusColor: AppTheme.greenAccent,
            ),
          ]),
          const SizedBox(height: 24),

          // Acceso & Flags
          _buildSectionHeader('ACCESO & FLAGS'),
          _buildCard([
            _buildSwitchTile(
              icon: Icons.person_add_alt_outlined,
              title: 'Registro público',
              subtitle: 'Permitir nuevos registros',
              value: _publicRegistration,
              onChanged: (val) {
                setState(() {
                  _publicRegistration = val;
                });
                _saveFlag('flag_public_registration', val);
              },
            ),
            _buildDivider(isDark),
            _buildSwitchTile(
              icon: Icons.engineering_outlined,
              title: 'Modo mantenimiento',
              subtitle: 'Desactivar app a usuarios',
              value: _maintenanceMode,
              onChanged: (val) {
                setState(() {
                  _maintenanceMode = val;
                });
                _saveFlag('flag_maintenance_mode', val);
              },
            ),
            _buildDivider(isDark),
            _buildActionTile(
              icon: Icons.language_outlined,
              title: 'CORS permitidos',
              subtitle: 'http://shitzu-5820f.web.app/',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Configuración de dominios CORS (Detallada)')),
                );
              },
            ),
          ]),
          const SizedBox(height: 24),

          // Zona de Peligro
          _buildSectionHeader('ZONA DE PELIGRO'),
          _buildCard([
            _buildActionTile(
              icon: Icons.settings_backup_restore,
              iconColor: AppTheme.redAccent,
              title: 'Resetear datos de prueba',
              subtitle: 'Limpiar base de datos y restaurar estilos originales',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('¿Resetear base de datos?'),
                    content: const Text('Esta acción restaurará la base de datos a sus valores iniciales limpiando el historial.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await state.clearHistory();
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('mock_styles');
                          await prefs.remove('mock_pets');
                          await prefs.remove('mock_tutorials');
                          await prefs.remove('mock_reports');
                          await state.refreshAllData();
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Base de datos restablecida con éxito.')),
                            );
                          }
                        },
                        child: const Text('Restablecer', style: TextStyle(color: AppTheme.redAccent)),
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
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
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

  Widget _buildActionTile({
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
      trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildStatusTile({
    required IconData icon,
    Color iconColor = AppTheme.primaryColor,
    required String title,
    required String subtitle,
    required String statusLabel,
    required Color statusColor,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          statusLabel,
          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
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
}
