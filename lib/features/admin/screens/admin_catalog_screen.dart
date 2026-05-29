import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/style.dart';
import 'admin_create_style_screen.dart';

class AdminCatalogScreen extends StatefulWidget {
  const AdminCatalogScreen({super.key});

  @override
  State<AdminCatalogScreen> createState() => _AdminCatalogScreenState();
}

class _AdminCatalogScreenState extends State<AdminCatalogScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to filter by tab
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter styles based on search and selected tab
    List<ArtStyle> filteredStyles = state.styles.where((style) {
      final nameMatches = style.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          style.category.toLowerCase().contains(_searchQuery.toLowerCase());

      final tabIndex = _tabController.index;
      if (tabIndex == 0) return nameMatches; // Todos
      if (tabIndex == 1) return nameMatches && style.status == 'activo';
      if (tabIndex == 2) return nameMatches && style.status == 'borrador';
      if (tabIndex == 3) return nameMatches && style.status == 'archivado';
      return nameMatches;
    }).toList();

    int activeCount = state.styles.where((s) => s.status == 'activo').length;
    int draftCount = state.styles.where((s) => s.status == 'borrador').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Estilos', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            // "+ Nuevo" Button
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminCreateStyleScreen()),
                );
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Nuevo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Buscar estilo...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),

          // Custom Segmented Control (Tabs)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppTheme.primaryColor,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              dividerColor: Colors.transparent,
              indicatorPadding: EdgeInsets.zero,
              tabs: const [
                Tab(text: 'Todos'),
                Tab(text: 'Activos'),
                Tab(text: 'Borrador'),
                Tab(text: 'Archivados'),
              ],
            ),
          ),

          // Total items count text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            child: Text(
              '$activeCount activos • $draftCount borradores',
              style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),

          // Styles List
          Expanded(
            child: filteredStyles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.palette_outlined, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'No se encontraron estilos.',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    itemCount: filteredStyles.length,
                    itemBuilder: (context, index) {
                      final style = filteredStyles[index];
                      return _buildStyleCard(context, style, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleCard(BuildContext context, ArtStyle style, bool isDark) {
    final state = Provider.of<AppStateProvider>(context, listen: false);

    // Dynamic color based on status
    Color statusColor;
    String statusText;
    switch (style.status) {
      case 'activo':
        statusColor = AppTheme.greenAccent;
        statusText = 'Activo';
        break;
      case 'borrador':
        statusColor = AppTheme.goldAccent;
        statusText = 'Borrador';
        break;
      case 'archivado':
      default:
        statusColor = Colors.grey;
        statusText = 'Archivado';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: isDark ? AppTheme.cardDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Thumbnail image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                style.imagePath,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 72,
                    height: 72,
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: const Icon(Icons.broken_image, color: AppTheme.primaryColor),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),

            // Style Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge row
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    style.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${style.uses} usos',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Row(
              children: [
                // Edit (Yellow pencil icon)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppTheme.goldAccent, size: 20),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdminCreateStyleScreen(styleToEdit: style)),
                    );
                  },
                ),
                // Archive / Restore (Green up/down arrow or folder icon)
                IconButton(
                  icon: Icon(
                    style.status == 'archivado' ? Icons.unarchive_outlined : Icons.archive_outlined,
                    color: AppTheme.greenAccent,
                    size: 20,
                  ),
                  onPressed: () async {
                    final updatedStyle = ArtStyle(
                      id: style.id,
                      name: style.name,
                      category: style.category,
                      imagePath: style.imagePath,
                      description: style.description,
                      isHot: style.isHot,
                      status: style.status == 'archivado' ? 'activo' : 'archivado',
                      promptTemplate: style.promptTemplate,
                      coatType: style.coatType,
                      difficulty: style.difficulty,
                      uses: style.uses,
                    );
                    await state.updateStyle(updatedStyle);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(style.status == 'archivado'
                              ? 'Estilo restaurado con éxito.'
                              : 'Estilo archivado con éxito.'),
                        ),
                      );
                    }
                  },
                ),
                // Delete (Red trash can)
                IconButton(
                  icon: const Icon(Icons.delete_outline_outlined, color: AppTheme.redAccent, size: 20),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('¿Eliminar estilo?'),
                        content: Text('¿Estás seguro de que quieres eliminar el estilo "${style.name}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await state.deleteStyle(style.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Estilo "${style.name}" eliminado.')),
                                );
                              }
                            },
                            child: const Text('Eliminar', style: TextStyle(color: AppTheme.redAccent)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
