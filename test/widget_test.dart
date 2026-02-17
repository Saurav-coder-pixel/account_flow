import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:account_flow/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('App starts and shows splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // The first screen should be the SplashScreen, which shows a CircularProgressIndicator.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
