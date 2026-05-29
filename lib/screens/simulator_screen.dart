import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../models/pet.dart';
import '../models/style.dart';
import '../models/creation.dart';
import 'add_pet_screen.dart';

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  int _petSourceIndex = 0; // 0: Mascota Guardada, 1: Nueva Foto
  Pet? _selectedPet;
  ArtStyle? _selectedStyle;
  Creation? _latestCreation;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Auto-select first pet and first style if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<AppStateProvider>(context, listen: false);
      if (state.pets.isNotEmpty) {
        setState(() {
          _selectedPet = state.pets.first;
        });
      }
      if (state.styles.isNotEmpty) {
        setState(() {
          _selectedStyle = state.styles.first;
        });
      }
    });
  }

  Future<void> _handleGenerate() async {
    setState(() {
      _errorMessage = null;
      _latestCreation = null;
    });

    if (_selectedPet == null) {
      setState(() {
        _errorMessage = "Por favor selecciona una mascota.";
      });
      return;
    }

    if (_selectedStyle == null) {
      setState(() {
        _errorMessage = "Por favor selecciona un estilo.";
      });
      return;
    }

    final state = Provider.of<AppStateProvider>(context, listen: false);
    try {
      final result = await state.generateArt(
        pet: _selectedPet!,
        style: _selectedStyle!,
      );
      setState(() {
        _latestCreation = result;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check if defaults need to be set (if lists loaded after init)
    if (_selectedPet == null && state.pets.isNotEmpty) {
      _selectedPet = state.pets.first;
    }
    if (_selectedStyle == null && state.styles.isNotEmpty) {
      _selectedStyle = state.styles.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Simulador de Estilos'),
            SizedBox(width: 6),
            Icon(Icons.auto_awesome, color: AppTheme.goldAccent, size: 18),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Credits indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: AppTheme.goldAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tienes ${state.credits} créditos disponibles',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // STEP 1: Elige tu mascota
            _buildStepTitle('1. Elige tu mascota'),
            const SizedBox(height: 12),
            // Source Toggle Buttons
            Row(
              children: [
                _buildSourceButton(
                  index: 0,
                  label: 'Mascota Guardada',
                  icon: Icons.pets,
                ),
                const SizedBox(width: 12),
                _buildSourceButton(
                  index: 1,
                  label: 'Nueva Foto',
                  icon: Icons.camera_alt,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_petSourceIndex == 0) ...[
              // Saved pets dropdown
              state.pets.isEmpty
                  ? TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddPetScreen()),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Registra tu primera mascota'),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.cardDark : const Color(0xFFF4F0FA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Pet>(
                          value: _selectedPet,
                          isExpanded: true,
                          dropdownColor: isDark ? AppTheme.cardDark : Colors.white,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                          items: state.pets.map((Pet pet) {
                            return DropdownMenuItem<Pet>(
                              value: pet,
                              child: Text('${pet.name} (${pet.breed})'),
                            );
                          }).toList(),
                          onChanged: (Pet? val) {
                            setState(() {
                              _selectedPet = val;
                              _latestCreation = null;
                            });
                          },
                        ),
                      ),
                    ),
            ] else ...[
              // Upload photo simulation
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Simulando carga de foto. Elige una Mascota Guardada para procesar.')),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.cardDark : const Color(0xFFF4F0FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2), width: 1.5),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload_outlined, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text(
                          'Cargar foto desde galería',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // STEP 2: Elige un estilo
            _buildStepTitle('2. Elige un estilo'),
            const SizedBox(height: 12),
            // Horizontal styles selection list
            SizedBox(
              height: 100,
              child: state.styles.isEmpty
                  ? Center(child: Text('Cargando estilos...', style: TextStyle(color: Colors.grey[500])))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.styles.length,
                      itemBuilder: (context, index) {
                        final style = state.styles[index];
                        final isSelected = _selectedStyle?.id == style.id;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedStyle = style;
                              _latestCreation = null;
                            });
                          },
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.cardDark : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    style.imagePath,
                                    height: 50,
                                    width: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  style.name.split(' ').first,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppTheme.primaryColor : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),

            // STEP 3: Resultado
            _buildStepTitle('3. Resultado'),
            const SizedBox(height: 12),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.redAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppTheme.redAccent, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Main generation result card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Generation output state
                  if (state.isGenerating) ...[
                    // Active generating animation
                    Container(
                      height: 250,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                              strokeWidth: 5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Generando obra de arte...',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: state.generationProgress,
                              minHeight: 8,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(state.generationProgress * 100).toInt()}% completado',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_latestCreation != null) ...[
                    // Display result
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: Image.asset(
                        _latestCreation!.imagePath,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_latestCreation!.petName} — ${_latestCreation!.styleName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _latestCreation!.description,
                            style: TextStyle(
                              color: isDark ? Colors.grey[300] : Colors.grey[700],
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Obra descargada con éxito.')),
                                    );
                                  },
                                  icon: const Icon(Icons.download, size: 18),
                                  label: const Text('Descargar'),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.grey[300]!),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Enlace de compartir copiado.')),
                                    );
                                  },
                                  icon: const Icon(Icons.share, size: 18),
                                  label: const Text('Compartir'),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppTheme.primaryColor),
                                    foregroundColor: AppTheme.primaryColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Empty state / prompt instruction
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.grey[300], size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Elige una mascota y un estilo artístico, luego haz clic en "Generar Estilo" para comenzar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Persistent Generate Button
            if (!state.isGenerating)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _handleGenerate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, color: AppTheme.goldAccent, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Generar Estilo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSourceButton({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _petSourceIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _petSourceIndex = index;
            _latestCreation = null;
          });
        },
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? AppTheme.cardDark : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey[300]!,
              width: isSelected ? 0 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
