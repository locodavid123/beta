import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/pet.dart';
import '../../../core/models/style.dart';
import '../../../core/models/coat_diagnosis.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/media_export_service.dart';
import '../../../core/theme/app_theme.dart';
import 'tutorials_screen.dart';

class CoatScannerScreen extends StatefulWidget {
  final Pet? initialPet;

  const CoatScannerScreen({super.key, this.initialPet});

  @override
  State<CoatScannerScreen> createState() => _CoatScannerScreenState();
}

class _CoatScannerScreenState extends State<CoatScannerScreen>
    with SingleTickerProviderStateMixin {
  Pet? _selectedPet;
  File? _customImageFile;
  bool _useCustomPhoto = false;

  bool _isScanning = false;
  int _scanningStepIndex = 0;
  Timer? _statusTimer;

  CoatDiagnosisResult? _diagnosis;
  late AnimationController _laserController;

  final List<String> _scanningMessages = [
    'Iniciando escáner biométrico y conformación cráneo-facial...',
    'Verificando fisionomía y rasgos de raza Shih Tzu...',
    'Analizando área periocular y riesgo de roce en córnea...',
    'Detectando manchas de lágrimas y oxidación de porfirinas...',
    'Evaluando textura del manto, densidad y propensión a nudos...',
    'Sintetizando corte ideal y recomendaciones de máster groomer...',
  ];

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<AppStateProvider>(context, listen: false);
      if (widget.initialPet != null) {
        setState(() {
          _selectedPet = widget.initialPet;
          _useCustomPhoto = false;
        });
      } else if (state.pets.isNotEmpty) {
        setState(() {
          _selectedPet = state.pets.first;
          _useCustomPhoto = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _laserController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 88,
      );

      if (picked != null) {
        setState(() {
          _customImageFile = File(picked.path);
          _useCustomPhoto = true;
          _diagnosis = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo cargar la imagen: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _startDiagnosis() async {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    File? fileToAnalyze;

    if (_useCustomPhoto && _customImageFile != null) {
      fileToAnalyze = _customImageFile;
    } else if (_selectedPet != null) {
      try {
        fileToAnalyze = await MediaExportService.getExportableFile(_selectedPet!.imagePath);
      } catch (_) {
        fileToAnalyze = null;
      }
    }

    if (fileToAnalyze == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una mascota o sube una fotografía.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _diagnosis = null;
      _scanningStepIndex = 0;
    });

    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
      if (mounted) {
        setState(() {
          _scanningStepIndex = (_scanningStepIndex + 1) % _scanningMessages.length;
        });
      }
    });

    try {
      final result = await GeminiService.diagnoseCoatAndFace(
        fileToAnalyze,
        state.geminiApiKey,
      );

      if (mounted) {
        _statusTimer?.cancel();
        setState(() {
          _diagnosis = result;
          _isScanning = false;
        });
      }
    } catch (_) {
      if (mounted) {
        _statusTimer?.cancel();
        setState(() {
          _diagnosis = GeminiService.diagnoseCoatAndFace(
            fileToAnalyze!,
            state.geminiApiKey,
          ) as dynamic;
          _isScanning = false;
        });
      }
    }
  }

  void _applyRecommendedStyleInSimulator(CoatDiagnosisResult diag) {
    final state = Provider.of<AppStateProvider>(context, listen: false);

    // Find style in state matching recommendedStyleId
    ArtStyle? matchedStyle;
    try {
      matchedStyle = state.styles.firstWhere(
        (s) => s.id == diag.recommendedStyleId || s.name.toLowerCase().contains(diag.recommendedStyleId.replaceAll('_', ' ')),
      );
    } catch (_) {
      matchedStyle = state.styles.isNotEmpty ? state.styles.first : null;
    }

    Pet? petToUse = _selectedPet ?? (state.pets.isNotEmpty ? state.pets.first : null);

    if (matchedStyle != null) {
      state.selectStyleForSimulation(matchedStyle, pet: petToUse);
      Navigator.of(context).pop(); // Go back to tabs (Simulator tab is now active)
    }
  }

  void _shareDiagnosis(CoatDiagnosisResult diag) {
    final petName = _selectedPet?.name ?? 'Mi Shih Tzu';
    final shareText = '''📋 DIAGNÓSTICO DE SALUD Y ESTILISMO SHIH TZU APP
🐾 Mascota: $petName (${diag.detectedBreed}) ${diag.isShihTzu ? '✓ Raza Verificada' : ''}
🏆 Puntuación: ${diag.overallScore}/100 (${diag.scoreLevel})
👁️ Ojos & Córnea: ${diag.eyeRiskStatus}
💧 Lagrimales: ${diag.tearStainStatus}
🦁 Manto: ${diag.coatCondition}
✂️ Corte Recomendado: ${diag.recommendedStyleName}
💡 Motivo: ${diag.recommendedStyleReason}

🩺 Plan de cuidado en casa:
• ${diag.groomingActionPlan.join('\n• ')}

✂️ Instrucción para el Groomer:
"${diag.groomerAdvice}"

Generado por Shih Tzu App con Inteligencia Artificial Gemini Vision ✨''';

    SharePlus.instance.share(
      ShareParams(
        text: shareText,
        subject: 'Diagnóstico de Carita y Manto de $petName',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.remove_red_eye_rounded, color: AppTheme.goldAccent, size: 22),
            SizedBox(width: 8),
            Text(
              'Escáner Facial & Manto',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: AppTheme.goldAccent, size: 14),
                SizedBox(width: 4),
                Text(
                  'Gemini Vision',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Description Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.12),
                    AppTheme.primaryLight.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.psychology, color: AppTheme.primaryColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Diagnóstico Oftalmo-Estético con IA',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Detecta oxidación en lagrimales, pelos rozando la córnea, nudos y el corte óptimo según su fisionomía.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Source Selector: "Mis Mascotas" vs "Foto Libre"
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Mis Shih Tzus')),
                    selected: !_useCustomPhoto,
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _useCustomPhoto = false;
                          _diagnosis = null;
                        });
                      }
                    },
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: !_useCustomPhoto ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Cámara / Galería')),
                    selected: _useCustomPhoto,
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _useCustomPhoto = true;
                          _diagnosis = null;
                        });
                      }
                    },
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: _useCustomPhoto ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pet Selection or Upload Area
            if (!_useCustomPhoto) ...[
              if (state.pets.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('No tienes mascotas registradas. Sube una foto con la opción Cámara/Galería.'),
                  ),
                )
              else
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.pets.length,
                    itemBuilder: (context, index) {
                      final pet = state.pets[index];
                      final isSelected = _selectedPet?.id == pet.id;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPet = pet;
                            _diagnosis = null;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 85,
                          margin: const EdgeInsets.only(right: 14),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? AppTheme.primaryColor.withValues(alpha: 0.3)
                                    : Colors.black.withValues(alpha: 0.04),
                                blurRadius: isSelected ? 8 : 4,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: pet.imagePath.startsWith('assets/')
                                    ? Image.asset(
                                        pet.imagePath,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(pet.imagePath),
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.pets, size: 36, color: AppTheme.primaryColor),
                                      ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                pet.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? AppTheme.primaryColor : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ] else ...[
              // Upload Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Tomar Foto'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('De Galería'),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // Photo Preview & Laser Scanner Frame
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isScanning ? Colors.cyanAccent : AppTheme.primaryColor.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isScanning
                              ? Colors.cyanAccent.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.08),
                          blurRadius: _isScanning ? 20 : 10,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: _useCustomPhoto
                          ? (_customImageFile != null
                              ? Image.file(_customImageFile!, fit: BoxFit.cover)
                              : Container(
                                  color: isDark ? AppTheme.cardDark : Colors.grey[200],
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text('Toma o sube una foto de frente', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ))
                          : (_selectedPet != null
                              ? (_selectedPet!.imagePath.startsWith('assets/')
                                  ? Image.asset(_selectedPet!.imagePath, fit: BoxFit.cover)
                                  : Image.file(
                                      File(_selectedPet!.imagePath),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.pets, size: 60, color: AppTheme.primaryColor),
                                    ))
                              : Container(
                                  color: Colors.grey[200],
                                  child: const Center(child: Text('Selecciona una mascota')),
                                )),
                    ),
                  ),

                  // Scanning Laser Overlay
                  if (_isScanning)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: AnimatedBuilder(
                          animation: _laserController,
                          builder: (context, child) {
                            return Stack(
                              children: [
                                // Glowing laser beam moving up and down
                                Positioned(
                                  top: _laserController.value * 230,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Colors.transparent, Colors.cyanAccent, Colors.pinkAccent, Colors.transparent],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.cyanAccent.withValues(alpha: 0.8),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Semi-transparent radar grid tint
                                Container(
                                  color: Colors.cyanAccent.withValues(alpha: 0.08),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Scan Action Button or Status Ticker
            if (_isScanning) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _scanningMessages[_scanningStepIndex],
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  onPressed: _startDiagnosis,
                  icon: const Icon(Icons.document_scanner_rounded, color: Colors.white),
                  label: const Text(
                    'Escanear con Inteligencia Artificial',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),

            // Diagnostic Results Section
            if (_diagnosis != null) ...[
              _buildDiagnosisResults(context, _diagnosis!, isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosisResults(BuildContext context, CoatDiagnosisResult diag, bool isDark) {
    Color scoreColor = Colors.greenAccent;
    if (diag.overallScore < 75) {
      scoreColor = Colors.orangeAccent;
    }
    if (diag.overallScore < 60) {
      scoreColor = Colors.redAccent;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Result Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Resultado del Diagnóstico',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.share, color: AppTheme.primaryColor),
              onPressed: () => _shareDiagnosis(diag),
              tooltip: 'Compartir Ficha',
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Breed Verification Banner
        if (diag.isShihTzu)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2EC4B6).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2EC4B6).withValues(alpha: 0.4), width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2EC4B6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text(
                            'Raza Verificada: Shih Tzu',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF2EC4B6),
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.verified, color: Color(0xFF2EC4B6), size: 16),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        diag.breedVerificationMessage,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4), width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.orangeAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.info_outline, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Raza Detectada: ${diag.detectedBreed}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.deepOrange,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Nota: Esta aplicación y sus cortes están optimizados para Shih Tzus. El diagnóstico visual se generó para esta mascota, pero los cortes recomendados están diseñados para la conformación de Shih Tzu.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Overall Score Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Circular Score Badge
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                  border: Border.all(color: scoreColor, width: 3),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${diag.overallScore}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'PUNTOS',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        diag.scoreLevel.toUpperCase(),
                        style: TextStyle(
                          color: scoreColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      diag.faceShape,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Evaluación médica y estética generada con Gemini Vision',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Ophthalmic & Tear Stain Cards (Side by Side)
        Row(
          children: [
            // Lagrimales
            Expanded(
              child: _buildMetricCard(
                context,
                isDark: isDark,
                icon: Icons.water_drop,
                iconColor: Colors.blueAccent,
                title: 'Lagrimales',
                status: diag.tearStainStatus,
                advice: diag.tearStainAdvice,
              ),
            ),
            const SizedBox(width: 12),
            // Zona Ocular / Córnea
            Expanded(
              child: _buildMetricCard(
                context,
                isDark: isDark,
                icon: Icons.visibility,
                iconColor: Colors.amber,
                title: 'Zona Ocular',
                status: diag.eyeRiskStatus,
                advice: diag.eyeRiskAdvice,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Coat and Matting Status
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.pets, color: Colors.purpleAccent, size: 20),
                  const SizedBox(width: 8),
                  const Text('Estado del Manto & Nudos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Riesgo: ${diag.mattingRisk}',
                      style: const TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(diag.coatCondition, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Recommended Cut Card (With instant Simulator & Tutorial Links)
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.15),
                AppTheme.goldAccent.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppTheme.goldAccent, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'CORTE RECOMENDADO POR LA IA',
                      style: TextStyle(
                        color: isDark ? AppTheme.goldAccent : Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  diag.recommendedStyleName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  diag.recommendedStyleReason,
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[300] : Colors.grey[800]),
                ),
                const SizedBox(height: 16),

                // Action Buttons: Simular Corte & Ver Video
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => _applyRecommendedStyleInSimulator(diag),
                        icon: const Icon(Icons.auto_fix_high, size: 18),
                        label: const Text('Probar en Simulador', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : AppTheme.primaryColor,
                          side: BorderSide(color: isDark ? Colors.white54 : AppTheme.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          final state = Provider.of<AppStateProvider>(context, listen: false);
                          final tut = state.getTutorialForStyle(
                            styleId: diag.recommendedStyleId,
                            styleName: diag.recommendedStyleName,
                          );
                          if (tut != null) {
                            TutorialsScreen.openTutorialGuide(context, tut);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const TutorialsScreen()),
                            );
                          }
                        },
                        icon: const Icon(Icons.play_circle_fill, size: 18),
                        label: const Text('Ver Video Guía', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Action Plan
        Text(
          'Plan de Cuidados en Casa',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 10),
        ...diag.groomingActionPlan.map((action) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(action, style: const TextStyle(fontSize: 13, height: 1.3)),
                  ),
                ],
              ),
            )),

        const SizedBox(height: 16),

        // Technical Groomer Sheet
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : const Color(0xFFF9F7FC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.content_cut, color: Colors.deepPurple, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Ficha Técnica para tu Peluquero Canino (Groomer)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepPurple),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '"${diag.groomerAdvice}"',
                style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String status,
    required String advice,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            advice,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.25),
          ),
        ],
      ),
    );
  }
}
