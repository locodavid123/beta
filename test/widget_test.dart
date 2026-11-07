import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:beta/core/providers/app_state.dart';
import 'package:beta/core/models/coat_diagnosis.dart';
import 'package:beta/core/services/firebase_service.dart';
import 'package:beta/core/services/gemini_service.dart';
import 'package:beta/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App smoke test - verifies app initializes with Provider', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => AppStateProvider())],
        child: const MyApp(),
      ),
    );

    // Initial frame rendered
    await tester.pump();
    expect(find.byType(MyApp), findsOneWidget);
  });

  test('GeminiService accepts authentic Shih Tzu breed names', () {
    expect(GeminiService.isShihTzuBreed('Shih Tzu'), isTrue);
    expect(GeminiService.isShihTzuBreed('Shih Tzu Mix'), isTrue);
    expect(GeminiService.isShihTzuBreed('Bichón Maltés'), isTrue);
  });

  test('GeminiService rejects non-Shih Tzu breeds', () {
    expect(GeminiService.isShihTzuBreed('Golden Retriever'), isFalse);
    expect(GeminiService.isShihTzuBreed('Pug'), isFalse);
    expect(GeminiService.isShihTzuBreed('Labrador Retriever'), isFalse);
    expect(GeminiService.isShihTzuBreed('Humano'), isFalse);
  });

  test('only verified Shih Tzu results are eligible for simulation', () {
    final personPhoto = GeminiResult(
      isShihTzu: false,
      breed: 'Humano',
      message: 'La imagen parece mostrar una persona.',
    );
    final serviceFailure = GeminiResult(
      isShihTzu: true,
      breed: 'Shih Tzu',
      message: 'No se pudo verificar.',
      isServiceError: true,
    );

    expect(personPhoto.isVerifiedShihTzu, isFalse);
    expect(serviceFailure.isVerifiedShihTzu, isFalse);
    expect(
      GeminiResult(
        isShihTzu: true,
        breed: 'Shih Tzu',
        message: 'Verificado.',
      ).isVerifiedShihTzu,
      isTrue,
    );
  });

  test('CoatDiagnosisResult recognizes close Shih Tzu breed names', () {
    final shared = CoatDiagnosisResult.fromMap({
      'detectedBreed': 'Bichón Maltés',
      'overallScore': 86,
      'scoreLevel': 'Excelente',
      'tearStainStatus': 'Leve',
      'tearStainAdvice': 'Lavar suavemente',
      'eyeRiskStatus': 'Seguro',
      'eyeRiskAdvice': 'Mantener el flequillo limpio',
      'coatCondition': 'Sedoso',
      'mattingRisk': 'Bajo',
      'recommendedStyleId': 'corte_cachorro',
      'recommendedStyleName': 'Corte Cachorro',
      'recommendedStyleReason': 'Mantiene mejor la cara',
      'faceShape': 'Carita redonda',
      'keyObservations': ['Pelo suave'],
      'groomingActionPlan': ['Cepillar'],
      'groomerAdvice': 'Peinar con cuidado',
    });

    expect(shared.isShihTzu, isTrue);
  });

  test('signOut clears the current user name and role from storage', () async {
    SharedPreferences.setMockInitialValues({});

    final prefs = await SharedPreferences.getInstance();
    final service = FirebaseService();

    await service.signIn('cliente_prueba@email.com', 'password123');
    await service.signOut();

    expect(service.currentUserEmail, isNull);
    expect(service.currentUserName, 'Usuario');
    expect(prefs.getString('user_name'), isNull);
    expect(prefs.getString('user_role'), isNull);
  });

  test(
    'logoutUser resets session data so stale user state is not kept',
    () async {
      SharedPreferences.setMockInitialValues({});

      final state = AppStateProvider();
      await state.setUserCredits(12);
      await state.toggleFavoriteTutorial('t1');
      await state.toggleCompletedTutorial('t2');

      await state.logoutUser();

      expect(state.credits, 5);
      expect(state.userPhoto, isEmpty);
      expect(state.favoriteTutorialIds, isEmpty);
      expect(state.completedTutorialIds, isEmpty);
    },
  );
}
