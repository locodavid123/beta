import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../models/style.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _styleNameController = TextEditingController();
  final _styleCategoryController = TextEditingController();
  final _styleDescController = TextEditingController();
  bool _isStyleHot = false;

  @override
  void dispose() {
    _styleNameController.dispose();
    _styleCategoryController.dispose();
    _styleDescController.dispose();
    super.dispose();
  }

  void _showAddStyleDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final state = Provider.of<AppStateProvider>(context);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Agregar Nuevo Estilo'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _styleNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Estilo',
                        hintText: 'Ej: Animé Mágico',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _styleCategoryController,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        hintText: 'Ej: Fantasía, Arte, Sci-Fi',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _styleDescController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        hintText: 'Ej: Colores brillantes, ojos grandes...',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: const Text('¿Estilo Popular? (Hot)'),
                      value: _isStyleHot,
                      onChanged: (val) {
                        setDialogState(() {
                          _isStyleHot = val ?? false;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = _styleNameController.text.trim();
                    final category = _styleCategoryController.text.trim();
                    final desc = _styleDescController.text.trim();
                    if (name.isEmpty || category.isEmpty || desc.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor completa todos los campos.')),
                      );
                      return;
                    }

                    // Choose a random available asset image to represent it
                    // Cycle through assets
                    List<String> images = [
                      'assets/images/realeza_imperial.png',
                      'assets/images/fantasia_cosmica.png',
                      'assets/images/cyberpunk_neon.png',
                      'assets/images/acuarela_suave.png',
                      'assets/images/steampunk.png',
                      'assets/images/kawaii_pastel.png',
                    ];
                    String selectedImg = images[name.length % images.length];

                    await state.registerStyle(
                      name: name,
                      category: category,
                      imagePath: selectedImg,
                      description: desc,
                      isHot: _isStyleHot,
                    );

                    _styleNameController.clear();
                    _styleCategoryController.clear();
                    _styleDescController.clear();
                    _isStyleHot = false;

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Estilo "$name" agregado con éxito.')),
                      );
                    }
                  },
                  child: const Text('Agregar'),
                ),
              ],
            );
          },
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
        title: const Column(
          children: [
            Text('Panel Admin', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Admin General', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Admin Avatar
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryLight.withOpacity(0.2),
              border: Border.all(color: AppTheme.primaryLight, width: 1.5),
            ),
            child: const Center(
              child: Text(
                'AG',
                style: TextStyle(
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
            // Stats Row
            Row(
              children: [
                _buildStatBlock(
                  context,
                  title: '127',
                  subtitle: 'Usuarios',
                  icon: Icons.group,
                  iconColor: Colors.blueAccent,
                ),
                const SizedBox(width: 12),
                _buildStatBlock(
                  context,
                  title: '${state.styles.length}',
                  subtitle: 'Estilos',
                  icon: Icons.palette,
                  iconColor: Colors.orangeAccent,
                ),
                const SizedBox(width: 12),
                _buildStatBlock(
                  context,
                  title: '842',
                  subtitle: 'Sims',
                  icon: Icons.auto_awesome,
                  iconColor: Colors.greenAccent,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Herramientas Section
            Text(
              'Herramientas',
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
                    icon: Icons.add_photo_alternate_outlined,
                    title: 'Gestionar Catálogo',
                    subtitle: 'Crear, editar y eliminar estilos',
                    onTap: _showAddStyleDialog,
                  ),
                  _buildDivider(isDark),
                  _buildToolItem(
                    context,
                    icon: Icons.history_edu_outlined,
                    title: 'Historial Global',
                    subtitle: 'Ver todas las simulaciones',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cargando historial global...')),
                      );
                    },
                  ),
                  _buildDivider(isDark),
                  _buildToolItem(
                    context,
                    icon: Icons.video_collection_outlined,
                    title: 'Tutoriales',
                    subtitle: 'Gestionar vídeos educativos',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Configuración de tutoriales (Simulado)')),
                      );
                    },
                  ),
                  _buildDivider(isDark),
                  _buildToolItem(
                    context,
                    icon: Icons.gavel_outlined,
                    title: 'Moderación',
                    subtitle: 'Comentarios y reportes',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cargando herramientas de moderación...')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Actividad Reciente Section
            Text(
              'Actividad Reciente',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _buildLogItem(
                    text: "usuario@test.com generó 'Realeza Imperial'",
                    time: "hace 2 min",
                    dotColor: AppTheme.primaryColor,
                  ),
                  _buildDivider(isDark, indent: 24),
                  _buildLogItem(
                    text: "Nuevo usuario registrado: María G.",
                    time: "hace 5 min",
                    dotColor: AppTheme.greenAccent,
                  ),
                  _buildDivider(isDark, indent: 24),
                  _buildLogItem(
                    text: "Error de API en simulación #334",
                    time: "hace 8 min",
                    dotColor: AppTheme.redAccent,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
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
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.08),
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
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_forward, size: 14, color: AppTheme.primaryColor),
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider(bool isDark, {double indent = 56}) {
    return Divider(
      height: 1,
      indent: indent,
      endIndent: 12,
      color: isDark ? Colors.grey[800] : Colors.grey[100],
    );
  }

  Widget _buildLogItem({
    required String text,
    required String time,
    required Color dotColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
