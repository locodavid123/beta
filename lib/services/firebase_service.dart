import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pet.dart';
import '../models/style.dart';
import '../models/creation.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _isFirebaseInitialized = false;
  bool get isFirebaseInitialized => _isFirebaseInitialized;

  // Local memory cache/mock if Firebase is unavailable
  final List<Pet> _mockPets = [];
  final List<ArtStyle> _mockStyles = [];
  final List<Creation> _mockCreations = [];
  
  // Active user details
  String? _currentUserEmail;
  String? _currentUserName;

  // Initialize service
  Future<void> init() async {
    try {
      // Try to initialize Firebase
      await Firebase.initializeApp();
      _isFirebaseInitialized = true;
      if (kDebugMode) {
        print("Firebase initialized successfully.");
      }
      
      // Load initial dynamic styles in Firestore if empty
      await _seedStylesInFirestore();
    } catch (e) {
      _isFirebaseInitialized = false;
      if (kDebugMode) {
        print("Firebase initialization failed/skipped: $e. Falling back to local storage.");
      }
      // Load local mock data
      await _loadLocalMockData();
    }
  }

  // Seed initial styles in Firestore
  Future<void> _seedStylesInFirestore() async {
    if (!_isFirebaseInitialized) return;
    try {
      final stylesColl = FirebaseFirestore.instance.collection('styles');
      final snapshot = await stylesColl.limit(1).get();
      if (snapshot.docs.isEmpty) {
        // Add default styles
        for (var s in _getDefaultStyles()) {
          await stylesColl.doc(s.id).set(s.toMap());
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error seeding styles: $e");
      }
    }
  }

  // Load local data from SharedPreferences if Firebase is disabled
  Future<void> _loadLocalMockData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Auth status
    _currentUserEmail = prefs.getString('user_email');
    _currentUserName = prefs.getString('user_name') ?? 'Valentina López';

    // Load styles
    final stylesJson = prefs.getStringList('mock_styles');
    if (stylesJson != null && stylesJson.isNotEmpty) {
      _mockStyles.clear();
      for (var s in stylesJson) {
        _mockStyles.add(ArtStyle.fromMap(jsonDecode(s)));
      }
    } else {
      _mockStyles.addAll(_getDefaultStyles());
      await _saveMockStyles();
    }

    // Load pets
    final petsJson = prefs.getStringList('mock_pets');
    if (petsJson != null) {
      _mockPets.clear();
      for (var p in petsJson) {
        _mockPets.add(Pet.fromMap(jsonDecode(p)));
      }
    } else {
      // Default pets
      _mockPets.addAll([
        Pet(
          id: 'luna',
          name: 'Luna',
          breed: 'Shih Tzu',
          age: '3 años',
          gender: 'Hembra',
          notes: 'Alergias, preferencias de corte...',
          imagePath: 'assets/images/luna_shih_tzu.png',
          isVerifiedByAI: true,
        ),
        Pet(
          id: 'max',
          name: 'Max',
          breed: 'Shih Tzu',
          age: '5 años',
          gender: 'Macho',
          notes: 'Muy juguetón y amigable.',
          imagePath: 'assets/images/max_shih_tzu.png',
          isVerifiedByAI: true,
        ),
      ]);
      await _saveMockPets();
    }

    // Load creations
    final creationsJson = prefs.getStringList('mock_creations');
    if (creationsJson != null) {
      _mockCreations.clear();
      for (var c in creationsJson) {
        _mockCreations.add(Creation.fromMap(jsonDecode(c)));
      }
    } else {
      // Initial creations for Valentina
      _mockCreations.addAll([
        Creation(
          id: 'c1',
          petId: 'luna',
          petName: 'Luna',
          styleId: 'realeza',
          styleName: 'Realeza Imperial',
          imagePath: 'assets/images/realeza_imperial.png',
          date: DateTime.now().subtract(const Duration(hours: 3)),
          likes: 24,
          description: 'Un retrato majestuoso de Luna en el estilo de la dinastía imperial china. Pelaje de seda dorada y una corona real con joyas incrustadas.',
        ),
        Creation(
          id: 'c2',
          petId: 'max',
          petName: 'Max',
          styleId: 'cosmico',
          styleName: 'Fantasía Cósmica',
          imagePath: 'assets/images/fantasia_cosmica.png',
          date: DateTime.now().subtract(const Duration(days: 1)),
          likes: 11,
          description: 'Un retrato espacial de Max flotando entre nebulosas galácticas púrpuras y destellos de estrellas brillantes.',
        ),
        Creation(
          id: 'c3',
          petId: 'luna',
          petName: 'Luna',
          styleId: 'cyberpunk',
          styleName: 'Cyberpunk Neon',
          imagePath: 'assets/images/cyberpunk_neon.png',
          date: DateTime.now().subtract(const Duration(days: 5)),
          likes: 8,
          description: 'Luna con gafas de sol futuristas y fondo de ciudad ciberpunk iluminada con luces de neón rosa y cian.',
        ),
        Creation(
          id: 'c4',
          petId: 'luna',
          petName: 'Luna',
          styleId: 'acuarela',
          styleName: 'Acuarela Suave',
          imagePath: 'assets/images/acuarela_suave.png',
          date: DateTime.now().subtract(const Duration(days: 8)),
          likes: 17,
          description: 'Pintura artística de Luna en estilo acuarela suave con tonos pastel mezclados armoniosamente.',
        ),
      ]);
      await _saveMockCreations();
    }
  }

  // SharedPreferences persistence helper methods
  Future<void> _saveMockPets() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _mockPets.map((p) => jsonEncode(p.toMap())).toList();
    await prefs.setStringList('mock_pets', data);
  }

  Future<void> _saveMockStyles() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _mockStyles.map((s) => jsonEncode(s.toMap())).toList();
    await prefs.setStringList('mock_styles', data);
  }

  Future<void> _saveMockCreations() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _mockCreations.map((c) => jsonEncode(c.toMap())).toList();
    await prefs.setStringList('mock_creations', data);
  }

  List<ArtStyle> _getDefaultStyles() {
    return [
      ArtStyle(
        id: 'realeza',
        name: 'Realeza Imperial',
        category: 'Clásico',
        imagePath: 'assets/images/realeza_imperial.png',
        description: 'Un retrato majestuoso de tu mascota vestido en ropajes de la realeza imperial con detalles dorados y corona.',
        isHot: true,
      ),
      ArtStyle(
        id: 'cosmico',
        name: 'Fantasía Cósmica',
        category: 'Fantasía',
        imagePath: 'assets/images/fantasia_cosmica.png',
        description: 'Tu mascota flotando en el espacio rodeado de galaxias, nebulosas y estrellas brillantes.',
        isHot: false,
      ),
      ArtStyle(
        id: 'cyberpunk',
        name: 'Cyberpunk Neon',
        category: 'Sci-Fi',
        imagePath: 'assets/images/cyberpunk_neon.png',
        description: 'Luces de neón intensas, lentes de sol tecnológicos y un ambiente urbano futurista.',
        isHot: true,
      ),
      ArtStyle(
        id: 'acuarela',
        name: 'Acuarela Suave',
        category: 'Arte',
        imagePath: 'assets/images/acuarela_suave.png',
        description: 'Trazo suave con salpicaduras de colores y pintura artística de acuarela.',
        isHot: false,
      ),
      ArtStyle(
        id: 'steampunk',
        name: 'Steampunk',
        category: 'Steampunk',
        imagePath: 'assets/images/steampunk.png',
        description: 'Engranajes de bronce, tubos de vapor y accesorios antiguos del siglo XIX.',
        isHot: false,
      ),
      ArtStyle(
        id: 'kawaii',
        name: 'Kawaii Pastel',
        category: 'Cute',
        imagePath: 'assets/images/kawaii_pastel.png',
        description: 'Un estilo super tierno y animado con colores pastel rosas, corazones y destellos de felicidad.',
        isHot: true,
      ),
    ];
  }

  // --- Auth Service API ---
  Future<UserCredential?> signIn(String email, String password) async {
    if (_isFirebaseInitialized) {
      try {
        return await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      } catch (e) {
        rethrow;
      }
    } else {
      // Mock Auth
      if (email.isNotEmpty && password.length >= 6) {
        _currentUserEmail = email;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', email);
        return null; // Return null but set internal auth status
      } else {
        throw Exception("Credenciales incorrectas (mínimo 6 caracteres en contraseña).");
      }
    }
  }

  Future<UserCredential?> signUp(String email, String password, String name) async {
    if (_isFirebaseInitialized) {
      try {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        await FirebaseFirestore.instance.collection('users').doc(cred.user?.uid).set({
          'name': name,
          'email': email,
          'credits': 5,
        });
        return cred;
      } catch (e) {
        rethrow;
      }
    } else {
      // Mock SignUp
      if (email.isNotEmpty && password.length >= 6) {
        _currentUserEmail = email;
        _currentUserName = name;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', email);
        await prefs.setString('user_name', name);
        return null;
      } else {
        throw Exception("Datos inválidos.");
      }
    }
  }

  Future<void> signOut() async {
    if (_isFirebaseInitialized) {
      await FirebaseAuth.instance.signOut();
    } else {
      _currentUserEmail = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_email');
    }
  }

  String? get currentUserEmail => _isFirebaseInitialized ? FirebaseAuth.instance.currentUser?.email : _currentUserEmail;
  String get currentUserName => _currentUserName ?? 'Usuario';

  // --- Pets API ---
  Future<List<Pet>> getPets() async {
    if (_isFirebaseInitialized) {
      try {
        final snapshot = await FirebaseFirestore.instance.collection('pets').get();
        return snapshot.docs.map((doc) => Pet.fromMap(doc.data())).toList();
      } catch (e) {
        if (kDebugMode) print("Error fetching pets: $e");
        return _mockPets;
      }
    } else {
      return _mockPets;
    }
  }

  Future<void> addPet(Pet pet) async {
    if (_isFirebaseInitialized) {
      try {
        await FirebaseFirestore.instance.collection('pets').doc(pet.id).set(pet.toMap());
      } catch (e) {
        if (kDebugMode) print("Error adding pet: $e");
        _mockPets.add(pet);
        await _saveMockPets();
      }
    } else {
      _mockPets.add(pet);
      await _saveMockPets();
    }
  }

  // --- Styles API (Dynamic Catalogue) ---
  Future<List<ArtStyle>> getStyles() async {
    if (_isFirebaseInitialized) {
      try {
        final snapshot = await FirebaseFirestore.instance.collection('styles').get();
        if (snapshot.docs.isEmpty) {
          return _mockStyles;
        }
        return snapshot.docs.map((doc) => ArtStyle.fromMap(doc.data())).toList();
      } catch (e) {
        if (kDebugMode) print("Error fetching styles: $e");
        return _mockStyles;
      }
    } else {
      return _mockStyles;
    }
  }

  Future<void> addStyle(ArtStyle style) async {
    if (_isFirebaseInitialized) {
      try {
        await FirebaseFirestore.instance.collection('styles').doc(style.id).set(style.toMap());
      } catch (e) {
        if (kDebugMode) print("Error adding style: $e");
        _mockStyles.add(style);
        await _saveMockStyles();
      }
    } else {
      _mockStyles.add(style);
      await _saveMockStyles();
    }
  }

  // --- Creations API ---
  Future<List<Creation>> getCreations() async {
    if (_isFirebaseInitialized) {
      try {
        final snapshot = await FirebaseFirestore.instance.collection('creations').orderBy('date', descending: true).get();
        return snapshot.docs.map((doc) => Creation.fromMap(doc.data())).toList();
      } catch (e) {
        if (kDebugMode) print("Error fetching creations: $e");
        return _mockCreations;
      }
    } else {
      // Sort mock by date desc
      _mockCreations.sort((a, b) => b.date.compareTo(a.date));
      return _mockCreations;
    }
  }

  Future<void> addCreation(Creation creation) async {
    if (_isFirebaseInitialized) {
      try {
        await FirebaseFirestore.instance.collection('creations').doc(creation.id).set(creation.toMap());
      } catch (e) {
        if (kDebugMode) print("Error adding creation: $e");
        _mockCreations.add(creation);
        await _saveMockCreations();
      }
    } else {
      _mockCreations.add(creation);
      await _saveMockCreations();
    }
  }
}
