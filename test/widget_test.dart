import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:account_flow/main.dart';
import 'package:account_flow/launcher/launcher_screen.dart';
import 'package:account_flow/features/account_flow/screens/splash_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize FFI for desktop/test environments
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('Launcher renders tool cards', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(home: LauncherScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Toolbox'), findsOneWidget);
    expect(find.text('Account Flow'), findsOneWidget);
    expect(find.text('Converters'), findsOneWidget);
    expect(find.text('Video Player'), findsOneWidget);
    expect(find.text('Coming Soon'), findsOneWidget);
  });

  testWidgets('Splash screen renders and advances to Launcher',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(home: SplashScreen()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Toolbox'), findsOneWidget);

    // Advance past the 3-second splash timer and animations
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.byType(LauncherScreen), findsOneWidget);
  });
}
