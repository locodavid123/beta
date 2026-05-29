import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pet.dart';
import '../models/style.dart';
import '../models/creation.dart';
import '../models/tutorial.dart';
import '../models/report.dart';

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
  final List<Tutorial> _mockTutorials = [];
  final List<ModerationReport> _mockReports = [];
  
  // Active user details
  String? _currentUserEmail;
  String? _currentUserName;
  String _currentUserRole = 'client';

  String get currentUserRole => _currentUserRole;

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
    _currentUserRole = prefs.getString('user_role') ?? 'client';

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

    // Load tutorials
    final tutorialsJson = prefs.getStringList('mock_tutorials');
    if (tutorialsJson != null && tutorialsJson.isNotEmpty) {
      _mockTutorials.clear();
      for (var t in tutorialsJson) {
        _mockTutorials.add(Tutorial.fromMap(jsonDecode(t)));
      }
    } else {
      _mockTutorials.addAll(_getDefaultTutorials());
      await _saveMockTutorials();
    }

    // Load reports
    final reportsJson = prefs.getStringList('mock_reports');
    if (reportsJson != null) {
      _mockReports.clear();
      for (var r in reportsJson) {
        _mockReports.add(ModerationReport.fromMap(jsonDecode(r)));
      }
    } else {
      _mockReports.addAll(_getDefaultReports());
      await _saveMockReports();
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

  Future<void> _saveMockTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _mockTutorials.map((t) => jsonEncode(t.toMap())).toList();
    await prefs.setStringList('mock_tutorials', data);
  }

  Future<void> _saveMockReports() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _mockReports.map((r) => jsonEncode(r.toMap())).toList();
    await prefs.setStringList('mock_reports', data);
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
        status: 'activo',
        promptTemplate: 'A majestic royal portrait of a [breed] dog, wearing ancient Chinese imperial clothing with elaborate golden embroidery and a jewel-encrusted royal crown, luxurious background, highly detailed.',
        coatType: 'Pelo Largo',
        difficulty: 'Medio',
        uses: 234,
      ),
      ArtStyle(
        id: 'cosmico',
        name: 'Fantasía Cósmica',
        category: 'Fantasía',
        imagePath: 'assets/images/fantasia_cosmica.png',
        description: 'Tu mascota flotando en el espacio rodeado de galaxias, nebulosas y estrellas brillantes.',
        isHot: false,
        status: 'activo',
        promptTemplate: 'A cute [breed] dog floating in deep space, surrounded by beautiful colorful purple and blue nebulas, cosmic dust, and bright shining stars, cinematic lighting.',
        coatType: 'Ambos',
        difficulty: 'Medio',
        uses: 159,
      ),
      ArtStyle(
        id: 'cyberpunk',
        name: 'Cyberpunk Neon',
        category: 'Sci-Fi',
        imagePath: 'assets/images/cyberpunk_neon.png',
        description: 'Luces de neón intensas, lentes de sol tecnológicos y un ambiente urbano futurista.',
        isHot: true,
        status: 'activo',
        promptTemplate: 'A futuristic [breed] dog wearing high-tech glowing sunglasses, background of a neon-drenched cyberpunk city at night with pink and cyan light reflections.',
        coatType: 'Pelo Corto',
        difficulty: 'Medio',
        uses: 89,
      ),
      ArtStyle(
        id: 'acuarela',
        name: 'Acuarela Suave',
        category: 'Arte',
        imagePath: 'assets/images/acuarela_suave.png',
        description: 'Trazo suave con salpicaduras de colores y pintura artística de acuarela.',
        isHot: false,
        status: 'activo',
        promptTemplate: 'A soft artistic watercolor painting of a [breed] dog, with colorful paint splatters, delicate brushstrokes, pastel colors, white background.',
        coatType: 'Ambos',
        difficulty: 'Fácil',
        uses: 12,
      ),
      ArtStyle(
        id: 'steampunk',
        name: 'Steampunk',
        category: 'Steampunk',
        imagePath: 'assets/images/steampunk.png',
        description: 'Engranajes de bronce, tubos de vapor y accesorios antiguos del siglo XIX.',
        isHot: false,
        status: 'activo',
        promptTemplate: 'A handsome [breed] dog dressed in 19th-century steampunk attire, with brass goggles on forehead, surrounded by bronze gears, copper pipes, and steam.',
        coatType: 'Ambos',
        difficulty: 'Difícil',
        uses: 78,
      ),
      ArtStyle(
        id: 'kawaii',
        name: 'Kawaii Pastel',
        category: 'Cute',
        imagePath: 'assets/images/kawaii_pastel.png',
        description: 'Un estilo super tierno y animado con colores pastel rosas, corazones y destellos de felicidad.',
        isHot: true,
        status: 'borrador',
        promptTemplate: 'An extremely cute chibi-style cartoon [breed] dog, pastel pink background, surrounded by floating hearts, happy stars, and sparkles, anime aesthetic.',
        coatType: 'Ambos',
        difficulty: 'Fácil',
        uses: 0,
      ),
    ];
  }

  List<Tutorial> _getDefaultTutorials() {
    return [
      Tutorial(
        id: 't1',
        title: 'Corte Puppy Cut básico',
        duration: '12:45 min',
        difficulty: 'Fácil',
        views: 312,
        status: 'publicado',
      ),
      Tutorial(
        id: 't2',
        title: 'Cuidado y desembollo',
        duration: '08:20 min',
        difficulty: 'Medio',
        views: 287,
        status: 'publicado',
      ),
      Tutorial(
        id: 't3',
        title: 'Corte de uñas',
        duration: '05:10 min',
        difficulty: 'Fácil',
        views: 198,
        status: 'publicado',
      ),
      Tutorial(
        id: 't4',
        title: 'Limpieza de lagañas',
        duration: '06:15 min',
        difficulty: 'Fácil',
        views: 176,
        status: 'publicado',
      ),
      Tutorial(
        id: 't5',
        title: 'Baño completo',
        duration: '15:30 min',
        difficulty: 'Difícil',
        views: 142,
        status: 'publicado',
      ),
      Tutorial(
        id: 't6',
        title: 'Corte de pelo largo',
        duration: '24:00 min',
        difficulty: 'Difícil',
        views: 20,
        status: 'borrador',
      ),
    ];
  }

  List<ModerationReport> _getDefaultReports() {
    return [
      ModerationReport(
        id: 'r1',
        userEmail: 'maria.g@gmail.com',
        reason: 'Imagen inapropiada en simulación',
        creationId: 'c1',
        creationImagePath: 'assets/images/realeza_imperial.png',
        priority: 'Alta',
        date: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ModerationReport(
        id: 'r2',
        userEmail: 'carlos.p@gmail.com',
        reason: 'Error al compartir resultado',
        creationId: 'c2',
        creationImagePath: 'assets/images/fantasia_cosmica.png',
        priority: 'Media',
        date: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      ModerationReport(
        id: 'r3',
        userEmail: 'laura.m@gmail.com',
        reason: 'Prompt generó contenido inesperado',
        creationId: 'c3',
        creationImagePath: 'assets/images/cyberpunk_neon.png',
        priority: 'Alta',
        date: DateTime.now().subtract(const Duration(hours: 10)),
      ),
    ];
  }

  // --- Auth Service API ---
  Future<UserCredential?> signIn(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    if (_isFirebaseInitialized) {
      try {
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
        if (cred.user != null) {
          final doc = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();
          if (doc.exists) {
            _currentUserName = doc.data()?['name'] ?? 'Usuario';
            _currentUserRole = doc.data()?['role'] ?? 'client';
          } else {
            _currentUserName = cred.user!.email?.split('@').first ?? 'Usuario';
            _currentUserRole = 'client';
          }
          _currentUserEmail = cred.user!.email;
          await prefs.setString('user_email', _currentUserEmail!);
          await prefs.setString('user_name', _currentUserName!);
          await prefs.setString('user_role', _currentUserRole);
        }
        return cred;
      } catch (e) {
        rethrow;
      }
    } else {
      // Mock Auth
      if (email.isNotEmpty && password.length >= 6) {
        _currentUserEmail = email;
        if (email == 'root@email.com') {
          _currentUserRole = 'root';
          _currentUserName = 'Root Admin';
        } else if (email == 'admin@email.com') {
          _currentUserRole = 'admin';
          _currentUserName = 'Admin General';
        } else {
          _currentUserRole = 'client';
          _currentUserName = prefs.getString('user_name') ?? 'Valentina López';
        }
        await prefs.setString('user_email', email);
        await prefs.setString('user_name', _currentUserName!);
        await prefs.setString('user_role', _currentUserRole);
        return null;
      } else {
        throw Exception("Credenciales incorrectas (mínimo 6 caracteres en contraseña).");
      }
    }
  }

  Future<UserCredential?> signUp(String email, String password, String name) async {
    final prefs = await SharedPreferences.getInstance();
    if (_isFirebaseInitialized) {
      try {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        _currentUserRole = (email == 'root@email.com')
            ? 'root'
            : (email == 'admin@email.com')
                ? 'admin'
                : 'client';
        await FirebaseFirestore.instance.collection('users').doc(cred.user?.uid).set({
          'name': name,
          'email': email,
          'credits': 5,
          'role': _currentUserRole,
        });
        _currentUserEmail = email;
        _currentUserName = name;
        await prefs.setString('user_email', email);
        await prefs.setString('user_name', name);
        await prefs.setString('user_role', _currentUserRole);
        return cred;
      } catch (e) {
        rethrow;
      }
    } else {
      // Mock SignUp
      if (email.isNotEmpty && password.length >= 6) {
        _currentUserEmail = email;
        _currentUserName = name;
        _currentUserRole = (email == 'root@email.com')
            ? 'root'
            : (email == 'admin@email.com')
                ? 'admin'
                : 'client';
        await prefs.setString('user_email', email);
        await prefs.setString('user_name', name);
        await prefs.setString('user_role', _currentUserRole);
        return null;
      } else {
        throw Exception("Datos inválidos.");
      }
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    if (_isFirebaseInitialized) {
      await FirebaseAuth.instance.signOut();
    }
    _currentUserEmail = null;
    _currentUserRole = 'client';
    await prefs.remove('user_email');
    await prefs.remove('user_role');
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

  // --- Tutorials API ---
  Future<List<Tutorial>> getTutorials() async {
    if (_isFirebaseInitialized) {
      try {
        final snapshot = await FirebaseFirestore.instance.collection('tutorials').get();
        if (snapshot.docs.isEmpty) return _mockTutorials;
        return snapshot.docs.map((doc) => Tutorial.fromMap(doc.data())).toList();
      } catch (e) {
        return _mockTutorials;
      }
    } else {
      return _mockTutorials;
    }
  }

  Future<void> addTutorial(Tutorial tutorial) async {
    if (_isFirebaseInitialized) {
      try {
        await FirebaseFirestore.instance.collection('tutorials').doc(tutorial.id).set(tutorial.toMap());
      } catch (e) {
        _mockTutorials.add(tutorial);
        await _saveMockTutorials();
      }
    } else {
      _mockTutorials.add(tutorial);
      await _saveMockTutorials();
    }
  }

  Future<void> updateTutorial(Tutorial tutorial) async {
    if (_isFirebaseInitialized) {
      try {
        await FirebaseFirestore.instance.collection('tutorials').doc(tutorial.id).update(tutorial.toMap());
      } catch (e) {
        final idx = _mockTutorials.indexWhere((t) => t.id == tutorial.id);
        if (idx != -1) {
          _mockTutorials[idx] = tutorial;
          await _saveMockTutorials();
        }
      }
    } else {
      final idx = _mockTutorials.indexWhere((t) => t.id == tutorial.id);
      if (idx != -1) {
        _mockTutorials[idx] = tutorial;
        await _saveMockTutorials();
      }
    }
  }

  Future<void> deleteTutorial(String id) async {
    if (_isFirebaseInitialized) {
      try {
        await FirebaseFirestore.instance.collection('tutorials').doc(id).delete();
      } catch (e) {
        _mockTutorials.removeWhere((t) => t.id == id);
        await _saveMockTutorials();
      }
    } else {
      _mockTutorials.removeWhere((t) => t.id == id);
      await _saveMockTutorials();
    }
  }

  // --- Reports API ---
  Future<List<ModerationReport>> getReports() async {
    if (_isFirebaseInitialized) {
      try {
        final snapshot = await FirebaseFirestore.instance.collection('reports').get();
        if (snapshot.docs.isEmpty) return _mockReports;
        return snapshot.docs.map((doc) => ModerationReport.fromMap(doc.data())).toList();
      } catch (e) {
        return _mockReports;
      }
    } else {
      return _mockReports;
    }
  }

  Future<void> addReport(ModerationReport report) async {
    if (_isFirebaseInitialized) {
      try {
        await FirebaseFirestore.instance.collection('reports').doc(report.id).set(report.toMap());
      } catch (e) {
        _mockReports.add(report);
        await _saveMockReports();
      }
    } else {
      _mockReports.add(report);
      await _saveMockReports();
    }
  }

  Future<void> resolveReport(String id) async {
    if (_isFirebaseInitialized) {
      try {
        await FirebaseFirestore.instance.collection('reports').doc(id).update({'isResolved': 1});
      } catch (e) {
        final idx = _mockReports.indexWhere((r) => r.id == id);
        if (idx != -1) {
          final updated = ModerationReport(
            id: _mockReports[idx].id,
            userEmail: _mockReports[idx].userEmail,
            reason: _mockReports[idx].reason,
            creationId: _mockReports[idx].creationId,
            creationImagePath: _mockReports[idx].creationImagePath,
            priority: _mockReports[idx].priority,
            date: _mockReports[idx].date,
            isResolved: true,
          );
          _mockReports[idx] = updated;
          await _saveMockReports();
        }
      }
    } else {
      final idx = _mockReports.indexWhere((r) => r.id == id);
      if (idx != -1) {
        final updated = ModerationReport(
          id: _mockReports[idx].id,
          userEmail: _mockReports[idx].userEmail,
          reason: _mockReports[idx].reason,
          creationId: _mockReports[idx].creationId,
          creationImagePath: _mockReports[idx].creationImagePath,
          priority: _mockReports[idx].priority,
          date: _mockReports[idx].date,
          isResolved: true,
        );
        _mockReports[idx] = updated;
        await _saveMockReports();
      }
    }
  }

  // --- Style Update & Deletion ---
  Future<void> updateStyle(ArtStyle style) async {
    if (_isFirebaseInitialized) {
      try {
        await FirebaseFirestore.instance.collection('styles').doc(style.id).update(style.toMap());
      } catch (e) {
        final idx = _mockStyles.indexWhere((s) => s.id == style.id);
        if (idx != -1) {
          _mockStyles[idx] = style;
          await _saveMockStyles();
        }
      }
    } else {
      final idx = _mockStyles.indexWhere((s) => s.id == style.id);
      if (idx != -1) {
        _mockStyles[idx] = style;
        await _saveMockStyles();
      }
    }
  }

  Future<void> deleteStyle(String id) async {
    if (_isFirebaseInitialized) {
      try {
        await FirebaseFirestore.instance.collection('styles').doc(id).delete();
      } catch (e) {
        _mockStyles.removeWhere((s) => s.id == id);
        await _saveMockStyles();
      }
    } else {
      _mockStyles.removeWhere((s) => s.id == id);
      await _saveMockStyles();
    }
  }
}
