import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet.dart';
import '../models/style.dart';
import '../models/creation.dart';
import '../models/tutorial.dart';
import '../models/report.dart';
import '../services/firebase_service.dart';
import '../utils/translations.dart';
import '../config/app_config.dart';

class AppStateProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  // Navigation
  int _currentNavIndex = 0;
  int get currentNavIndex => _currentNavIndex;

  // Preselected items for simulator navigation
  ArtStyle? _selectedSimulatorStyle;
  ArtStyle? get selectedSimulatorStyle => _selectedSimulatorStyle;

  Pet? _selectedSimulatorPet;
  Pet? get selectedSimulatorPet => _selectedSimulatorPet;

  // Data lists
  List<Pet> _pets = [];
  List<Pet> get pets => _pets;

  List<ArtStyle> _styles = [];
  List<ArtStyle> get styles => _styles;

  List<Creation> _creations = [];
  List<Creation> get creations => _creations;

  List<Tutorial> _tutorials = [];
  List<Tutorial> get tutorials => _tutorials;

  List<String> _favoriteTutorialIds = [];
  List<String> get favoriteTutorialIds => _favoriteTutorialIds;

  List<String> _completedTutorialIds = [];
  List<String> get completedTutorialIds => _completedTutorialIds;

  bool isTutorialFavorite(String id) => _favoriteTutorialIds.contains(id);
  bool isTutorialCompleted(String id) => _completedTutorialIds.contains(id);

  double get tutorialCompletionProgress {
    final published = _tutorials.where((t) => t.status == 'publicado').toList();
    if (published.isEmpty) return 0.0;
    return (_completedTutorialIds.length / published.length).clamp(0.0, 1.0);
  }

  List<ModerationReport> _reports = [];
  List<ModerationReport> get reports => _reports;

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> get users => _users;

  // App settings
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  String _language = 'Español';
  String get language => _language;

  bool _pushNotifications = true;
  bool get pushNotifications => _pushNotifications;

  bool _emailNotifications = false;
  bool get emailNotifications => _emailNotifications;

  String _imageQuality = 'Alta (más lento)';
  String get imageQuality => _imageQuality;

  String _geminiApiKey = AppConfig.defaultGeminiApiKey;
  String get geminiApiKey => _geminiApiKey;

  String _userPhoto = '';
  String get userPhoto => _userPhoto;

  int _credits = 5;
  int get credits => _credits;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;
  double _generationProgress = 0.0;
  double get generationProgress => _generationProgress;

  // Auth Status
  bool get isAuthenticated => _firebaseService.currentUserEmail != null;
  String get userName => _firebaseService.currentUserName;
  String get userEmail => _firebaseService.currentUserEmail ?? 'invitado@correo.com';
  String get userRole => _firebaseService.currentUserRole;

  // Constructor
  AppStateProvider() {
    _initApp();
  }

  Future<void> _initApp() async {
    _isLoading = true;
    notifyListeners();

    // Init Firebase/Mock
    await _firebaseService.init();

    // Load Settings from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    _language = prefs.getString('language') ?? 'Español';
    _pushNotifications = prefs.getBool('push_notifications') ?? true;
    _emailNotifications = prefs.getBool('email_notifications') ?? false;
    _imageQuality = prefs.getString('image_quality') ?? 'Alta (más lento)';
    final savedApiKey = prefs.getString('gemini_api_key');
    if (savedApiKey != null &&
        savedApiKey.trim().isNotEmpty &&
        !savedApiKey.contains('AIzaSyBFWudg')) {
      _geminiApiKey = savedApiKey.trim();
    } else {
      _geminiApiKey = AppConfig.defaultGeminiApiKey.trim();
      await prefs.setString('gemini_api_key', _geminiApiKey);
    }
    _credits = prefs.getInt('user_credits') ?? 5;
    _userPhoto = prefs.getString('user_photo') ?? '';
    _favoriteTutorialIds = prefs.getStringList('favorite_tutorials') ?? [];
    _completedTutorialIds = prefs.getStringList('completed_tutorials') ?? [];

    // Load data lists
    await refreshAllData();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshAllData() async {
    try {
      _pets = await _firebaseService.getPets();
    } catch (_) {}
    try {
      _styles = await _firebaseService.getStyles();
    } catch (_) {}
    try {
      _creations = await _firebaseService.getCreations();
    } catch (_) {}
    try {
      _tutorials = await _firebaseService.getTutorials();
    } catch (_) {}
    try {
      _reports = await _firebaseService.getReports();
    } catch (_) {}
    try {
      _users = await _firebaseService.getUsers();
    } catch (_) {}
    notifyListeners();
  }

  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }

  void selectStyleForSimulation(ArtStyle style, {Pet? pet}) {
    _selectedSimulatorStyle = style;
    if (pet != null) {
      _selectedSimulatorPet = pet;
    }
    _currentNavIndex = 2; // Jump to Simulator tab
    notifyListeners();
  }

  void clearSimulatorPreselection() {
    _selectedSimulatorStyle = null;
    _selectedSimulatorPet = null;
  }

  // --- Theme Mode ---
  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', value);
    notifyListeners();
  }

  // --- Settings modifications ---
  Future<void> setLanguage(String value) async {
    _language = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', value);
    notifyListeners();
  }

  Future<void> setPushNotifications(bool value) async {
    _pushNotifications = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications', value);
    notifyListeners();
  }

  Future<void> setEmailNotifications(bool value) async {
    _emailNotifications = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('email_notifications', value);
    notifyListeners();
  }

  Future<void> setImageQuality(String value) async {
    _imageQuality = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('image_quality', value);
    notifyListeners();
  }

  Future<void> setGeminiApiKey(String value) async {
    _geminiApiKey = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', value);
    notifyListeners();
  }

  Future<void> addCredits(int amount) async {
    _credits += amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_credits', _credits);
    notifyListeners();
  }

  Future<void> toggleFavoriteTutorial(String id) async {
    if (_favoriteTutorialIds.contains(id)) {
      _favoriteTutorialIds.remove(id);
    } else {
      _favoriteTutorialIds.add(id);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_tutorials', _favoriteTutorialIds);
    notifyListeners();
  }

  Future<void> toggleCompletedTutorial(String id) async {
    if (_completedTutorialIds.contains(id)) {
      _completedTutorialIds.remove(id);
    } else {
      _completedTutorialIds.add(id);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('completed_tutorials', _completedTutorialIds);
    notifyListeners();
  }

  /// Retorna el tutorial de video y técnica paso a paso más adecuado para un corte o estilo
  Tutorial? getTutorialForStyle({String? styleId, String? styleName}) {
    if (_tutorials.isEmpty) return null;
    final sId = (styleId ?? '').toLowerCase();
    final sName = (styleName ?? '').toLowerCase();

    // Coincidencia exacta por palabras clave de cortes de Shih Tzu
    for (final t in _tutorials) {
      final tTitle = t.title.toLowerCase();
      if ((sId.contains('cachorro') || sName.contains('cachorro') || sName.contains('puppy')) &&
          (tTitle.contains('puppy') || tTitle.contains('cachorro'))) {
        return t;
      }
      if ((sId.contains('oso') || sName.contains('oso') || sName.contains('teddy')) &&
          (tTitle.contains('oso') || tTitle.contains('teddy'))) {
        return t;
      }
      if ((sId.contains('leon') || sName.contains('león') || sName.contains('leon')) &&
          (tTitle.contains('león') || tTitle.contains('leon'))) {
        return t;
      }
      if ((sId.contains('exhibicion') || sName.contains('exhibición') || sName.contains('exposicion') || sName.contains('manto')) &&
          (tTitle.contains('exhibición') || tTitle.contains('exposicion') || tTitle.contains('manto'))) {
        return t;
      }
      if ((sId.contains('topknot') || sName.contains('top knot') || sName.contains('moño')) &&
          (tTitle.contains('top knot') || tTitle.contains('moño'))) {
        return t;
      }
    }

    // Coincidencia secundaria: cualquier palabra en común con cortes
    for (final t in _tutorials) {
      if (t.category == 'Cortes') {
        final words = sName.split(' ');
        for (final w in words) {
          if (w.length > 3 && t.title.toLowerCase().contains(w)) {
            return t;
          }
        }
      }
    }

    // Fallback: primer tutorial de categoría 'Cortes' o el primero existente
    return _tutorials.firstWhere(
      (t) => t.category == 'Cortes',
      orElse: () => _tutorials.first,
    );
  }

  // --- Auth Flow ---
  Future<void> loginUser(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firebaseService.signIn(email, password);
      _userPhoto = _firebaseService.currentUserPhoto;
      await refreshAllData();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerUser(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firebaseService.signUp(email, password, name);
      _userPhoto = '';
      _credits = 5; // new accounts get 5 credits
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_credits', 5);
      await refreshAllData();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reloadUsers() async {
    _users = await _firebaseService.getUsers();
    notifyListeners();
  }

  Future<void> updateUserRoleAndCredits(String email, String role, int credits, [String? name, String? password]) async {
    await _firebaseService.updateUserInDatabase(email, role, credits, name, password);
    if (email.trim().toLowerCase() == userEmail.trim().toLowerCase()) {
      _credits = credits;
    }
    await reloadUsers();
  }

  Future<void> createUserFromAdmin(String name, String email, String role, [int credits = 5, String password = 'password123']) async {
    await _firebaseService.addUserToDatabase(name, email, role, credits, password);
    await reloadUsers();
  }

  Future<void> deleteUser(String email) async {
    await _firebaseService.deleteUserFromDatabase(email);
    await reloadUsers();
  }

  Future<void> addUserCredits(String email, int amount) async {
    final cleanEmail = email.trim().toLowerCase();
    final user = _users.firstWhere(
      (u) => (u['email'] ?? '').toString().trim().toLowerCase() == cleanEmail,
      orElse: () => {},
    );
    final currentCredits = (user['credits'] as int?) ?? (cleanEmail == 'cliente_prueba@email.com' ? _credits : 5);
    final newCredits = currentCredits + amount;
    final role = (user['role'] as String?) ?? 'client';
    final name = (user['name'] as String?) ?? (cleanEmail == 'cliente_prueba@email.com' ? 'Valentina López' : 'Usuario');
    await updateUserRoleAndCredits(cleanEmail, role, newCredits, name);
  }

  Future<void> logoutUser() async {
    _isLoading = true;
    notifyListeners();
    await _firebaseService.signOut();
    _userPhoto = '';
    _currentNavIndex = 0;
    await refreshAllData();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> registerPet({
    required String name,
    required String breed,
    required String age,
    required String gender,
    required String notes,
    required String imagePath,
  }) async {
    final newPet = Pet(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      breed: breed,
      age: age,
      gender: gender,
      notes: notes,
      imagePath: imagePath,
      isVerifiedByAI: true,
      userEmail: userEmail,
    );
    await _firebaseService.addPet(newPet);
    await refreshAllData();
  }

  Future<void> updatePet(Pet pet) async {
    await _firebaseService.updatePet(pet);
    await refreshAllData();
  }

  Future<void> deletePet(String id) async {
    await _firebaseService.deletePet(id);
    await refreshAllData();
  }

  // --- Art Style Dynamic Management ---
  Future<void> registerStyle({
    required String name,
    required String category,
    required String imagePath,
    required String description,
    bool isHot = false,
  }) async {
    final newStyle = ArtStyle(
      id: name.toLowerCase().replaceAll(' ', '_'),
      name: name,
      category: category,
      imagePath: imagePath,
      description: description,
      isHot: isHot,
    );
    await _firebaseService.addStyle(newStyle);
    await refreshAllData();
  }

  // --- Generation Logic (Simulated or Real Gemini) ---
  Future<Creation?> generateArt({
    required Pet pet,
    required ArtStyle style,
    String coatColor = 'Dorado y Blanco',
  }) async {
    if (_credits <= 0) {
      throw Exception("Créditos insuficientes. Visita tu perfil para obtener más.");
    }

    _isGenerating = true;
    _generationProgress = 0.0;
    notifyListeners();

    // Simulación de progreso con pasos realistas de estilismo
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
      _generationProgress = i / 10.0;
      notifyListeners();
    }

    // Selección inteligente de la imagen según la tonalidad del pelaje
    String resultingImagePath = style.imagePath;

    final lowerColor = coatColor.toLowerCase();
    final petNotes = '${pet.name} ${pet.notes}'.toLowerCase();
    final isBlackAndWhite = lowerColor.contains('negro') ||
        lowerColor.contains('panda') ||
        petNotes.contains('negro') ||
        petNotes.contains('panda') ||
        petNotes.contains('black');

    if (isBlackAndWhite) {
      if (style.id == 'corte_cachorro') {
        resultingImagePath = 'assets/images/corte_cachorro_bw.png';
      } else if (style.id == 'corte_oso') {
        resultingImagePath = 'assets/images/corte_oso_bw.png';
      }
    }

    // Descripción personalizada para esta mascota y corte
    String desc = '${pet.name} luce espectacular con su nuevo "${style.name}". Pelaje estilizado en salón profesional con acabado sedoso, líneas de corte definidas y contorno adaptado a su carita de Shih Tzu.';

    // Subtract 1 credit
    _credits -= 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_credits', _credits);

    final newCreation = Creation(
      id: 'creation_${DateTime.now().millisecondsSinceEpoch}',
      petId: pet.id,
      petName: pet.name,
      styleId: style.id,
      styleName: style.name,
      imagePath: resultingImagePath,
      originalImagePath: pet.imagePath,
      date: DateTime.now(),
      likes: 12 + (DateTime.now().millisecond % 20),
      description: desc,
    );

    await _firebaseService.addCreation(newCreation);
    await refreshAllData();

    _isGenerating = false;
    notifyListeners();
    return newCreation;
  }

  // Clear history local mock
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mock_creations');
    _creations.clear();
    await refreshAllData();
  }

  // --- Dynamic Style CRUD ---
  Future<void> updateStyle(ArtStyle style) async {
    await _firebaseService.updateStyle(style);
    await refreshAllData();
  }

  Future<void> deleteStyle(String id) async {
    await _firebaseService.deleteStyle(id);
    await refreshAllData();
  }

  // --- Tutorials CRUD ---
  Future<void> addTutorial({
    required String title,
    required String duration,
    required String difficulty,
    String status = 'publicado',
  }) async {
    final newTutorial = Tutorial(
      id: 't_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      duration: duration,
      difficulty: difficulty,
      status: status,
    );
    await _firebaseService.addTutorial(newTutorial);
    await refreshAllData();
  }

  Future<void> updateTutorial(Tutorial tutorial) async {
    await _firebaseService.updateTutorial(tutorial);
    await refreshAllData();
  }

  Future<void> deleteTutorial(String id) async {
    await _firebaseService.deleteTutorial(id);
    await refreshAllData();
  }

  // --- Moderation CRUD ---
  Future<void> addReport({
    required String userEmail,
    required String reason,
    required String creationId,
    required String creationImagePath,
    required String priority,
  }) async {
    final newReport = ModerationReport(
      id: 'r_${DateTime.now().millisecondsSinceEpoch}',
      userEmail: userEmail,
      reason: reason,
      creationId: creationId,
      creationImagePath: creationImagePath,
      priority: priority,
      date: DateTime.now(),
    );
    await _firebaseService.addReport(newReport);
    await refreshAllData();
  }

  Future<void> resolveReport(String id) async {
    await _firebaseService.resolveReport(id);
    await refreshAllData();
  }

  // Set user credits dynamically (Admin/Root utility)
  Future<void> setUserCredits(int amount) async {
    _credits = amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_credits', amount);
    notifyListeners();
  }

  Future<void> updateUserProfile({
    required String name,
    required String photoPath,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firebaseService.updateProfile(name: name, photoPath: photoPath);
      _userPhoto = photoPath;
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firebaseService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String translate(String key, {Map<String, String>? params}) {
    return AppTranslations.translate(key, _language, params: params);
  }
}
