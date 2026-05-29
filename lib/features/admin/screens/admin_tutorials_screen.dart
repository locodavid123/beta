import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/tutorial.dart';

class AdminTutorialsScreen extends StatefulWidget {
  const AdminTutorialsScreen({super.key});

  @override
  State<AdminTutorialsScreen> createState() => _AdminTutorialsScreenState();
}

class _AdminTutorialsScreenState extends State<AdminTutorialsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  void _showAddEditTutorialDialog({Tutorial? tutorial}) {
    final titleController = TextEditingController(text: tutorial?.title ?? '');
    final durationController = TextEditingController(text: tutorial?.duration ?? '');
    String difficulty = tutorial?.difficulty ?? 'Fácil';
    bool isPublished = tutorial != null ? (tutorial.status == 'publicado') : true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(tutorial == null ? 'Nuevo Tutorial' : 'Editar Tutorial'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título del Tutorial',
                        hintText: 'Ej: Corte de Cachorro',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: durationController,
                      decoration: const InputDecoration(
                        labelText: 'Duración (ej: 12:45 min)',
                        hintText: 'Ej: 12:45 min',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: difficulty,
                      decoration: const InputDecoration(labelText: 'Dificultad'),
                      items: ['Fácil', 'Medio', 'Difícil']
                          .map((diff) => DropdownMenuItem(value: diff, child: Text(diff)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            difficulty = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Publicado', style: TextStyle(fontSize: 14)),
                      value: isPublished,
                      activeThumbColor: AppTheme.primaryColor,
                      onChanged: (val) {
                        setDialogState(() {
                          isPublished = val;
                        });
                      },
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
                    final title = titleController.text.trim();
                    final duration = durationController.text.trim();
                    if (title.isEmpty || duration.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor completa todos los campos.')),
                      );
                      return;
                    }

                    final state = Provider.of<AppStateProvider>(context, listen: false);

                    if (tutorial == null) {
                      await state.addTutorial(
                        title: title,
                        duration: duration,
                        difficulty: difficulty,
                        status: isPublished ? 'publicado' : 'borrador',
                      );
                    } else {
                      final updated = Tutorial(
                        id: tutorial.id,
                        title: title,
                        duration: duration,
                        difficulty: difficulty,
                        views: tutorial.views,
                        status: isPublished ? 'publicado' : 'borrador',
                        videoUrl: tutorial.videoUrl,
                      );
                      await state.updateTutorial(updated);
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tutorial guardado con éxito.')),
                      );
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter tutorials
    List<Tutorial> filteredTutorials = state.tutorials.where((t) {
      return t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.difficulty.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    int activeCount = state.tutorials.where((t) => t.status == 'publicado').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutoriales de Peluquería', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showAddEditTutorialDialog(),
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
          ),
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
                  hintText: 'Buscar tutorial...',
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

          // Total tutorial count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            child: Text(
              '$activeCount tutoriales activos',
              style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),

          // Tutorials List
          Expanded(
            child: filteredTutorials.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.video_library_outlined, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'No hay tutoriales registrados.',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    itemCount: filteredTutorials.length,
                    itemBuilder: (context, index) {
                      final tutorial = filteredTutorials[index];
                      return _buildTutorialCard(context, tutorial, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialCard(BuildContext context, Tutorial tutorial, bool isDark) {
    final state = Provider.of<AppStateProvider>(context, listen: false);

    // Alternate background or status indicator colors
    Color diffColor;
    if (tutorial.difficulty == 'Fácil') {
      diffColor = AppTheme.greenAccent;
    } else if (tutorial.difficulty == 'Medio') {
      diffColor = AppTheme.goldAccent;
    } else {
      diffColor = AppTheme.redAccent;
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
            // Play Button Thumbnail Mock
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.play_circle_fill, color: AppTheme.primaryColor, size: 28),
              ),
            ),
            const SizedBox(width: 14),

            // Tutorial Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tutorial.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${tutorial.duration} • ',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                      Text(
                        tutorial.difficulty,
                        style: TextStyle(color: diffColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${tutorial.views} vistas  •  ${tutorial.status == 'publicado' ? 'Publicado' : 'Borrador'}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 10),
                  ),
                ],
              ),
            ),

            // Actions: Edit / Delete
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppTheme.goldAccent, size: 20),
                  onPressed: () => _showAddEditTutorialDialog(tutorial: tutorial),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_outlined, color: AppTheme.redAccent, size: 20),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('¿Eliminar tutorial?'),
                        content: Text('¿Estás seguro de que quieres eliminar el tutorial "${tutorial.title}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await state.deleteTutorial(tutorial.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Tutorial eliminado.')),
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
