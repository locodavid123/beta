import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/style.dart';

class AdminCreateStyleScreen extends StatefulWidget {
  final ArtStyle? styleToEdit;

  const AdminCreateStyleScreen({super.key, this.styleToEdit});

  @override
  State<AdminCreateStyleScreen> createState() => _AdminCreateStyleScreenState();
}

class _AdminCreateStyleScreenState extends State<AdminCreateStyleScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late String _name;
  late String _category;
  late String _description;
  late String _promptTemplate;
  late String _imagePath;
  late String _coatType;
  late String _difficulty;
  late bool _isPublished;
  late bool _isHot;

  @override
  void initState() {
    super.initState();
    final style = widget.styleToEdit;
    _name = style?.name ?? '';
    _category = style?.category ?? 'Fantasía';
    _description = style?.description ?? '';
    _promptTemplate = style?.promptTemplate ?? '';
    _imagePath = style?.imagePath ?? '';
    _coatType = style?.coatType ?? 'Ambos';
    _difficulty = style?.difficulty ?? 'Medio';
    _isPublished = style != null ? (style.status == 'activo') : true;
    _isHot = style?.isHot ?? false;
  }

  String _buildPreviewPrompt() {
    String tpl = _promptTemplate.trim();
    if (tpl.isEmpty) {
      tpl = 'A majestic portrait of a [breed] dog...';
    }
    // Replace [breed] tag for visual preview
    return tpl.replaceAll('[breed]', 'Shih Tzu');
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.styleToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Estilo' : 'Crear Nuevo Estilo', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Style Name
                _buildLabel('Nombre del estilo'),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _name,
                  onChanged: (val) => setState(() => _name = val.trim()),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa el nombre del estilo' : null,
                  decoration: const InputDecoration(
                    hintText: 'Ej: Realeza Imperial',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 18),

                // Category & Hot check
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Categoría'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _category,
                            onChanged: (val) {
                              if (val != null) setState(() => _category = val);
                            },
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: ['Clásico', 'Fantasía', 'Sci-Fi', 'Arte', 'Steampunk', 'Cute']
                                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('¿Estilo Popular? (Hot)'),
                          const SizedBox(height: 2),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Popular', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            value: _isHot,
                            activeColor: AppTheme.primaryColor,
                            onChanged: (val) => setState(() => _isHot = val ?? false),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Description
                _buildLabel('Descripción corta'),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _description,
                  onChanged: (val) => setState(() => _description = val.trim()),
                  maxLines: 2,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa la descripción' : null,
                  decoration: const InputDecoration(
                    hintText: 'Describe el estilo en 1-2 líneas...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 18),

                // Prompt Template
                _buildLabel('Prompt de IA (plantilla)'),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _promptTemplate,
                  onChanged: (val) => setState(() => _promptTemplate = val),
                  maxLines: 3,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa el prompt de IA' : null,
                  decoration: const InputDecoration(
                    hintText: 'A majestic royal portrait of a [breed] dog, wearing ancient clothes...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 18),

                // Example Image URL / Local path
                _buildLabel('URL / Ruta de imagen de ejemplo'),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _imagePath,
                  onChanged: (val) => setState(() => _imagePath = val.trim()),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa la ruta de imagen' : null,
                  decoration: const InputDecoration(
                    hintText: 'assets/images/realeza_imperial.png',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 18),

                // Coat selection
                _buildLabel('Tipo de manto'),
                const SizedBox(height: 8),
                Row(
                  children: ['Pelo Largo', 'Pelo Corto', 'Ambos'].map((type) {
                    final selected = _coatType == type;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          showCheckmark: false,
                          label: Center(
                            child: Text(
                              type,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ),
                          selected: selected,
                          selectedColor: AppTheme.primaryColor,
                          backgroundColor: isDark ? AppTheme.cardDark : Colors.grey[200],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          onSelected: (val) {
                            if (val) setState(() => _coatType = type);
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Difficulty selection
                _buildLabel('Nivel de dificultad'),
                const SizedBox(height: 8),
                Row(
                  children: ['Fácil', 'Medio', 'Difícil'].map((diff) {
                    final selected = _difficulty == diff;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          showCheckmark: false,
                          label: Center(
                            child: Text(
                              diff,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ),
                          selected: selected,
                          selectedColor: AppTheme.primaryColor,
                          backgroundColor: isDark ? AppTheme.cardDark : Colors.grey[200],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          onSelected: (val) {
                            if (val) setState(() => _difficulty = diff);
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Publish Style Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: _buildLabel('Publicar estilo'),
                  subtitle: const Text(
                    '¿Activar este estilo para los usuarios?',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  value: _isPublished,
                  activeThumbColor: AppTheme.primaryColor,
                  onChanged: (val) => setState(() => _isPublished = val),
                ),
                const SizedBox(height: 18),

                // React Preview blue container
                _buildLabel('Vista previa del prompt'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[900]?.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blueAccent, width: 1),
                  ),
                  child: Text(
                    _buildPreviewPrompt(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.4,
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final styleId = isEditing
                            ? widget.styleToEdit!.id
                            : _name.toLowerCase().replaceAll(' ', '_');

                        final style = ArtStyle(
                          id: styleId,
                          name: _name,
                          category: _category,
                          imagePath: _imagePath,
                          description: _description,
                          isHot: _isHot,
                          status: _isPublished ? 'activo' : 'borrador',
                          promptTemplate: _promptTemplate,
                          coatType: _coatType,
                          difficulty: _difficulty,
                          uses: isEditing ? widget.styleToEdit!.uses : 0,
                        );

                        if (isEditing) {
                          await state.updateStyle(style);
                        } else {
                          // Check if ID already exists
                          final exist = state.styles.any((s) => s.id == style.id);
                          if (exist) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ya existe un estilo con este nombre.')),
                            );
                            return;
                          }
                          await state.registerStyle(
                            name: _name,
                            category: _category,
                            imagePath: _imagePath,
                            description: _description,
                            isHot: _isHot,
                          );
                          // Register style internally uses defaults, so we update it with full prompt details
                          await state.updateStyle(style);
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEditing
                                  ? 'Estilo actualizado con éxito.'
                                  : 'Nuevo estilo guardado con éxito.'),
                            ),
                          );
                          Navigator.pop(context);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9D0208), // Crimson Magenta / deep red
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: const Text('Guardar Estilo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    );
  }
}
