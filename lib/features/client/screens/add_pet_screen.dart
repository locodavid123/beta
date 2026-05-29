import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/theme/app_theme.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedGender = 'Macho'; // Macho / Hembra
  bool _isPhotoAdded = false;

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

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa el nombre de la mascota.')),
      );
      return;
    }

    final state = Provider.of<AppStateProvider>(context, listen: false);
    
    // Choose fallback photo based on breed or randomly
    String petPhoto = 'assets/images/luna_shih_tzu.png';
    if (name.toLowerCase() == 'max') {
      petPhoto = 'assets/images/max_shih_tzu.png';
    }

    await state.registerPet(
      name: name,
      breed: breed.isEmpty ? 'Shih Tzu' : breed,
      age: age.isEmpty ? '2 años' : age,
      gender: _selectedGender,
      notes: notes,
      imagePath: petPhoto,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡$name registrada con éxito!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Mascota'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
                    onTap: () {
                      setState(() {
                        _isPhotoAdded = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Foto de la mascota cargada.')),
                      );
                    },
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? AppTheme.cardDark : const Color(0xFFF4F0FA),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.15),
                          width: 2,
                        ),
                      ),
                      child: _isPhotoAdded
                          ? const Center(
                              child: Icon(Icons.check_circle, color: AppTheme.greenAccent, size: 40),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, color: AppTheme.primaryColor, size: 28),
                                SizedBox(height: 6),
                                Text(
                                  '+ Subir foto',
                                  style: TextStyle(
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
                      color: AppTheme.greenAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.greenAccent.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: AppTheme.greenAccent, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Verificación con IA',
                          style: TextStyle(
                            color: AppTheme.greenAccent,
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
            _buildLabel('Nombre de la mascota'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nameController,
              hintText: 'Ej: Luna, Max, Coco...',
            ),
            const SizedBox(height: 16),

            _buildLabel('Raza'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _breedController,
              hintText: 'Shih Tzu (verificada)',
              suffixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'IA activa ',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.bolt, color: AppTheme.primaryColor, size: 10),
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
                      _buildLabel('Edad'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _ageController,
                        hintText: 'Ej: 2 años',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Género'),
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

            _buildLabel('Notas adicionales (opcional)'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _notesController,
              hintText: 'Alergias, preferences de corte...',
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
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pets, size: 18),
                      SizedBox(width: 10),
                      Text(
                        'Guardar Mascota',
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
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
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
    final isSelected = _selectedGender == gender;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              gender,
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
}
