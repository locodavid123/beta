import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:beta/core/providers/app_state.dart';
import 'package:beta/main.dart';

void main() {
  testWidgets('App smoke test - verifies app initializes with Provider', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Initial frame rendered
    await tester.pump();
    expect(find.byType(MyApp), findsOneWidget);
  });
}
