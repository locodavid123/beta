import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet.dart';
import '../models/style.dart';
import '../models/creation.dart';
import '../services/firebase_service.dart';

class AppStateProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  // Navigation
  int _currentNavIndex = 0;
  int get currentNavIndex => _currentNavIndex;

  // Data lists
  List<Pet> _pets = [];
  List<Pet> get pets => _pets;

  List<ArtStyle> _styles = [];
  List<ArtStyle> get styles => _styles;

  List<Creation> _creations = [];
  List<Creation> get creations => _creations;

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

  String _geminiApiKey = '';
  String get geminiApiKey => _geminiApiKey;

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
    _geminiApiKey = prefs.getString('gemini_api_key') ?? '';
    _credits = prefs.getInt('user_credits') ?? 5;

    // Load data lists
    await refreshAllData();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshAllData() async {
    _pets = await _firebaseService.getPets();
    _styles = await _firebaseService.getStyles();
    _creations = await _firebaseService.getCreations();
    notifyListeners();
  }

  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
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

  // --- Auth Flow ---
  Future<void> loginUser(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firebaseService.signIn(email, password);
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

  Future<void> logoutUser() async {
    _isLoading = true;
    notifyListeners();
    await _firebaseService.signOut();
    _currentNavIndex = 0;
    _isLoading = false;
    notifyListeners();
  }

  // --- Pet Management ---
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
    );
    await _firebaseService.addPet(newPet);
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
  }) async {
    if (_credits <= 0) {
      throw Exception("Créditos insuficientes. Visita tu perfil para obtener más.");
    }

    _isGenerating = true;
    _generationProgress = 0.0;
    notifyListeners();

    // Simulate progress bar countdown
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
      _generationProgress = i / 10.0;
      notifyListeners();
    }

    // Generate output details
    // We use the pre-generated asset for this style
    String resultingImagePath = style.imagePath;
    String dateStr = DateTime.now().toIso8601String();
    
    // Create prompt/description
    String desc = "Un retrato majestuoso de ${pet.name} (${pet.breed}) al estilo ${style.name}. ${style.description}";

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
      date: DateTime.now(),
      likes: 12 + (DateTime.now().millisecond % 20), // random likes count
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
}
