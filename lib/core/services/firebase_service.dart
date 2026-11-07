import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pet.dart';
import '../models/style.dart';
import '../models/creation.dart';
import '../models/tutorial.dart';
import '../models/report.dart';
import '../../firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _isFirebaseInitialized = false;
  bool get isFirebaseInitialized => _isFirebaseInitialized;

  // Active user details
  String? _currentUserName;
  String _currentUserRole = 'client';
  String? _currentUserPhoto;

  String get currentUserRole => _currentUserRole;
  String get currentUserPhoto => _currentUserPhoto ?? '';

  // Initialize service
  Future<void> init() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: kIsWeb ? DefaultFirebaseOptions.web : null,
        );
      }
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
      _isFirebaseInitialized = true;

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _loadCurrentUserProfile(user);
      }
    } catch (e) {
      _isFirebaseInitialized = false;
      rethrow;
    }
  }

  void _requireFirebase() {
    if (!_isFirebaseInitialized) {
      throw StateError(
        'Firebase no está inicializado. No se guardaron cambios.',
      );
    }
  }

  Future<void> _loadCurrentUserProfile(User user) async {
    _currentUserName = user.displayName ?? user.email?.split('@').first;
    _currentUserRole = 'client';
    _currentUserPhoto = user.photoURL;

    final users = FirebaseFirestore.instance.collection('users');
    final profileReference = users.doc(user.uid);
    var snapshot = await profileReference.get(
      const GetOptions(source: Source.server),
    );
    if (!snapshot.exists) {
      final newProfile = {
        'uid': user.uid,
        'email': user.email?.toLowerCase() ?? '',
        'name': _currentUserName ?? 'Usuario',
        'role': 'client',
        'credits': 5,
        'photoUrl': user.photoURL ?? '',
        'isDarkMode': false,
        'language': 'Español',
        'pushNotifications': true,
        'emailNotifications': false,
        'imageQuality': 'Alta (más lento)',
        'favoriteTutorialIds': <String>[],
        'completedTutorialIds': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      };
      await profileReference.set(newProfile);
      snapshot = await profileReference.get(
        const GetOptions(source: Source.server),
      );
    }
    final data = snapshot.data()!;
    if (data['disabled'] == true) {
      await FirebaseAuth.instance.signOut();
      _currentUserName = null;
      _currentUserRole = 'client';
      _currentUserPhoto = null;
      throw StateError('Esta cuenta fue desactivada.');
    }
    _currentUserName = data['name']?.toString() ?? _currentUserName;
    _currentUserRole = data['role']?.toString() ?? 'client';
    _currentUserPhoto = data['photoUrl']?.toString() ?? _currentUserPhoto;
  }

  String? get currentUserEmail => FirebaseAuth.instance.currentUser?.email;

  String get currentUserName => _currentUserName ?? 'Usuario';

  DocumentReference<Map<String, dynamic>> get _currentProfileReference {
    _requireFirebase();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Inicia sesión para continuar.');
    return FirebaseFirestore.instance.collection('users').doc(user.uid);
  }

  Future<Map<String, dynamic>> getCurrentUserProfile() async {
    final snapshot = await _currentProfileReference.get(
      const GetOptions(source: Source.server),
    );
    final data = snapshot.data();
    if (data == null) {
      throw StateError('No se encontró el perfil del usuario en Firestore.');
    }
    return data;
  }

  Future<void> updateCurrentUserFields(Map<String, dynamic> fields) async {
    if (fields.containsKey('credits') &&
        _currentUserRole != 'admin' &&
        _currentUserRole != 'root') {
      final currentProfile = await getCurrentUserProfile();
      final currentCredits = (currentProfile['credits'] as num?)?.toInt() ?? 0;
      final requestedCredits = (fields['credits'] as num?)?.toInt() ?? 0;
      if (requestedCredits > currentCredits) {
        throw StateError(
          'Los créditos solo pueden asignarse desde administración.',
        );
      }
    }
    await _currentProfileReference.set(fields, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> getSystemSettings() async {
    _requireFirebase();
    final snapshot = await FirebaseFirestore.instance
        .collection('system')
        .doc('settings')
        .get(const GetOptions(source: Source.server));
    return snapshot.data() ?? {};
  }

  Stream<Map<String, dynamic>> watchSystemSettings() {
    _requireFirebase();
    return FirebaseFirestore.instance
        .collection('system')
        .doc('settings')
        .snapshots()
        .map((snapshot) => snapshot.data() ?? const <String, dynamic>{});
  }

  Future<void> updateSystemSetting(String key, bool value) async {
    _requireFirebase();
    if (_currentUserRole != 'root') {
      throw StateError('Solo root puede cambiar la configuración global.');
    }
    if (key != 'publicRegistration' && key != 'maintenanceMode') {
      throw ArgumentError.value(key, 'key', 'Configuración desconocida.');
    }
    await FirebaseFirestore.instance.collection('system').doc('settings').set({
      key: value,
    }, SetOptions(merge: true));
  }

  Future<int> getCurrentUserCredits() async {
    if (FirebaseAuth.instance.currentUser == null) return 0;
    final profile = await getCurrentUserProfile();
    return (profile['credits'] as num?)?.toInt() ?? 0;
  }

  Future<List<String>> getCurrentUserList(String field) async {
    if (FirebaseAuth.instance.currentUser == null) return [];
    final profile = await getCurrentUserProfile();
    return List<String>.from(profile[field] ?? const <String>[]);
  }

  Future<void> toggleCurrentUserListValue(String field, String value) async {
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final reference = _currentProfileReference;
      final snapshot = await transaction.get(reference);
      final profile = snapshot.data();
      if (profile == null) {
        throw StateError('No se encontró el perfil del usuario en Firestore.');
      }
      final values = List<String>.from(profile[field] ?? const <String>[]);
      if (values.contains(value)) {
        values.remove(value);
      } else {
        values.add(value);
      }
      transaction.set(reference, {field: values}, SetOptions(merge: true));
    });
  }

  Future<UserCredential?> signIn(String email, String password) async {
    _requireFirebase();
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    final user = credential.user;
    if (user == null) throw StateError('Firebase Auth no devolvió un usuario.');
    await _loadCurrentUserProfile(user);
    final settings = await getSystemSettings();
    if (settings['maintenanceMode'] == true &&
        _currentUserRole != 'admin' &&
        _currentUserRole != 'root') {
      await signOut();
      throw StateError(
        'La aplicación está en mantenimiento. Inténtalo más tarde.',
      );
    }
    return credential;
  }

  Future<UserCredential?> signUp(
    String email,
    String password,
    String name,
  ) async {
    _requireFirebase();
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();
    final settings = await getSystemSettings();
    if (settings['publicRegistration'] == false) {
      throw StateError('El registro público está desactivado.');
    }
    if (settings['maintenanceMode'] == true) {
      throw StateError(
        'La aplicación está en mantenimiento. Inténtalo más tarde.',
      );
    }
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: cleanEmail, password: password);
    final user = credential.user;
    if (user == null) throw StateError('Firebase Auth no devolvió un usuario.');
    await user.updateDisplayName(cleanName);
    final profile = {
      'uid': user.uid,
      'email': cleanEmail,
      'name': cleanName,
      'role': 'client',
      'credits': 5,
      'photoUrl': '',
      'isDarkMode': false,
      'language': 'Español',
      'pushNotifications': true,
      'emailNotifications': false,
      'imageQuality': 'Alta (más lento)',
      'favoriteTutorialIds': <String>[],
      'completedTutorialIds': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    };
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(profile);
    await _loadCurrentUserProfile(user);
    return credential;
  }

  Future<void> signOut() async {
    _requireFirebase();
    await FirebaseAuth.instance.signOut();
    _currentUserName = null;
    _currentUserRole = 'client';
    _currentUserPhoto = null;
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    _requireFirebase();
    if (_currentUserRole != 'admin' && _currentUserRole != 'root') {
      throw StateError('Solo un administrador puede consultar usuarios.');
    }
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .get(const GetOptions(source: Source.server));
    return snapshot.docs
        .where((document) {
          return document.data()['disabled'] != true;
        })
        .map((document) {
          return {'uid': document.id, ...document.data()};
        })
        .toList();
  }

  Future<void> updateUserInDatabase(
    String email,
    String newRole,
    int newCredits, [
    String? newName,
  ]) async {
    _requireFirebase();
    if (_currentUserRole != 'admin' && _currentUserRole != 'root') {
      throw StateError('Solo un administrador puede actualizar usuarios.');
    }
    if (!{'client', 'admin', 'root'}.contains(newRole)) {
      throw ArgumentError.value(newRole, 'newRole', 'Rol inválido.');
    }
    if (newCredits < 0) {
      throw ArgumentError.value(
        newCredits,
        'newCredits',
        'No puede ser negativo.',
      );
    }
    if (newRole == 'root' && _currentUserRole != 'root') {
      throw StateError('Solo root puede asignar el rol root.');
    }
    if (_currentUserRole == 'admin' && newRole != 'client') {
      throw StateError(
        'Los administradores solo pueden asignar el rol cliente.',
      );
    }
    final results = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .get(const GetOptions(source: Source.server));
    if (results.docs.isEmpty) throw StateError('Usuario no encontrado.');
    for (final document in results.docs) {
      if (_currentUserRole == 'admin' && document.data()['role'] != 'client') {
        throw StateError('Los administradores solo pueden modificar clientes.');
      }
      await document.reference.update({
        'role': newRole,
        'credits': newCredits,
        if (newName != null && newName.isNotEmpty) 'name': newName,
      });
      if (document.id == FirebaseAuth.instance.currentUser?.uid) {
        _currentUserRole = newRole;
        if (newName != null && newName.isNotEmpty) {
          _currentUserName = newName;
        }
      }
    }
  }

  Future<void> addUserToDatabase(
    String name,
    String email,
    String role,
    int credits, [
    String password = '',
  ]) async {
    _requireFirebase();
    if (_currentUserRole != 'admin' && _currentUserRole != 'root') {
      throw StateError('Solo un administrador puede crear usuarios.');
    }
    if (role == 'root' && _currentUserRole != 'root') {
      throw StateError('Solo root puede crear otra cuenta root.');
    }
    if (_currentUserRole == 'admin' && role != 'client') {
      throw StateError(
        'Los administradores solo pueden crear cuentas cliente.',
      );
    }
    if (password.length < 6) {
      throw ArgumentError('La contraseña debe tener al menos 6 caracteres.');
    }
    if (credits < 0) {
      throw ArgumentError.value(credits, 'credits', 'No puede ser negativo.');
    }

    final secondaryApp = await Firebase.initializeApp(
      name: 'user-provision-${DateTime.now().microsecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
    User? createdUser;
    try {
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      createdUser = credential.user;
      if (createdUser == null) {
        throw StateError('Firebase Auth no devolvió el usuario creado.');
      }
      await createdUser.updateDisplayName(name.trim());
      await FirebaseFirestore.instance
          .collection('users')
          .doc(createdUser.uid)
          .set({
            'uid': createdUser.uid,
            'name': name.trim(),
            'email': email.trim().toLowerCase(),
            'role': role,
            'credits': credits,
            'photoUrl': '',
            'favoriteTutorialIds': <String>[],
            'completedTutorialIds': <String>[],
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
          });
    } catch (error) {
      if (createdUser != null) {
        await createdUser.delete();
      }
      rethrow;
    } finally {
      await secondaryApp.delete();
    }
  }

  Future<void> deactivateUserInDatabase(String email) async {
    _requireFirebase();
    if (_currentUserRole != 'admin' && _currentUserRole != 'root') {
      throw StateError('Solo un administrador puede desactivar usuarios.');
    }
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final users = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .get(const GetOptions(source: Source.server));
    if (users.docs.isEmpty) {
      throw StateError('Usuario no encontrado.');
    }
    for (final document in users.docs) {
      if (document.id == currentUid) {
        throw StateError('No puedes desactivar tu propia cuenta.');
      }
      if (_currentUserRole == 'admin' && document.data()['role'] != 'client') {
        throw StateError(
          'Los administradores solo pueden desactivar clientes.',
        );
      }
      await document.reference.update({
        'disabled': true,
        'disabledAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<List<Pet>> getPets() async {
    _requireFirebase();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
      'pets',
    );
    if (_currentUserRole != 'admin' && _currentUserRole != 'root') {
      query = query.where('userEmail', isEqualTo: user.email?.toLowerCase());
    }
    final snapshot = await query.get(const GetOptions(source: Source.server));
    return snapshot.docs.map((doc) => Pet.fromMap(doc.data())).toList();
  }

  Future<void> addPet(Pet pet) async {
    _requireFirebase();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Inicia sesión para guardar mascotas.');
    final petData = pet.toMap()
      ..['ownerUid'] = user.uid
      ..['userEmail'] = user.email?.toLowerCase() ?? '';
    await FirebaseFirestore.instance
        .collection('pets')
        .doc(pet.id)
        .set(petData);
  }

  Future<void> updatePet(Pet pet) async {
    _requireFirebase();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Inicia sesión para actualizar mascotas.');
    }
    await FirebaseFirestore.instance.collection('pets').doc(pet.id).update({
      ...pet.toMap(),
      'ownerUid': user.uid,
      'userEmail': user.email?.toLowerCase() ?? '',
    });
  }

  Future<void> deletePet(String id) async {
    _requireFirebase();
    await FirebaseFirestore.instance.collection('pets').doc(id).delete();
  }

  Future<List<ArtStyle>> getStyles() async {
    _requireFirebase();
    final snapshot = await FirebaseFirestore.instance
        .collection('styles')
        .get(const GetOptions(source: Source.server));
    final styles = snapshot.docs
        .map((document) => ArtStyle.fromMap(document.data()))
        .where(
          (style) =>
              _currentUserRole == 'admin' ||
              _currentUserRole == 'root' ||
              style.status == 'activo',
        )
        .toList();
    const order = [
      'corte_cachorro',
      'corte_oso',
      'corte_topknot',
      'corte_leon',
      'corte_exhibicion',
    ];
    styles.sort((a, b) {
      final aIndex = order.indexOf(a.id);
      final bIndex = order.indexOf(b.id);
      return (aIndex < 0 ? order.length : aIndex).compareTo(
        bIndex < 0 ? order.length : bIndex,
      );
    });
    return styles;
  }

  Future<void> addStyle(ArtStyle style) async {
    _requireFirebase();
    await FirebaseFirestore.instance
        .collection('styles')
        .doc(style.id)
        .set(style.toMap());
  }

  Future<void> updateStyle(ArtStyle style) async {
    _requireFirebase();
    await FirebaseFirestore.instance
        .collection('styles')
        .doc(style.id)
        .update(style.toMap());
  }

  Future<void> deleteStyle(String id) async {
    _requireFirebase();
    await FirebaseFirestore.instance.collection('styles').doc(id).delete();
  }

  Future<List<Creation>> getCreations() async {
    _requireFirebase();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
      'creations',
    );
    if (_currentUserRole != 'admin' && _currentUserRole != 'root') {
      query = query.where('ownerUid', isEqualTo: user.uid);
    }
    final snapshot = await query.get(const GetOptions(source: Source.server));
    final creations =
        snapshot.docs
            .map((document) => Creation.fromMap(document.data()))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return creations;
  }

  Future<void> addCreation(Creation creation) async {
    _requireFirebase();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Inicia sesión para guardar resultados.');
    }
    await FirebaseFirestore.instance
        .collection('creations')
        .doc(creation.id)
        .set({
          ...creation.toMap(),
          'ownerUid': user.uid,
          'userEmail': user.email?.toLowerCase() ?? '',
        });
  }

  Future<int> addCreationAndConsumeCredit(Creation creation) async {
    _requireFirebase();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Inicia sesión para continuar.');
    final firestore = FirebaseFirestore.instance;
    final userReference = firestore.collection('users').doc(user.uid);
    final creationReference = firestore
        .collection('creations')
        .doc(creation.id);
    return firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userReference);
      final userData = userSnapshot.data();
      if (userData == null) {
        throw StateError('No se encontró el perfil del usuario en Firestore.');
      }
      final credits = (userData['credits'] as num?)?.toInt() ?? 0;
      if (credits <= 0) {
        throw StateError(
          'Créditos insuficientes. Visita tu perfil para obtener más.',
        );
      }
      transaction.set(userReference, {
        'credits': credits - 1,
      }, SetOptions(merge: true));
      transaction.set(creationReference, {
        ...creation.toMap(),
        'ownerUid': user.uid,
        'userEmail': user.email?.toLowerCase() ?? '',
      });
      return credits - 1;
    });
  }

  Future<void> clearCurrentUserCreations() async {
    _requireFirebase();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Inicia sesión para continuar.');
    final snapshot = await FirebaseFirestore.instance
        .collection('creations')
        .where('ownerUid', isEqualTo: user.uid)
        .get(const GetOptions(source: Source.server));
    for (var offset = 0; offset < snapshot.docs.length; offset += 400) {
      final batch = FirebaseFirestore.instance.batch();
      for (final document in snapshot.docs.skip(offset).take(400)) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }
  }

  Future<List<Tutorial>> getTutorials() async {
    _requireFirebase();
    final snapshot = await FirebaseFirestore.instance
        .collection('tutorials')
        .get(const GetOptions(source: Source.server));
    return snapshot.docs
        .map((document) => Tutorial.fromMap(document.data()))
        .where(
          (tutorial) =>
              _currentUserRole == 'admin' ||
              _currentUserRole == 'root' ||
              tutorial.status == 'publicado',
        )
        .toList();
  }

  Future<void> addTutorial(Tutorial tutorial) async {
    _requireFirebase();
    await FirebaseFirestore.instance
        .collection('tutorials')
        .doc(tutorial.id)
        .set(tutorial.toMap());
  }

  Future<void> updateTutorial(Tutorial tutorial) async {
    _requireFirebase();
    await FirebaseFirestore.instance
        .collection('tutorials')
        .doc(tutorial.id)
        .update(tutorial.toMap());
  }

  Future<void> deleteTutorial(String id) async {
    _requireFirebase();
    await FirebaseFirestore.instance.collection('tutorials').doc(id).delete();
  }

  Future<List<ModerationReport>> getReports() async {
    _requireFirebase();
    if (_currentUserRole != 'admin' && _currentUserRole != 'root') return [];
    final snapshot = await FirebaseFirestore.instance
        .collection('reports')
        .get(const GetOptions(source: Source.server));
    return snapshot.docs
        .map((document) => ModerationReport.fromMap(document.data()))
        .toList();
  }

  Future<void> addReport(ModerationReport report) async {
    _requireFirebase();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Inicia sesión para enviar un reporte.');
    await FirebaseFirestore.instance.collection('reports').doc(report.id).set({
      ...report.toMap(),
      'ownerUid': user.uid,
      'userEmail': user.email?.toLowerCase() ?? '',
    });
  }

  Future<void> resolveReport(String id) async {
    _requireFirebase();
    if (_currentUserRole != 'admin' && _currentUserRole != 'root') {
      throw StateError('Solo un administrador puede resolver reportes.');
    }
    await FirebaseFirestore.instance.collection('reports').doc(id).update({
      'isResolved': true,
    });
  }

  Future<void> updateProfile({
    required String name,
    required String photoPath,
  }) async {
    _requireFirebase();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Inicia sesión para editar tu perfil.');
    await user.updateDisplayName(name);
    await user.updatePhotoURL(photoPath.isEmpty ? null : photoPath);
    await _currentProfileReference.set({
      'name': name.trim(),
      'photoUrl': photoPath,
    }, SetOptions(merge: true));
    _currentUserName = name.trim();
    _currentUserPhoto = photoPath;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _requireFirebase();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      throw StateError('No hay usuario autenticado.');
    }
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }
}
