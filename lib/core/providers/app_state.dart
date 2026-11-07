import 'dart:async';

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
  StreamSubscription<Map<String, dynamic>>? _systemSettingsSubscription;

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

  int _credits = 0;
  int get credits => _credits;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _initializationError;
  String? get initializationError => _initializationError;
  bool _publicRegistrationEnabled = true;
  bool get publicRegistrationEnabled => _publicRegistrationEnabled;
  bool _maintenanceMode = false;
  bool get maintenanceMode => _maintenanceMode;

  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;
  double _generationProgress = 0.0;
  double get generationProgress => _generationProgress;

  // Auth Status
  bool get isAuthenticated => _firebaseService.currentUserEmail != null;
  String get userName => _firebaseService.currentUserName;
  String get userEmail =>
      _firebaseService.currentUserEmail ?? 'invitado@correo.com';
  String get userRole => _firebaseService.currentUserRole;

  // Constructor
  AppStateProvider() {
    _initApp();
  }

  Future<void> _initApp() async {
    _isLoading = true;
    _initializationError = null;
    notifyListeners();

    try {
      await _systemSettingsSubscription?.cancel();
      _systemSettingsSubscription = null;
      await _firebaseService.init();
      _applySystemSettings(await _firebaseService.getSystemSettings());
      _systemSettingsSubscription = _firebaseService
          .watchSystemSettings()
          .listen(
            _applySystemSettings,
            onError: (Object error, StackTrace stackTrace) {
              _initializationError =
                  'No se pudo sincronizar la configuración de Firebase: $error';
              notifyListeners();
            },
          );

      final prefs = await SharedPreferences.getInstance();
      final savedApiKey = prefs.getString('gemini_api_key');
      if (savedApiKey != null &&
          savedApiKey.trim().isNotEmpty &&
          !savedApiKey.contains('AIzaSyBFWudg')) {
        _geminiApiKey = savedApiKey.trim();
      } else {
        _geminiApiKey = AppConfig.defaultGeminiApiKey.trim();
        await prefs.setString('gemini_api_key', _geminiApiKey);
      }

      _userPhoto = _firebaseService.currentUserPhoto;
      if (isAuthenticated) {
        final profile = await _firebaseService.getCurrentUserProfile();
        _credits = (profile['credits'] as num?)?.toInt() ?? 0;
        _isDarkMode = profile['isDarkMode'] as bool? ?? false;
        _language = profile['language'] as String? ?? 'Español';
        _pushNotifications = profile['pushNotifications'] as bool? ?? true;
        _emailNotifications = profile['emailNotifications'] as bool? ?? false;
        _imageQuality =
            profile['imageQuality'] as String? ?? 'Alta (más lento)';
        _favoriteTutorialIds = await _firebaseService.getCurrentUserList(
          'favoriteTutorialIds',
        );
        _completedTutorialIds = await _firebaseService.getCurrentUserList(
          'completedTutorialIds',
        );
      } else {
        _credits = 0;
        _isDarkMode = false;
        _language = 'Español';
        _pushNotifications = true;
        _emailNotifications = false;
        _imageQuality = 'Alta (más lento)';
        _favoriteTutorialIds = [];
        _completedTutorialIds = [];
      }

      await refreshAllData();
    } catch (e) {
      _initializationError = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retryInitialization() => _initApp();

  void _applySystemSettings(Map<String, dynamic> settings) {
    _publicRegistrationEnabled =
        settings['publicRegistration'] as bool? ?? true;
    _maintenanceMode = settings['maintenanceMode'] as bool? ?? false;
    notifyListeners();
  }

  Future<void> refreshAllData() async {
    _pets = await _firebaseService.getPets();
    _styles = await _firebaseService.getStyles();
    _creations = await _firebaseService.getCreations();
    _tutorials = await _firebaseService.getTutorials();
    _reports = await _firebaseService.getReports();
    if (userRole == 'admin' || userRole == 'root') {
      _users = await _firebaseService.getUsers();
    } else {
      _users = [];
    }
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
    await _firebaseService.updateCurrentUserFields({'isDarkMode': value});
    _isDarkMode = value;
    notifyListeners();
  }

  // --- Settings modifications ---
  Future<void> setLanguage(String value) async {
    await _firebaseService.updateCurrentUserFields({'language': value});
    _language = value;
    notifyListeners();
  }

  Future<void> setPushNotifications(bool value) async {
    await _firebaseService.updateCurrentUserFields({
      'pushNotifications': value,
    });
    _pushNotifications = value;
    notifyListeners();
  }

  Future<void> setEmailNotifications(bool value) async {
    await _firebaseService.updateCurrentUserFields({
      'emailNotifications': value,
    });
    _emailNotifications = value;
    notifyListeners();
  }

  Future<void> setImageQuality(String value) async {
    await _firebaseService.updateCurrentUserFields({'imageQuality': value});
    _imageQuality = value;
    notifyListeners();
  }

  Future<void> setGeminiApiKey(String value) async {
    _geminiApiKey = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', value);
    notifyListeners();
  }

  Future<void> addCredits(int amount) async {
    final nextCredits = _credits + amount;
    await _firebaseService.updateCurrentUserFields({'credits': nextCredits});
    _credits = nextCredits;
    notifyListeners();
  }

  Future<void> toggleFavoriteTutorial(String id) async {
    await _firebaseService.toggleCurrentUserListValue(
      'favoriteTutorialIds',
      id,
    );
    _favoriteTutorialIds = await _firebaseService.getCurrentUserList(
      'favoriteTutorialIds',
    );
    notifyListeners();
  }

  Future<void> toggleCompletedTutorial(String id) async {
    await _firebaseService.toggleCurrentUserListValue(
      'completedTutorialIds',
      id,
    );
    _completedTutorialIds = await _firebaseService.getCurrentUserList(
      'completedTutorialIds',
    );
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
      if ((sId.contains('cachorro') ||
              sName.contains('cachorro') ||
              sName.contains('puppy')) &&
          (tTitle.contains('puppy') || tTitle.contains('cachorro'))) {
        return t;
      }
      if ((sId.contains('oso') ||
              sName.contains('oso') ||
              sName.contains('teddy')) &&
          (tTitle.contains('oso') || tTitle.contains('teddy'))) {
        return t;
      }
      if ((sId.contains('leon') ||
              sName.contains('león') ||
              sName.contains('leon')) &&
          (tTitle.contains('león') || tTitle.contains('leon'))) {
        return t;
      }
      if ((sId.contains('exhibicion') ||
              sName.contains('exhibición') ||
              sName.contains('exposicion') ||
              sName.contains('manto')) &&
          (tTitle.contains('exhibición') ||
              tTitle.contains('exposicion') ||
              tTitle.contains('manto'))) {
        return t;
      }
      if ((sId.contains('topknot') ||
              sName.contains('top knot') ||
              sName.contains('moño')) &&
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
      final profile = await _firebaseService.getCurrentUserProfile();
      _credits = (profile['credits'] as num?)?.toInt() ?? 0;
      _favoriteTutorialIds = await _firebaseService.getCurrentUserList(
        'favoriteTutorialIds',
      );
      _completedTutorialIds = await _firebaseService.getCurrentUserList(
        'completedTutorialIds',
      );
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
      _credits = await _firebaseService.getCurrentUserCredits();
      _favoriteTutorialIds = await _firebaseService.getCurrentUserList(
        'favoriteTutorialIds',
      );
      _completedTutorialIds = await _firebaseService.getCurrentUserList(
        'completedTutorialIds',
      );
      await refreshAllData();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reloadUsers() async {
    _users = userRole == 'admin' || userRole == 'root'
        ? await _firebaseService.getUsers()
        : [];
    notifyListeners();
  }

  Future<void> updateUserRoleAndCredits(
    String email,
    String role,
    int credits, [
    String? name,
  ]) async {
    await _firebaseService.updateUserInDatabase(email, role, credits, name);
    if (email.trim().toLowerCase() == userEmail.trim().toLowerCase()) {
      _credits = credits;
    }
    await reloadUsers();
  }

  Future<void> createUserFromAdmin(
    String name,
    String email,
    String role, [
    int credits = 5,
    String password = '',
  ]) async {
    await _firebaseService.addUserToDatabase(
      name,
      email,
      role,
      credits,
      password,
    );
    await reloadUsers();
  }

  Future<void> deactivateUser(String email) async {
    await _firebaseService.deactivateUserInDatabase(email);
    await reloadUsers();
  }

  Future<void> addUserCredits(String email, int amount) async {
    final cleanEmail = email.trim().toLowerCase();
    final user = _users.firstWhere(
      (u) => (u['email'] ?? '').toString().trim().toLowerCase() == cleanEmail,
      orElse: () => {},
    );
    if (user.isEmpty) throw StateError('Usuario no encontrado en Firestore.');
    final currentCredits = (user['credits'] as num?)?.toInt() ?? 0;
    final newCredits = currentCredits + amount;
    final role = (user['role'] as String?) ?? 'client';
    final name = (user['name'] as String?) ?? 'Usuario';
    await updateUserRoleAndCredits(cleanEmail, role, newCredits, name);
  }

  Future<void> logoutUser() async {
    _isLoading = true;
    notifyListeners();

    await _firebaseService.signOut();

    _userPhoto = '';
    _credits = 0;
    _favoriteTutorialIds = [];
    _completedTutorialIds = [];
    _selectedSimulatorStyle = null;
    _selectedSimulatorPet = null;
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

  // --- Grooming simulation ---
  Future<Creation?> generateArt({
    required Pet pet,
    required ArtStyle style,
  }) async {
    if (_credits <= 0) {
      throw Exception(
        "Créditos insuficientes. Visita tu perfil para obtener más.",
      );
    }

    _isGenerating = true;
    _generationProgress = 0.0;
    notifyListeners();

    try {
      if (pet.imagePath.isEmpty || style.imagePath.isEmpty) {
        throw Exception(
          'Selecciona una foto del perro y una referencia de estilo.',
        );
      }

      _generationProgress = 0.2;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 900));
      _generationProgress = 0.8;
      notifyListeners();

      final newCreation = Creation(
        id: 'creation_${DateTime.now().millisecondsSinceEpoch}',
        petId: pet.id,
        petName: pet.name,
        styleId: style.id,
        styleName: style.name,
        imagePath: style.imagePath,
        originalImagePath: pet.imagePath,
        date: DateTime.now(),
        likes: 0,
        description:
            'Vista de referencia del estilo "${style.name}" para ${pet.name}. Esta imagen ilustra el corte, pero no es una transformación de la foto de la mascota.',
      );

      _credits = await _firebaseService.addCreationAndConsumeCredit(
        newCreation,
      );
      await refreshAllData();
      return newCreation;
    } finally {
      _isGenerating = false;
      _generationProgress = 0.0;
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    await _firebaseService.clearCurrentUserCreations();
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
    await _firebaseService.updateCurrentUserFields({'credits': amount});
    _credits = amount;
    notifyListeners();
  }

  Future<Map<String, dynamic>> getSystemSettings() =>
      _firebaseService.getSystemSettings();

  Future<void> setSystemSetting(String key, bool value) async {
    await _firebaseService.updateSystemSetting(key, value);
    if (key == 'publicRegistration') _publicRegistrationEnabled = value;
    if (key == 'maintenanceMode') _maintenanceMode = value;
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

  @override
  void dispose() {
    _systemSettingsSubscription?.cancel();
    super.dispose();
  }
}
