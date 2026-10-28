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
  String? _currentUserPhoto;

  String get currentUserRole => _currentUserRole;
  String get currentUserPhoto => _currentUserPhoto ?? '';

  // Initialize service
  Future<void> init() async {
    // ALWAYS load local cache/storage first so fallback data is immediately available
    await _loadLocalMockData();

    try {
      // Try to initialize Firebase
      await Firebase.initializeApp();
      _isFirebaseInitialized = true;
      if (kDebugMode) {
        print("Firebase initialized successfully.");
      }
      
      // Load initial dynamic styles in Firestore if empty
      await _seedStylesInFirestore();
      // Load initial tutorials in Firestore if empty and ensure YouTube URLs are up-to-date
      await _seedTutorialsInFirestore();
    } catch (e) {
      _isFirebaseInitialized = false;
      if (kDebugMode) {
        print("Firebase initialization failed/skipped: $e. Falling back to local storage.");
      }
    }
  }

  // Seed initial styles in Firestore
  Future<void> _seedStylesInFirestore() async {
    if (!_isFirebaseInitialized) return;
    try {
      final stylesColl = FirebaseFirestore.instance.collection('styles');
      
      // Clean up the deprecated/deleted styles from Firestore database
      final idsToRemove = {'realeza', 'cosmico', 'cyberpunk', 'acuarela', 'steampunk', 'kawaii'};
      for (var id in idsToRemove) {
        await stylesColl.doc(id).delete();
      }

      // Load/Seed default styles if not already present or update metadata
      for (var s in _getDefaultStyles()) {
        final doc = await stylesColl.doc(s.id).get();
        if (!doc.exists) {
          await stylesColl.doc(s.id).set(s.toMap());
        } else {
          final data = doc.data();
          if (data != null && (data['tutorialId'] != s.tutorialId || data['videoUrl'] != s.videoUrl || data['name'] != s.name)) {
            await stylesColl.doc(s.id).update({
              'tutorialId': s.tutorialId,
              'videoUrl': s.videoUrl,
              'name': s.name,
              'category': s.category,
            });
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error seeding/migrating styles in Firestore: $e");
      }
    }
  }

  // Seed initial tutorials in Firestore and ensure videoUrls are updated
  Future<void> _seedTutorialsInFirestore() async {
    if (!_isFirebaseInitialized) return;
    try {
      final tutsColl = FirebaseFirestore.instance.collection('tutorials');
      final defaultTuts = _getDefaultTutorials();
      for (var t in defaultTuts) {
        final doc = await tutsColl.doc(t.id).get();
        if (!doc.exists) {
          await tutsColl.doc(t.id).set(t.toMap());
        } else {
          // If already exists, verify if videoUrl needs updating
          final data = doc.data();
          if (data != null && t.videoUrl.isNotEmpty) {
            final currentVideo = data['videoUrl']?.toString() ?? '';
            if (currentVideo != t.videoUrl) {
              await tutsColl.doc(t.id).update({
                'videoUrl': t.videoUrl,
                'tools': t.tools,
                'steps': t.steps,
                'status': 'publicado',
              });
            }
          }
        }
      }
      if (kDebugMode) {
        print("Tutorials seeded/synchronized in Firestore successfully.");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error seeding tutorials in Firestore: $e");
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
    _currentUserPhoto = prefs.getString('user_photo') ?? '';

    // Load styles
    final stylesJson = prefs.getStringList('mock_styles');
    if (stylesJson != null && stylesJson.isNotEmpty) {
      _mockStyles.clear();
      for (var s in stylesJson) {
        _mockStyles.add(ArtStyle.fromMap(jsonDecode(s)));
      }
      // Explicitly remove the deprecated/deleted default concept styles
      final idsToRemove = {'realeza', 'cosmico', 'cyberpunk', 'acuarela', 'steampunk', 'kawaii'};
      _mockStyles.removeWhere((s) => idsToRemove.contains(s.id));

      // Add and update official styles with tutorial links
      final defaultStyles = _getDefaultStyles();
      for (var def in defaultStyles) {
        final idx = _mockStyles.indexWhere((s) => s.id == def.id);
        if (idx == -1) {
          _mockStyles.add(def);
        } else {
          _mockStyles[idx] = def;
        }
      }
      final order = ['corte_cachorro', 'corte_oso', 'corte_topknot', 'corte_leon', 'corte_exhibicion'];
      _mockStyles.sort((a, b) {
        int idxA = order.indexOf(a.id);
        int idxB = order.indexOf(b.id);
        if (idxA == -1) idxA = 999;
        if (idxB == -1) idxB = 999;
        return idxA.compareTo(idxB);
      });
      await _saveMockStyles();
    } else {
      _mockStyles.clear();
      _mockStyles.addAll(_getDefaultStyles());
      await _saveMockStyles();
    }

    // Load pets
    final petsJson = prefs.getStringList('mock_pets');
    if (petsJson != null && petsJson.isNotEmpty) {
      _mockPets.clear();
      for (var p in petsJson) {
        final pet = Pet.fromMap(jsonDecode(p));
        if (!_mockPets.any((existing) => existing.id == pet.id)) {
          _mockPets.add(pet);
        }
      }
    } else {
      _mockPets.clear();
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
          userEmail: 'cliente_prueba@email.com',
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
          userEmail: 'cliente_prueba@email.com',
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
          styleId: 'corte_cachorro',
          styleName: 'Corte Cachorro (Puppy Cut)',
          imagePath: 'assets/images/corte_cachorro.png',
          originalImagePath: 'assets/images/luna_shih_tzu.png',
          date: DateTime.now().subtract(const Duration(hours: 3)),
          likes: 24,
          description: 'Luna luciendo un hermoso y práctico corte cachorro de 2 pulgadas, muy cómoda y fresca.',
        ),
        Creation(
          id: 'c2',
          petId: 'max',
          petName: 'Max',
          styleId: 'corte_oso',
          styleName: 'Corte Oso de Peluche',
          imagePath: 'assets/images/corte_oso.png',
          originalImagePath: 'assets/images/max_shih_tzu.png',
          date: DateTime.now().subtract(const Duration(days: 1)),
          likes: 11,
          description: 'Max con su corte oso de peluche, su cabeza se ve muy redonda y tierna.',
        ),
        Creation(
          id: 'c3',
          petId: 'luna',
          petName: 'Luna',
          styleId: 'corte_leon',
          styleName: 'Corte de León',
          imagePath: 'assets/images/corte_leon.png',
          originalImagePath: 'assets/images/luna_shih_tzu.png',
          date: DateTime.now().subtract(const Duration(days: 5)),
          likes: 8,
          description: 'Luna con un majestuoso corte de león, una melena abundante y cuerpo recortado.',
        ),
        Creation(
          id: 'c4',
          petId: 'luna',
          petName: 'Luna',
          styleId: 'corte_topknot',
          styleName: 'Corte Top Knot',
          imagePath: 'assets/images/corte_topknot.png',
          originalImagePath: 'assets/images/luna_shih_tzu.png',
          date: DateTime.now().subtract(const Duration(days: 8)),
          likes: 17,
          description: 'Luna con su clásico top knot recogido con un lazo rojo elegante.',
        ),
      ]);
      await _saveMockCreations();
    }

    // Load tutorials
    final tutorialsJson = prefs.getStringList('mock_tutorials_v4');
    if (tutorialsJson != null && tutorialsJson.isNotEmpty) {
      _mockTutorials.clear();
      for (var t in tutorialsJson) {
        _mockTutorials.add(Tutorial.fromMap(jsonDecode(t)));
      }
      // Update any default tutorials that received new videoUrls
      final defs = _getDefaultTutorials();
      bool updated = false;
      for (var def in defs) {
        final idx = _mockTutorials.indexWhere((t) => t.id == def.id);
        if (idx != -1) {
          if (def.videoUrl.isNotEmpty && _mockTutorials[idx].videoUrl != def.videoUrl) {
            _mockTutorials[idx] = def;
            updated = true;
          }
        } else {
          _mockTutorials.add(def);
          updated = true;
        }
      }
      if (updated) {
        await _saveMockTutorials();
      }
    } else {
      _mockTutorials.clear();
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
    await prefs.setStringList('mock_tutorials_v4', data);
  }

  Future<void> _saveMockReports() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _mockReports.map((r) => jsonEncode(r.toMap())).toList();
    await prefs.setStringList('mock_reports', data);
  }

  List<ArtStyle> _getDefaultStyles() {
    return [
      ArtStyle(
        id: 'corte_cachorro',
        name: 'Corte Cachorro (Puppy Cut)',
        category: 'Clásico',
        imagePath: 'assets/images/corte_cachorro.png',
        description: 'Un corte práctico y uniforme de 1 a 2 pulgadas en todo el cuerpo, ideal para climas cálidos y fácil mantenimiento.',
        isHot: true,
        status: 'activo',
        promptTemplate: 'A professional portrait of a [breed] dog with a fresh puppy cut, showcasing short, even coat all over the body, neat round head, looking happy, studio lighting.',
        coatType: 'Pelo Corto',
        difficulty: 'Fácil',
        uses: 340,
        tutorialId: 't1',
        videoUrl: 'https://youtu.be/f5oRAy-WARA',
      ),
      ArtStyle(
        id: 'corte_oso',
        name: 'Corte Oso de Peluche (Teddy Bear)',
        category: 'Cute',
        imagePath: 'assets/images/corte_oso.png',
        description: 'Cuerpo recortado a longitud media y cabeza redondeada y esponjosa, dándole la apariencia tierna de un osito.',
        isHot: true,
        status: 'activo',
        promptTemplate: 'A beautiful [breed] dog styled in a teddy bear cut, featuring a rounded fluffy head shape, neatly trimmed body, cute expressive eyes, soft pastel background.',
        coatType: 'Ambos',
        difficulty: 'Medio',
        uses: 289,
        tutorialId: 't_oso',
        videoUrl: 'https://youtu.be/toHlRfTARaQ',
      ),
      ArtStyle(
        id: 'corte_topknot',
        name: 'Corte Moño Superior (Top Knot)',
        category: 'Cute',
        imagePath: 'assets/images/corte_topknot.png',
        description: 'El pelo de la cabeza se recoge elegantemente en una coleta o moño, sujetado con un lazo, mientras el cuerpo puede ir corto o largo.',
        isHot: false,
        status: 'activo',
        promptTemplate: 'A cute [breed] dog with head hair gathered in a neat top knot ponytail adorned with a colorful ribbon, bright happy expression, high quality grooming.',
        coatType: 'Pelo Largo',
        difficulty: 'Medio',
        uses: 180,
        tutorialId: 't6',
        videoUrl: 'https://youtu.be/wRnLLl3VDRE',
      ),
      ArtStyle(
        id: 'corte_leon',
        name: 'Corte de León (Lion Cut)',
        category: 'Fantasía',
        imagePath: 'assets/images/corte_leon.png',
        description: 'Cuerpo y patas recortados muy cortos, dejando una melena abundante y majestuosa alrededor del cuello y la cabeza.',
        isHot: false,
        status: 'activo',
        promptTemplate: 'A majestic [breed] dog groomed with a lion cut, showing a neatly shaved body and limbs with a full, fluffy lion-like mane around its head and neck, looking proud.',
        coatType: 'Pelo Largo',
        difficulty: 'Difícil',
        uses: 120,
        tutorialId: 't_leon',
        videoUrl: 'https://youtu.be/65nmhuunf7k',
      ),
      ArtStyle(
        id: 'corte_exhibicion',
        name: 'Manto Largo Tradicional de Exhibición',
        category: 'Clásico',
        imagePath: 'assets/images/corte_exhibicion.png',
        description: 'El pelaje largo y sedoso tradicional que llega hasta el suelo, requiriendo cepillado diario y cuidado premium.',
        isHot: false,
        status: 'activo',
        promptTemplate: 'A show-quality [breed] dog with a gorgeous, long flowing silky coat reaching the ground, head hair gathered in a classic topknot with a red ribbon bow.',
        coatType: 'Pelo Largo',
        difficulty: 'Difícil',
        uses: 95,
        tutorialId: 't_exhibicion',
        videoUrl: 'https://youtu.be/tx8xQy0PYWY',
      ),
    ];
  }

  List<Tutorial> _getDefaultTutorials() {
    return [
      Tutorial(
        id: 't1',
        title: 'Corte Puppy Cut para Shih Tzu',
        duration: '12:45 min',
        difficulty: 'Fácil',
        category: 'Cortes',
        views: 342,
        status: 'publicado',
        videoUrl: 'https://youtu.be/f5oRAy-WARA',
        tools: [
          'Tijera recta de 7 pulgadas',
          'Tijera curva para patitas',
          'Peine metálico de púas anchas',
          'Máquina con alza #4 (9.5mm)',
        ],
        steps: [
          'Bañar y secar completamente estirando el manto con cepillo de mantequilla.',
          'Pasar la máquina con alza #4 en lomo y costados a favor del crecimiento del pelo.',
          'Redondear las patitas con tijera curva creando columnas rectas y limpias.',
          'Perfilar la carita redonda con tijera de entresacar manteniendo la forma de peluche.',
        ],
      ),
      Tutorial(
        id: 't2',
        title: 'Desenredo de nudos difíciles sin tirones',
        duration: '08:20 min',
        difficulty: 'Medio',
        category: 'Cepillado',
        views: 418,
        status: 'publicado',
        tools: [
          'Cepillo de mantequilla (sin bolitas en la punta)',
          'Spray desenredante bifásico protector',
          'Peine metálico tipo peine de manteca',
          'Cortanudos de seguridad de 9 hojas',
        ],
        steps: [
          'Rociar generosamente el spray desenredante sobre el nudo; jamás cepillar en seco.',
          'Abrir el nudo suavemente con los dedos desde el centro hacia afuera.',
          'Con la punta del cepillo de mantequilla, desenredar de puntas hacia la raíz poco a poco.',
          'Si el nudo es muy compacto, realizar una incisión vertical con el cortanudos y abrir.',
          'Pasar el peine metálico para confirmar que no queden nudos cerca de la piel.',
        ],
      ),
      Tutorial(
        id: 't3',
        title: 'Limpieza y cuidado de lagrimales',
        duration: '06:15 min',
        difficulty: 'Fácil',
        category: 'Higiene',
        views: 295,
        status: 'publicado',
        tools: [
          'Suero fisiológico estéril o limpiador de lágrimas',
          'Gasa suave de algodón (no gasa hilachosa)',
          'Peine fino para lagrimal / pulgas',
          'Polvo secante antimicrobiano para pliegues faciales',
        ],
        steps: [
          'Humedecer una gasa estéril con el suero fisiológico templado.',
          'Limpiar desde el lagrimal hacia abajo con movimientos suaves y descendentes.',
          'Con el peine fino, retirar los restos de lagañas ya ablandadas con sumo cuidado.',
          'Secar profundamente la zona con papel tissue para evitar humedad bacteriana.',
          'Aplicar una mínima pizca de polvo secante en el pliegue nasal.',
        ],
      ),
      Tutorial(
        id: 't4',
        title: 'Corte de uñas seguro sin dolor',
        duration: '05:10 min',
        difficulty: 'Fácil',
        category: 'Higiene',
        views: 220,
        status: 'publicado',
        tools: [
          'Cortauñas tipo alicate para razas pequeñas',
          'Polvo cicatrizante hemostático',
          'Lima de uñas metálica o electrónica para mascotas',
          'Snacks de recompensa positiva',
        ],
        steps: [
          'Sujetar la patita con firmeza pero con calma, despejando los pelos interdigitales.',
          'Identificar el vaso sanguíneo; en uñas oscuras cortar solo 1-2 mm de la punta.',
          'Colocar el cortauñas a 45 grados y realizar un corte firme y decidido.',
          'Limar las asperezas para que no se enganche en alfombras o telas.',
          'Premiar inmediatamente a tu perrito tras cada uña cortada.',
        ],
      ),
      Tutorial(
        id: 't5',
        title: 'Baño hidratante y secado anti-dermatitis',
        duration: '15:30 min',
        difficulty: 'Medio',
        category: 'Baño',
        views: 184,
        status: 'publicado',
        tools: [
          'Shampoo hidratante con aceite de argán o avena',
          'Mascarilla nutritiva desenredante',
          'Toalla de microfibra súper absorbente',
          'Secador profesional con boquilla plana (temperatura tibia)',
        ],
        steps: [
          'Cepillar minuciosamente a tu Shih Tzu antes de mojarlo para evitar apelmazar nudos.',
          'Mojar con agua tibia y aplicar el shampoo diluido con esponja sin frotar en círculos.',
          'Aplicar mascarilla hidratante en las puntas dejando actuar 3 minutos y enjuagar al 100%.',
          'Escurrir con toalla de microfibra a toques, sin estrujar el pelo.',
          'Secar de abajo hacia arriba estirando el manto con el cepillo hasta que esté 100% seco en raíz.',
        ],
      ),
      Tutorial(
        id: 't6',
        title: 'Corte Moño Superior (Top Knot) con lazo',
        duration: '09:40 min',
        difficulty: 'Medio',
        category: 'Cortes',
        views: 260,
        status: 'publicado',
        videoUrl: 'https://youtu.be/wRnLLl3VDRE',
        tools: [
          'Peine de cola de ratón de acero',
          'Bandas elásticas de látex especiales sin rotura',
          'Lazo o lazo doble decorativo para exposición',
        ],
        steps: [
          'Trazar una línea recta desde la esquina exterior de cada ojo hacia la coronilla.',
          'Recoger el pelo frontal verificando que los ojos queden libres y sin tensión.',
          'Colocar la gomita elástica con 2 a 3 vueltas suaves.',
          'Con la punta del peine, aflojar ligeramente el centro para darle volumen y libertad de parpadeo.',
          'Colocar el lazo decorativo sobre la banda elástica.',
        ],
      ),
      Tutorial(
        id: 't_oso',
        title: 'Corte Oso de Peluche (Teddy Bear Cut)',
        duration: '14:15 min',
        difficulty: 'Medio',
        category: 'Cortes',
        views: 310,
        status: 'publicado',
        videoUrl: 'https://youtu.be/toHlRfTARaQ',
        tools: [
          'Tijera recta de 7.5 pulgadas',
          'Tijera de esculpir (dientes anchos)',
          'Peine metálico tipo peine de manteca',
          'Carda suave sin bolas de protección',
        ],
        steps: [
          'Bañar y secar con soplador levantando la raíz para dar volumen tipo algodón.',
          'Rebajar el manto del cuerpo a tijera a una longitud uniforme de 2 a 3 centímetros.',
          'Redondear la cabeza con tijera de esculpir esculpiendo una esfera suave y tierna.',
          'Perfilar las orejas en curva alineándolas a la base de la mandíbula inferior.',
          'Dar forma tubular y redondeada a las 4 patitas para el efecto patas de oso.',
        ],
      ),
      Tutorial(
        id: 't_leon',
        title: 'Corte Estilo León Majestuoso',
        duration: '16:50 min',
        difficulty: 'Difícil',
        category: 'Cortes',
        views: 195,
        status: 'publicado',
        videoUrl: 'https://youtu.be/65nmhuunf7k',
        tools: [
          'Máquina profesional con cuchilla #10 o #7F',
          'Tijera recta microdentada',
          'Tijera curva de 6.5 pulgadas',
          'Spray abrillantador con silicona ligera',
        ],
        steps: [
          'Marcar la línea de la melena detrás de las escápulas y alrededor del pecho.',
          'Pasar la máquina en el lomo, grupa y flancos a favor del pelo con la cuchilla elegida.',
          'Rasurar los muslos y antebrazos dejando brazaletes o polainas sobre los corvejones.',
          'Esquilar la base de la cola y recortar un pompón esférico en el tercio final.',
          'Peinar la melena hacia adelante y emparejar las puntas en forma circular imitando un león.',
        ],
      ),
      Tutorial(
        id: 't_exhibicion',
        title: 'Manto Largo Tradicional de Exhibición',
        duration: '18:20 min',
        difficulty: 'Difícil',
        category: 'Cortes',
        views: 145,
        status: 'publicado',
        videoUrl: 'https://youtu.be/tx8xQy0PYWY',
        tools: [
          'Cepillo de púas metálicas sin bolitas (Pin brush)',
          'Peine metálico con espina de latón',
          'Mascarilla nutritiva con extracto de seda',
          'Plancha térmica para peluquería canina a baja temperatura',
        ],
        steps: [
          'Aplicar baño con mascarilla de caída pesada y no frotar el manto para no quebrar las puntas.',
          'Secar estirando hacia abajo con el secador direccionado en ángulo descendente.',
          'Trazar una raya central perfecta en la columna desde la cruz hasta la base de la cola.',
          'Planchar suavemente mechón por mechón con protector térmico para alisar la caída.',
          'Perfilar a tijera las puntas que tocan el suelo para una línea limpia al caminar.',
        ],
      ),
    ];
  }

  List<ModerationReport> _getDefaultReports() {
    return [
      ModerationReport(
        id: 'r1',
        userEmail: 'maria.g@gmail.com',
        reason: 'Imagen inapropiada en simulación',
        creationId: 'c3',
        creationImagePath: 'assets/images/corte_leon.png',
        priority: 'Alta',
        date: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ModerationReport(
        id: 'r2',
        userEmail: 'carlos.p@gmail.com',
        reason: 'Error al compartir resultado',
        creationId: 'c2',
        creationImagePath: 'assets/images/corte_oso.png',
        priority: 'Media',
        date: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      ModerationReport(
        id: 'r3',
        userEmail: 'laura.m@gmail.com',
        reason: 'Prompt generó contenido inesperado',
        creationId: 'c4',
        creationImagePath: 'assets/images/corte_topknot.png',
        priority: 'Alta',
        date: DateTime.now().subtract(const Duration(hours: 10)),
      ),
    ];
  }

  // --- Auth Service API ---
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
            _currentUserPhoto = doc.data()?['photoUrl'] ?? '';
          } else {
            _currentUserName = cred.user!.displayName ?? 'Usuario';
            _currentUserRole = (email.toLowerCase().contains('root'))
                ? 'root'
                : (email.toLowerCase().contains('admin'))
                    ? 'admin'
                    : 'client';
            _currentUserPhoto = '';
            try {
              await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
                'name': _currentUserName,
                'email': email,
                'credits': _currentUserRole == 'client' ? 5 : 999,
                'role': _currentUserRole,
                'photoUrl': '',
              });
            } catch (_) {}
          }
          _currentUserEmail = cred.user!.email;
          await prefs.setString('user_email', _currentUserEmail!);
          await prefs.setString('user_name', _currentUserName!);
          await prefs.setString('user_role', _currentUserRole);
          await prefs.setString('user_photo', _currentUserPhoto!);
        }
        return cred;
      } catch (e) {
        // Fallback to local authentication for built-in accounts (root, admin, test users)
        // or if Firebase Auth doesn't have the user registered yet in the cloud
        try {
          return await _signInLocal(email, password, prefs);
        } catch (_) {
          rethrow;
        }
      }
    } else {
      return await _signInLocal(email, password, prefs);
    }
  }

  Future<UserCredential?> _signInLocal(String email, String password, SharedPreferences prefs) async {
    final usersJson = prefs.getString('mock_users');
    List<dynamic> users = [];
    if (usersJson != null) {
      users = jsonDecode(usersJson);
    } else {
      users = [];
    }

    // Always guarantee built-in accounts are present and up to date
    final defaultUsers = [
      {"email": "admin@email.com", "password": "password123", "name": "Admin General", "role": "admin", "credits": 999},
      {"email": "root@email.com", "password": "password123", "name": "Root Admin", "role": "root", "credits": 999},
      {"email": "admin@myapp.com", "password": "password123", "name": "Admin General", "role": "admin", "credits": 999},
      {"email": "root@myapp.com", "password": "password123", "name": "Root Admin", "role": "root", "credits": 999},
      {"email": "cliente_prueba@email.com", "password": "password123", "name": "Valentina López", "role": "client", "credits": 5},
      {"email": "valentina@email.com", "password": "password123", "name": "Valentina López", "role": "client", "credits": 5},
    ];

    for (var def in defaultUsers) {
      final existingIndex = users.indexWhere((u) => u['email'].toString().toLowerCase() == def['email'].toString().toLowerCase());
      if (existingIndex == -1) {
        users.add(def);
      } else {
        users[existingIndex]['password'] = def['password'];
        users[existingIndex]['role'] = def['role'];
      }
    }
    await prefs.setString('mock_users', jsonEncode(users));

    final normalizedEmail = email.trim().toLowerCase();
    final userIndex = users.indexWhere((u) => u['email'].toString().toLowerCase() == normalizedEmail);
    if (userIndex == -1) {
      throw Exception("El usuario no está registrado en la base de datos.");
    }

    final user = users[userIndex];
    if (user['password'] != password) {
      throw Exception("Contraseña incorrecta.");
    }

    _currentUserEmail = user['email'];
    _currentUserName = user['name'];
    _currentUserRole = user['role'];
    _currentUserPhoto = user['photoUrl'] ?? '';

    await prefs.setString('user_email', _currentUserEmail!);
    await prefs.setString('user_name', _currentUserName!);
    await prefs.setString('user_role', _currentUserRole);
    await prefs.setString('user_photo', _currentUserPhoto!);
    await prefs.setInt('user_credits', user['credits'] ?? 5);
    return null;
  }

  Future<UserCredential?> signUp(String email, String password, String name) async {
    final prefs = await SharedPreferences.getInstance();
    if (_isFirebaseInitialized) {
      try {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        _currentUserRole = (email == 'root@email.com' || email == 'root@myapp.com')
            ? 'root'
            : (email == 'admin@email.com' || email == 'admin@myapp.com')
                ? 'admin'
                : 'client';
        try {
          await FirebaseFirestore.instance.collection('users').doc(cred.user?.uid).set({
            'name': name,
            'email': email,
            'credits': 5,
            'role': _currentUserRole,
            'photoUrl': '',
          });
        } catch (_) {}
        _currentUserEmail = email;
        _currentUserName = name;
        _currentUserPhoto = '';
        await prefs.setString('user_email', email);
        await prefs.setString('user_name', name);
        await prefs.setString('user_role', _currentUserRole);
        await prefs.setString('user_photo', '');
        return cred;
      } catch (e) {
        return await _signUpLocal(email, password, name, prefs);
      }
    } else {
      return await _signUpLocal(email, password, name, prefs);
    }
  }

  Future<UserCredential?> _signUpLocal(String email, String password, String name, SharedPreferences prefs) async {
    if (email.isNotEmpty && password.length >= 6) {
      final usersJson = prefs.getString('mock_users');
      List<dynamic> users = [];
      if (usersJson != null) {
        users = jsonDecode(usersJson);
      } else {
        users = [];
      }

      final normalizedEmail = email.trim().toLowerCase();
      if (users.any((u) => u['email'].toString().toLowerCase() == normalizedEmail)) {
        throw Exception("El correo ya está registrado.");
      }

      _currentUserRole = (email == 'root@email.com' || email == 'root@myapp.com')
          ? 'root'
          : (email == 'admin@email.com' || email == 'admin@myapp.com')
              ? 'admin'
              : 'client';

      users.add({
        "email": email,
        "password": password,
        "name": name,
        "role": _currentUserRole,
        "credits": 5,
        "photoUrl": ""
      });

      await prefs.setString('mock_users', jsonEncode(users));

      _currentUserEmail = email;
      _currentUserName = name;
      _currentUserPhoto = '';
      await prefs.setString('user_email', email);
      await prefs.setString('user_name', name);
      await prefs.setString('user_role', _currentUserRole);
      await prefs.setString('user_photo', '');
      await prefs.setInt('user_credits', 5);
      return null;
    } else {
      throw Exception("Datos inválidos.");
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    if (_isFirebaseInitialized) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    _currentUserEmail = null;
    _currentUserRole = 'client';
    _currentUserPhoto = null;
    await prefs.remove('user_email');
    await prefs.remove('user_role');
    await prefs.remove('user_photo');
  }

  String? get currentUserEmail => FirebaseAuth.instance.currentUser?.email ?? _currentUserEmail;
  String get currentUserName => _currentUserName ?? 'Usuario';

  // --- Pets API ---
  Future<List<Pet>> getPets() async {
    final email = currentUserEmail?.trim().toLowerCase() ?? '';
    if (_isFirebaseInitialized) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('pets')
            .where('userEmail', isEqualTo: email)
            .get();
        final list = snapshot.docs.map((doc) => Pet.fromMap(doc.data())).toList();
        return list.isNotEmpty ? list : _mockPets;
      } catch (e) {
        if (kDebugMode) print("Error fetching pets: $e");
        return _mockPets;
      }
    } else {
      if (email.isEmpty || email == 'invitado@correo.com' || _currentUserRole == 'root' || _currentUserRole == 'admin') {
        return _mockPets;
      }
      final userPets = _mockPets.where((p) => p.userEmail.toLowerCase() == email).toList();
      return userPets.isNotEmpty ? userPets : _mockPets;
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

  Future<void> updatePet(Pet pet) async {
    if (_isFirebaseInitialized) {
      try {
        await FirebaseFirestore.instance.collection('pets').doc(pet.id).update(pet.toMap());
      } catch (e) {
        if (kDebugMode) print("Error updating pet: $e");
        final idx = _mockPets.indexWhere((p) => p.id == pet.id);
        if (idx != -1) {
          _mockPets[idx] = pet;
          await _saveMockPets();
        }
      }
    } else {
      final idx = _mockPets.indexWhere((p) => p.id == pet.id);
      if (idx != -1) {
        _mockPets[idx] = pet;
        await _saveMockPets();
      }
    }
  }

  Future<void> deletePet(String id) async {
    if (_isFirebaseInitialized) {
      try {
        await FirebaseFirestore.instance.collection('pets').doc(id).delete();
      } catch (e) {
        if (kDebugMode) print("Error deleting pet: $e");
        _mockPets.removeWhere((p) => p.id == id);
        await _saveMockPets();
      }
    } else {
      _mockPets.removeWhere((p) => p.id == id);
      await _saveMockPets();
    }
  }

  // --- Styles API (Dynamic Catalogue) ---
  Future<List<ArtStyle>> getStyles() async {
    if (_mockStyles.isEmpty) {
      _mockStyles.addAll(_getDefaultStyles());
    }
    final order = ['corte_cachorro', 'corte_oso', 'corte_topknot', 'corte_leon', 'corte_exhibicion'];
    if (_isFirebaseInitialized) {
      try {
        final snapshot = await FirebaseFirestore.instance.collection('styles').get();
        if (snapshot.docs.isEmpty) {
          return List<ArtStyle>.from(_mockStyles);
        }
        final list = snapshot.docs.map((doc) => ArtStyle.fromMap(doc.data())).toList();
        final idsToRemove = {'realeza', 'cosmico', 'cyberpunk', 'acuarela', 'steampunk', 'kawaii'};
        list.removeWhere((s) => idsToRemove.contains(s.id));

        // Merge official tutorial links and sort
        final defs = _getDefaultStyles();
        for (var def in defs) {
          final idx = list.indexWhere((s) => s.id == def.id);
          if (idx == -1) {
            list.add(def);
          } else if (list[idx].tutorialId.isEmpty || list[idx].videoUrl.isEmpty) {
            list[idx] = def;
          }
        }
        list.sort((a, b) {
          int idxA = order.indexOf(a.id);
          int idxB = order.indexOf(b.id);
          if (idxA == -1) idxA = 999;
          if (idxB == -1) idxB = 999;
          return idxA.compareTo(idxB);
        });
        return list;
      } catch (e) {
        if (kDebugMode) print("Error fetching styles: $e");
        return List<ArtStyle>.from(_mockStyles);
      }
    } else {
      return List<ArtStyle>.from(_mockStyles);
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
        final list = snapshot.docs.map((doc) => Creation.fromMap(doc.data())).toList();
        return list.isNotEmpty ? list : List<Creation>.from(_mockCreations);
      } catch (e) {
        if (kDebugMode) print("Error fetching creations: $e");
        return List<Creation>.from(_mockCreations);
      }
    } else {
      // Sort mock by date desc
      _mockCreations.sort((a, b) => b.date.compareTo(a.date));
      return List<Creation>.from(_mockCreations);
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
    // 1. Guarantee memory has default tutorials if empty
    if (_mockTutorials.isEmpty) {
      _mockTutorials.addAll(_getDefaultTutorials());
    }

    if (_isFirebaseInitialized) {
      try {
        final snapshot = await FirebaseFirestore.instance.collection('tutorials').get();
        if (snapshot.docs.isEmpty) {
          // If Firestore is empty, start seeding and return populated local tutorials
          _seedTutorialsInFirestore();
          return List<Tutorial>.from(_mockTutorials);
        }
        
        final list = snapshot.docs.map((doc) => Tutorial.fromMap(doc.data())).toList();
        
        // Ensure that all official default tutorials (including their YouTube links)
        // are present and accurate, merging if any are missing or have outdated links
        final defs = _getDefaultTutorials();
        for (var def in defs) {
          final idx = list.indexWhere((t) => t.id == def.id);
          if (idx == -1) {
            list.add(def);
          } else if (def.videoUrl.isNotEmpty && (list[idx].videoUrl.isEmpty || list[idx].videoUrl != def.videoUrl)) {
            list[idx] = list[idx].copyWith(videoUrl: def.videoUrl);
          }
        }
        return list;
      } catch (e) {
        if (kDebugMode) print("Error fetching tutorials from Firestore: $e");
        return List<Tutorial>.from(_mockTutorials.isNotEmpty ? _mockTutorials : _getDefaultTutorials());
      }
    } else {
      return List<Tutorial>.from(_mockTutorials.isNotEmpty ? _mockTutorials : _getDefaultTutorials());
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
    if (_mockReports.isEmpty) {
      _mockReports.addAll(_getDefaultReports());
    }
    if (_isFirebaseInitialized) {
      try {
        final snapshot = await FirebaseFirestore.instance.collection('reports').get();
        if (snapshot.docs.isEmpty) return List<ModerationReport>.from(_mockReports);
        final list = snapshot.docs.map((doc) => ModerationReport.fromMap(doc.data())).toList();
        return list.isNotEmpty ? list : List<ModerationReport>.from(_mockReports);
      } catch (e) {
        return List<ModerationReport>.from(_mockReports);
      }
    } else {
      return List<ModerationReport>.from(_mockReports);
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

  Future<void> updateProfile({required String name, required String photoPath}) async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserName = name;
    _currentUserPhoto = photoPath;
    await prefs.setString('user_name', name);
    await prefs.setString('user_photo', photoPath);

    if (_isFirebaseInitialized) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await user.updateDisplayName(name);
          await user.updatePhotoURL(photoPath);
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'name': name,
            'photoUrl': photoPath,
          });
        } catch (e) {
          if (kDebugMode) print("Error updating Firebase profile: $e");
        }
      }
    } else {
      // Mock db update
      final usersJson = prefs.getString('mock_users');
      if (usersJson != null) {
        try {
          List<dynamic> users = jsonDecode(usersJson);
          final normalizedEmail = currentUserEmail?.trim().toLowerCase();
          final idx = users.indexWhere((u) => u['email'].toString().toLowerCase() == normalizedEmail);
          if (idx != -1) {
            users[idx]['name'] = name;
            users[idx]['photoUrl'] = photoPath;
            await prefs.setString('mock_users', jsonEncode(users));
          }
        } catch (e) {
          if (kDebugMode) print("Error updating mock profile: $e");
        }
      }
    }
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    if (_isFirebaseInitialized) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        try {
          AuthCredential credential = EmailAuthProvider.credential(
            email: user.email!,
            password: currentPassword,
          );
          await user.reauthenticateWithCredential(credential);
          await user.updatePassword(newPassword);
        } catch (e) {
          throw Exception("Error al cambiar contraseña en Firebase: $e");
        }
      } else {
        throw Exception("No hay usuario autenticado.");
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('mock_users');
      if (usersJson != null) {
        List<dynamic> users = jsonDecode(usersJson);
        final normalizedEmail = currentUserEmail?.trim().toLowerCase();
        final idx = users.indexWhere((u) => u['email'].toString().toLowerCase() == normalizedEmail);
        if (idx != -1) {
          final storedPassword = users[idx]['password'];
          if (storedPassword != currentPassword) {
            throw Exception("La contraseña actual es incorrecta.");
          }
          users[idx]['password'] = newPassword;
          await prefs.setString('mock_users', jsonEncode(users));
        } else {
          throw Exception("Usuario no encontrado en la base de datos.");
        }
      } else {
        throw Exception("Base de datos no inicializada.");
      }
    }
  }
}
