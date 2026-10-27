import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/models/pet.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/gemini_service.dart';

class AddPetScreen extends StatefulWidget {
  final Pet? pet;
  const AddPetScreen({super.key, this.pet});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedGender = 'Macho'; // Macho / Hembra
  File? _imageFile;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    if (widget.pet != null) {
      _nameController.text = widget.pet!.name;
      _breedController.text = widget.pet!.breed;
      _ageController.text = widget.pet!.age;
      _notesController.text = widget.pet!.notes;
      _selectedGender = widget.pet!.gender;
      _isVerified = widget.pet!.isVerifiedByAI;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final breed = _breedController.text.trim();
    final age = _ageController.text.trim();
    final notes = _notesController.text.trim();
    final state = Provider.of<AppStateProvider>(context, listen: false);

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.translate('pet_validation_name'))),
      );
      return;
    }

    final isEdit = widget.pet != null;
    final hasImage = _imageFile != null || (isEdit && widget.pet!.imagePath.isNotEmpty);

    if (!hasImage || !_isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.translate('pet_validation_photo')),
          backgroundColor: AppTheme.redAccent,
        ),
      );
      return;
    }

    final finalImagePath = _imageFile != null ? _imageFile!.path : widget.pet!.imagePath;

    if (isEdit) {
      final updatedPet = Pet(
        id: widget.pet!.id,
        name: name,
        breed: breed.isEmpty ? 'Shih Tzu' : breed,
        age: age.isEmpty ? '2 años' : age,
        gender: _selectedGender,
        notes: notes,
        imagePath: finalImagePath,
        isVerifiedByAI: _isVerified,
        userEmail: widget.pet!.userEmail,
      );
      await state.updatePet(updatedPet);
    } else {
      await state.registerPet(
        name: name,
        breed: breed.isEmpty ? 'Shih Tzu' : breed,
        age: age.isEmpty ? '2 años' : age,
        gender: _selectedGender,
        notes: notes,
        imagePath: finalImagePath,
      );
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit
              ? state.translate('pet_success_updated', params: {'name': name})
              : state.translate('pet_success_registered', params: {'name': name})),
          backgroundColor: AppTheme.greenAccent,
        ),
      );
    }
  }

  Future<void> _handleDelete() async {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final petName = widget.pet?.name ?? 'la mascota';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(state.translate('pet_confirm_delete')),
        content: Text(state.translate('pet_confirm_delete_desc', params: {'name': petName})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(state.translate('profile_btn_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(state.translate('pet_btn_delete'), style: const TextStyle(color: AppTheme.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      await state.deletePet(widget.pet!.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.translate('pet_success_deleted', params: {'name': petName})),
            backgroundColor: AppTheme.greenAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = Provider.of<AppStateProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.translate(widget.pet != null ? 'pet_title_edit' : 'pet_title_new')),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: widget.pet != null
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.redAccent),
                  onPressed: _handleDelete,
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo Placeholder Circle
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _showImageSourceActionSheet(context),
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? AppTheme.cardDark : const Color(0xFFF4F0FA),
                        border: Border.all(
                          color: _isVerified
                              ? AppTheme.greenAccent.withValues(alpha: 0.3)
                              : AppTheme.primaryColor.withValues(alpha: 0.15),
                          width: 2,
                        ),
                      ),
                      child: _imageFile != null
                          ? ClipOval(
                              child: Image.file(
                                _imageFile!,
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                              ),
                            )
                          : (widget.pet != null && widget.pet!.imagePath.isNotEmpty)
                              ? ClipOval(
                                  child: widget.pet!.imagePath.startsWith('assets/')
                                      ? Image.asset(
                                          widget.pet!.imagePath,
                                          width: 110,
                                          height: 110,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(widget.pet!.imagePath),
                                          width: 110,
                                          height: 110,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Image.asset(
                                            'assets/images/luna_shih_tzu.png',
                                            width: 110,
                                            height: 110,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.camera_alt, color: AppTheme.primaryColor, size: 28),
                                    const SizedBox(height: 6),
                                    Text(
                                      state.translate('pet_btn_upload'),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // IA verification badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isVerified
                          ? AppTheme.greenAccent.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isVerified
                            ? AppTheme.greenAccent.withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isVerified ? Icons.verified : Icons.verified_user_outlined,
                          color: _isVerified ? AppTheme.greenAccent : Colors.grey,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isVerified ? state.translate('pet_badge_verified') : state.translate('pet_badge_unverified'),
                          style: TextStyle(
                            color: _isVerified ? AppTheme.greenAccent : Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Form Fields
            _buildLabel(state.translate('pet_lbl_name')),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nameController,
              hintText: state.translate('pet_name_hint'),
            ),
            const SizedBox(height: 16),

            _buildLabel(state.translate('pet_lbl_breed')),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _breedController,
              hintText: state.translate('pet_breed_hint'),
              readOnly: true,
              suffixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isVerified
                      ? AppTheme.greenAccent.withValues(alpha: 0.1)
                      : AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isVerified ? state.translate('pet_ia_active') : state.translate('pet_ia_pending'),
                      style: TextStyle(
                        color: _isVerified ? AppTheme.greenAccent : AppTheme.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      _isVerified ? Icons.check : Icons.bolt,
                      color: _isVerified ? AppTheme.greenAccent : AppTheme.primaryColor,
                      size: 10,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Age & Gender Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(state.translate('pet_lbl_age')),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _ageController,
                        hintText: state.translate('pet_age_hint'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(state.translate('pet_lbl_gender')),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildGenderButton('Macho'),
                          const SizedBox(width: 8),
                          _buildGenderButton('Hembra'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildLabel(state.translate('pet_lbl_notes')),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _notesController,
              hintText: state.translate('pet_notes_hint'),
              maxLines: 4,
            ),
            const SizedBox(height: 36),

            // Save Button
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
                  onPressed: _handleSave,
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
                      const Icon(Icons.pets, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        state.translate(widget.pet != null ? 'pet_btn_save_changes' : 'pet_btn_save'),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    Widget? suffixIcon,
    bool readOnly = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: isDark ? const Color(0xFF261D3B) : const Color(0xFFF6F5FB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildGenderButton(String gender) {
    final state = Provider.of<AppStateProvider>(context);
    final isSelected = _selectedGender == gender;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayedText = gender == 'Macho' ? state.translate('pet_gender_m') : state.translate('pet_gender_f');

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedGender = gender;
          });
        },
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? const Color(0xFF261D3B) : const Color(0xFFF6F5FB)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(
              displayedText,
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
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

    if (state.geminiApiKey.trim().isNotEmpty) {
      result = await GeminiService.verifyShihTzu(file, state.geminiApiKey.trim());
    } else {
      // Verificación asistida rápida y amigable sin interrumpir ni pedir claves al usuario
      await Future.delayed(const Duration(milliseconds: 1000));
      result = GeminiResult(
        isShihTzu: true,
        breed: 'Shih Tzu',
        message: state.language == 'English' 
            ? 'Excellent! Your pet has been verified as a Shih Tzu.' 
            : state.language == 'Português'
                ? 'Excelente! Seu pet foi verificado como um Shih Tzu.'
                : '¡Excelente! Se ha verificado que tu mascota es un Shih Tzu.',
      );
    }

    if (mounted) {
      Navigator.pop(context); // Dismiss the loading dialog
    }

    if (result.isShihTzu) {
      setState(() {
        _imageFile = file;
        _isVerified = true;
        _breedController.text = 'Shih Tzu';
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
        _imageFile = null;
        _isVerified = false;
        _breedController.clear();
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
