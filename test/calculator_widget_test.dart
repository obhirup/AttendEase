import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attend_pulse/models/calculator_config.dart';
import 'package:attend_pulse/providers/calculator_provider.dart';
import 'package:attend_pulse/screens/calculator_screen.dart';
import 'package:attend_pulse/services/storage_service.dart';
import 'package:attend_pulse/theme/claude_theme.dart';
import 'package:attend_pulse/widgets/calculator_keypad.dart';

void main() {
  late StorageService storageService;
  late CalculatorProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = StorageService(prefs);
    provider = CalculatorProvider(storageService);
  });

  Widget buildTestApp() {
    return ChangeNotifierProvider<CalculatorProvider>.value(
      value: provider,
      child: Consumer<CalculatorProvider>(
        builder: (_, prov, __) {
          return MaterialApp(
            theme: ClaudeTheme.light(prov.activeColor),
            darkTheme: ClaudeTheme.dark(prov.activeColor),
            themeMode: prov.themeMode,
            home: const CalculatorScreen(),
          );
        },
      ),
    );
  }

  void setupMobileScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets('CalculatorScreen renders with 12-digit display, selectors, and keypad', (tester) async {
    setupMobileScreen(tester);
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Verify model title
    expect(find.text('Casio MJ-120D'), findsWidgets);

    // Verify 12-digit display
    expect(find.text('12-DIGIT'), findsOneWidget);
    expect(find.text('0'), findsWidgets); // initial display value

    // Verify selectors
    expect(find.text('ROUNDING'), findsOneWidget);
    expect(find.text('DECIMAL'), findsOneWidget);
    expect(find.text('5/4'), findsOneWidget);
    expect(find.text('F'), findsOneWidget);

    // Verify MJ-120D keys
    expect(find.text('TAX+'), findsOneWidget);
    expect(find.text('TAX-'), findsOneWidget);
    expect(find.text('MU'), findsOneWidget);
    expect(find.text('GT'), findsOneWidget);
    expect(find.text('MRC'), findsOneWidget);
    expect(find.text('AUTO'), findsOneWidget);
    expect(find.text('CORRECT'), findsOneWidget);
  });

  testWidgets('Switching model from MJ-120D to MJ-12D swaps keypad to omit TAX keys', (tester) async {
    setupMobileScreen(tester);
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Initially MJ-120D with TAX keys
    expect(find.text('TAX+'), findsOneWidget);
    expect(find.text('TAX-'), findsOneWidget);

    // Switch model to MJ-12D
    provider.switchModel(CalculatorModel.mj12d);
    await tester.pumpAndSettle();

    // Verify MJ-12D is active
    expect(find.text('Casio MJ-12D'), findsWidgets);

    // Verify TAX keys are omitted on MJ-12D
    expect(find.text('TAX+'), findsNothing);
    expect(find.text('TAX-'), findsNothing);

    // But MU, GT, MRC, 150-step keys remain!
    expect(find.text('MU'), findsOneWidget);
    expect(find.text('GT'), findsOneWidget);
    expect(find.text('MRC'), findsOneWidget);
    expect(find.text('AUTO'), findsOneWidget);
  });

  testWidgets('Keypad arithmetic calculation updates LCD display', (tester) async {
    setupMobileScreen(tester);
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Tap 2 + 3 =
    Finder keypadKey(String label) => find.descendant(
          of: find.byType(CalculatorKeypad),
          matching: find.text(label),
        );

    await tester.tap(keypadKey('2'));
    await tester.pump();
    await tester.tap(keypadKey('+'));
    await tester.pump();
    await tester.tap(keypadKey('3'));
    await tester.pump();
    await tester.tap(keypadKey('='));
    await tester.pumpAndSettle();

    expect(find.text('5'), findsWidgets);
    expect(find.text('2 STEPS'), findsOneWidget);
  });

  testWidgets('Audit Tape bottom sheet opens and displays recorded steps', (tester) async {
    setupMobileScreen(tester);
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    Finder keypadKey(String label) => find.descendant(
          of: find.byType(CalculatorKeypad),
          matching: find.text(label),
        );

    // Tap 10 + 20 =
    await tester.tap(keypadKey('1'));
    await tester.pump();
    await tester.tap(keypadKey('0'));
    await tester.pump();
    await tester.tap(keypadKey('+'));
    await tester.pump();
    await tester.tap(keypadKey('2'));
    await tester.pump();
    await tester.tap(keypadKey('0'));
    await tester.pump();
    await tester.tap(keypadKey('='));
    await tester.pumpAndSettle();

    // Tap step pill or audit tape icon in AppBar
    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await tester.pumpAndSettle();

    expect(find.text('150-Step Audit Tape'), findsOneWidget);
    expect(find.text('#01'), findsOneWidget);
  });
}
