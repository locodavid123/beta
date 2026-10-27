import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/pet.dart';
import '../../../core/models/style.dart';
import '../../../core/models/creation.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/media_export_service.dart';
import '../../../core/widgets/before_after_comparator.dart';
import 'add_pet_screen.dart';
import 'tutorials_screen.dart';
import 'coat_scanner_screen.dart';
import '../../../core/config/app_config.dart';

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
  String _selectedCoatColor = 'Dorado y Blanco';

  File? _newPetImageFile;
  bool _isNewPetVerified = false;
  bool _isSavingImage = false;
  bool _isSharingImage = false;

  final ScrollController _stylesScrollController = ScrollController();

  @override
  void dispose() {
    _stylesScrollController.dispose();
    super.dispose();
  }

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
    final state = Provider.of<AppStateProvider>(context, listen: false);
    setState(() {
      _errorMessage = null;
      _latestCreation = null;
    });

    Pet? petToUse;
    if (_petSourceIndex == 0) {
      if (_selectedPet == null) {
        setState(() {
          _errorMessage = state.translate('sim_err_select_pet');
        });
        return;
      }
      petToUse = _selectedPet;
    } else {
      if (_newPetImageFile == null || !_isNewPetVerified) {
        setState(() {
          _errorMessage = state.language == 'English'
              ? 'Please upload and verify a photo first.'
              : state.language == 'Português'
                  ? 'Por favor, carregue e verifique uma foto primeiro.'
                  : 'Por favor, carga y verifica una foto primero.';
        });
        return;
      }
      petToUse = Pet(
        id: 'temp_pet_${DateTime.now().millisecondsSinceEpoch}',
        name: state.language == 'English' ? 'My Shih Tzu' : state.language == 'Português' ? 'Meu Shih Tzu' : 'Mi Shih Tzu',
        breed: 'Shih Tzu',
        age: '',
        gender: '',
        notes: '',
        imagePath: _newPetImageFile!.path,
        isVerifiedByAI: true,
        userEmail: state.userEmail,
      );
    }

    if (_selectedStyle == null) {
      setState(() {
        _errorMessage = state.translate('sim_err_select_style');
      });
      return;
    }

    try {
      final result = await state.generateArt(
        pet: petToUse!,
        style: _selectedStyle!,
        coatColor: _selectedCoatColor,
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

  Future<void> _handleDownload(AppStateProvider state) async {
    if (_latestCreation == null) return;
    setState(() {
      _isSavingImage = true;
    });

    try {
      final savedPath = await MediaExportService.saveImageToDevice(
        imagePath: _latestCreation!.imagePath,
        petName: _latestCreation!.petName,
        styleName: _latestCreation!.styleName,
      );

      if (mounted) {
        final fileName = savedPath.split(Platform.pathSeparator).last;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.primaryDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: AppTheme.goldAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.translate('sim_success_download'),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        state.translate('sim_saved_path', params: {'path': fileName}),
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.redAccent,
            content: Text('Error al guardar: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingImage = false;
        });
      }
    }
  }

  Future<void> _handleShare(AppStateProvider state) async {
    if (_latestCreation == null) return;
    setState(() {
      _isSharingImage = true;
    });

    try {
      await MediaExportService.shareCreation(
        imagePath: _latestCreation!.imagePath,
        petName: _latestCreation!.petName,
        styleName: _latestCreation!.styleName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al compartir: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharingImage = false;
        });
      }
    }
  }

  void _showGroomerCardModal(BuildContext context, AppStateProvider state) {
    if (_latestCreation == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final beforeImage = _latestCreation!.originalImagePath.isNotEmpty
        ? _latestCreation!.originalImagePath
        : (_selectedPet?.imagePath ?? (_newPetImageFile?.path ?? ''));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.content_cut, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.translate('sim_groomer_card_title'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            state.translate('sim_groomer_card_desc'),
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Mini Before/After preview
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BeforeAfterComparator(
                    beforeImagePath: beforeImage,
                    afterImagePath: _latestCreation!.imagePath,
                    beforeLabel: state.translate('sim_before'),
                    afterLabel: state.translate('sim_after'),
                    height: 200,
                    showControls: false,
                  ),
                ),
                const SizedBox(height: 16),

                // Data grid: Pet & Style Details
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF130D20) : const Color(0xFFF7F5FC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGroomerRow('🐕 Mascota:', '${_latestCreation!.petName} (Shih Tzu)'),
                      const Divider(height: 16),
                      _buildGroomerRow('✂️ Estilo deseado:', _latestCreation!.styleName),
                      if (_selectedStyle != null) ...[
                        const Divider(height: 16),
                        _buildGroomerRow('💈 Tipo de pelaje:', _selectedStyle!.coatType),
                        const Divider(height: 16),
                        _buildGroomerRow('⭐ Dificultad del corte:', _selectedStyle!.difficulty),
                      ],
                      if (_selectedPet != null && _selectedPet!.notes.isNotEmpty) ...[
                        const Divider(height: 16),
                        _buildGroomerRow('📝 Notas / Alergias:', _selectedPet!.notes),
                      ],
                      const Divider(height: 16),
                      Text(
                        state.translate('sim_groomer_card_instructions'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _latestCreation!.description,
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[300] : Colors.grey[700], height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Watch Video Tutorial Button in Groomer Modal
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      final matchingTutorial = state.getTutorialForStyle(
                        styleId: _latestCreation!.styleId,
                        styleName: _latestCreation!.styleName,
                      );
                      if (matchingTutorial != null) {
                        TutorialsScreen.openTutorialGuide(context, matchingTutorial);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(state.translate('sim_no_tutorial_found'))),
                        );
                      }
                    },
                    icon: const Icon(Icons.play_circle_fill_rounded, color: AppTheme.primaryColor),
                    label: Text(
                      state.translate('sim_watch_tutorial_btn'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Big Share to Groomer Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      final groomerShareText = 'Hola! Te comparto la ficha de corte para mi Shih Tzu ${_latestCreation!.petName}.\n'
                          'Estilo deseado: "${_latestCreation!.styleName}".\n'
                          'Notas de la mascota: ${_selectedPet?.notes.isNotEmpty == true ? _selectedPet!.notes : "Ninguna"}.\n'
                          '¡Diseñado con Shih Tzu App! 🐕✂️';
                      MediaExportService.shareCreation(
                        imagePath: _latestCreation!.imagePath,
                        petName: _latestCreation!.petName,
                        styleName: _latestCreation!.styleName,
                        customText: groomerShareText,
                      );
                    },
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    label: Text(
                      state.translate('sim_groomer_share_btn'),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroomerRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Preselection from Catalog or Home
    if (state.selectedSimulatorStyle != null) {
      final preselected = state.selectedSimulatorStyle;
      final preselectedPet = state.selectedSimulatorPet;
      _selectedStyle = preselected;
      _latestCreation = null;
      _errorMessage = null;
      if (preselectedPet != null) {
        _selectedPet = preselectedPet;
        _petSourceIndex = 0;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state.clearSimulatorPreselection();
        if (_stylesScrollController.hasClients && preselected != null) {
          final idx = state.styles.indexWhere((s) => s.id == preselected.id);
          if (idx >= 0) {
            final targetOffset = (idx * 92.0).clamp(0.0, _stylesScrollController.position.maxScrollExtent);
            _stylesScrollController.animateTo(
              targetOffset,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
            );
          }
        }
      });
    }

    // Check if defaults need to be set (if lists loaded after init)
    if (_selectedPet == null && state.pets.isNotEmpty) {
      _selectedPet = state.pets.first;
    }
    if (_selectedStyle == null && state.styles.isNotEmpty) {
      _selectedStyle = state.styles.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.translate('sim_title')),
            const SizedBox(width: 6),
            const Icon(Icons.auto_awesome, color: AppTheme.goldAccent, size: 18),
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
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: AppTheme.goldAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    state.translate('sim_credits_avail', params: {'count': state.credits.toString()}),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // AI Vision Diagnostic Recommendation Banner
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CoatScannerScreen(initialPet: _selectedPet),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.12),
                      Colors.blueAccent.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.document_scanner_rounded, color: AppTheme.primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¿No sabes qué corte le favorece?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Escanear lagrimales, ojos y manto con IA',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.primaryColor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // STEP 1: Elige tu mascota
            _buildStepTitle(state.translate('sim_step1')),
            const SizedBox(height: 12),
            // Source Toggle Buttons
            Row(
              children: [
                _buildSourceButton(
                  index: 0,
                  label: state.translate('sim_source_saved'),
                  icon: Icons.pets,
                ),
                const SizedBox(width: 12),
                _buildSourceButton(
                  index: 1,
                  label: state.translate('sim_source_new'),
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
                      label: Text(state.translate('sim_register_first')),
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
              // Upload photo flow
              _newPetImageFile == null
                  ? InkWell(
                      onTap: () => _showImageSourceActionSheet(context),
                      child: Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.cardDark : const Color(0xFFF4F0FA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2), width: 1.5),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cloud_upload_outlined, color: AppTheme.primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                state.translate('sim_upload_gallery'),
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              _newPetImageFile!,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.language == 'English' ? 'Temporary Pet' : state.language == 'Português' ? 'Pet Temporário' : 'Mascota Temporal',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      _isNewPetVerified ? Icons.verified : Icons.verified_user_outlined,
                                      color: _isNewPetVerified ? AppTheme.greenAccent : Colors.grey,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _isNewPetVerified
                                          ? state.translate('pet_badge_verified')
                                          : state.translate('pet_badge_unverified'),
                                      style: TextStyle(
                                        color: _isNewPetVerified ? AppTheme.greenAccent : Colors.grey,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cached, color: AppTheme.primaryColor),
                            onPressed: () => _showImageSourceActionSheet(context),
                            tooltip: state.language == 'English' ? 'Change Photo' : state.language == 'Português' ? 'Alterar Foto' : 'Cambiar Foto',
                          ),
                        ],
                      ),
                    ),
            ],
            const SizedBox(height: 14),

            // Tonalidad del pelaje de tu Shih Tzu
            Row(
              children: [
                const Icon(Icons.palette_outlined, size: 16, color: AppTheme.goldAccent),
                const SizedBox(width: 6),
                Text(
                  state.language == 'English'
                      ? 'Shih Tzu Coat Tone:'
                      : state.language == 'Português'
                          ? 'Tom da Pelagem:'
                          : 'Tonalidad del pelaje de tu Shih Tzu:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'Dorado y Blanco',
                  'Panda (Blanco y Negro)',
                  'Tricolor',
                  'Chocolate',
                ].map((colorOption) {
                  final isSelected = _selectedCoatColor == colorOption;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        colorOption,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : (isDark ? Colors.grey[300] : Colors.grey[700]),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.18),
                      backgroundColor: isDark ? AppTheme.cardDark : const Color(0xFFF4F0FA),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) {
                        if (val) {
                          setState(() => _selectedCoatColor = colorOption);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // STEP 2: Elige un estilo
            _buildStepTitle(state.translate('sim_step2')),
            const SizedBox(height: 12),
            // Horizontal styles selection list
            SizedBox(
              height: 124,
              child: state.styles.isEmpty
                  ? Center(child: Text(state.translate('sim_loading_styles'), style: TextStyle(color: Colors.grey[500])))
                  : ListView.builder(
                      controller: _stylesScrollController,
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
                            width: 105,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.cardDark : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? AppTheme.primaryColor.withValues(alpha: 0.25)
                                      : Colors.black.withValues(alpha: 0.03),
                                  blurRadius: isSelected ? 8 : 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: style.imagePath.startsWith('assets/')
                                      ? Image.asset(
                                          style.imagePath,
                                          height: 48,
                                          width: 48,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(style.imagePath),
                                          height: 48,
                                          width: 48,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            height: 48,
                                            width: 48,
                                            color: Colors.grey[200],
                                            child: const Icon(Icons.broken_image, color: Colors.grey, size: 20),
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  style.name,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    height: 1.15,
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
            if (_selectedStyle != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Estilo seleccionado: ${_selectedStyle!.name}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // STEP 3: Resultado
            _buildStepTitle(state.translate('sim_step3')),
            const SizedBox(height: 12),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.redAccent.withValues(alpha: 0.1),
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
                    color: Colors.black.withValues(alpha: 0.03),
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
                            state.translate('sim_generating_art'),
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
                            state.translate('sim_percent_completed', params: {'progress': (state.generationProgress * 100).toInt().toString()}),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_latestCreation != null) ...[
                    // Interactive Before & After Comparator
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: BeforeAfterComparator(
                        beforeImagePath: _latestCreation!.originalImagePath.isNotEmpty
                            ? _latestCreation!.originalImagePath
                            : (_selectedPet?.imagePath ?? (_newPetImageFile?.path ?? '')),
                        afterImagePath: _latestCreation!.imagePath,
                        beforeLabel: state.translate('sim_before'),
                        afterLabel: state.translate('sim_after'),
                        height: 280,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${_latestCreation!.petName} — ${_latestCreation!.styleName}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.goldAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.4)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.stars, color: AppTheme.goldAccent, size: 12),
                                    SizedBox(width: 4),
                                    Text(
                                      'Shih Tzu Cut',
                                      style: TextStyle(
                                        color: AppTheme.goldAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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

                          // Featured Video Tutorial Banner
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7B2CBF), Color(0xFFE61D63)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE61D63).withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  final matchingTutorial = state.getTutorialForStyle(
                                    styleId: _latestCreation!.styleId,
                                    styleName: _latestCreation!.styleName,
                                  );
                                  if (matchingTutorial != null) {
                                    TutorialsScreen.openTutorialGuide(context, matchingTutorial);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(state.translate('sim_no_tutorial_found'))),
                                    );
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.22),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              state.translate('sim_watch_tutorial_btn'),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              state.translate('sim_watch_tutorial_desc'),
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.85),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Action Buttons: Descargar, Compartir & Ficha Peluquero
                          Row(
                            children: [
                              // Download Button
                              Expanded(
                                flex: 3,
                                child: OutlinedButton.icon(
                                  onPressed: _isSavingImage ? null : () => _handleDownload(state),
                                  icon: _isSavingImage
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.download, size: 18),
                                  label: Text(state.translate('sim_download')),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: isDark ? Colors.white24 : Colors.grey[300]!),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Share Button
                              Expanded(
                                flex: 3,
                                child: ElevatedButton.icon(
                                  onPressed: _isSharingImage ? null : () => _handleShare(state),
                                  icon: _isSharingImage
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Icon(Icons.share, size: 18, color: Colors.white),
                                  label: Text(
                                    state.translate('sim_share'),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Groomer Card Button
                              Tooltip(
                                message: state.translate('sim_groomer_card'),
                                child: InkWell(
                                  onTap: () => _showGroomerCardModal(context, state),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.goldAccent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
                                    ),
                                    child: const Icon(
                                      Icons.content_cut,
                                      color: AppTheme.goldAccent,
                                      size: 20,
                                    ),
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
                            state.translate('sim_empty_state_desc'),
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
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome, color: AppTheme.goldAccent, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          state.translate('sim_btn_generate'),
                          style: const TextStyle(
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
            _errorMessage = null;
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

  void _showImageSourceActionSheet(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.translate('pet_sheet_title'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                state.translate('pet_sheet_desc'),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryColor, size: 28),
                            const SizedBox(height: 8),
                            Text(
                              state.translate('edit_profile_camera'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.photo_library_outlined, color: AppTheme.primaryColor, size: 28),
                            const SizedBox(height: 8),
                            Text(
                              state.translate('edit_profile_gallery'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final state = Provider.of<AppStateProvider>(context, listen: false);
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      await _runVerification(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.translate('pet_error_pick', params: {'error': e.toString()})),
            backgroundColor: AppTheme.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _runVerification(File file) async {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              Text(
                state.translate('pet_verifying_title'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                state.translate('pet_verifying_desc'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );

    GeminiResult result;

    final activeKey = state.geminiApiKey.trim().isNotEmpty &&
            !state.geminiApiKey.trim().startsWith('AIzaSy')
        ? state.geminiApiKey.trim()
        : AppConfig.defaultGeminiApiKey.trim();

    if (activeKey.isNotEmpty) {
      result = await GeminiService.verifyShihTzu(file, activeKey);
    } else {
      result = GeminiResult(
        isShihTzu: false,
        breed: 'No configurado',
        message: 'No se encontró una clave de Gemini activa para verificar la raza Shih Tzu.',
      );
    }

    if (mounted) {
      Navigator.pop(context); // Dismiss the loading dialog
    }

    if (result.isShihTzu) {
      setState(() {
        _newPetImageFile = file;
        _isNewPetVerified = true;
        _errorMessage = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.greenAccent,
            content: Text(result.message),
          ),
        );
      }
    } else {
      setState(() {
        _newPetImageFile = null;
        _isNewPetVerified = false;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppTheme.redAccent, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(state.translate('pet_verify_failed_title')),
                ),
              ],
            ),
            content: Text(
              '${result.message}\n\n${state.translate('pet_verify_failed_desc')}',
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppTheme.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(state.translate('pet_btn_understood')),
              ),
            ],
          ),
        );
      }
    }
  }
}
