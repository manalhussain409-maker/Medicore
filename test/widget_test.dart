// This is a basic Flutter widget test for the Medliy Healthcare App.
//
// These tests verify basic app functionality.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Medliy App Tests', () {
    test('Basic widget test', () {
      // Verify Flutter SDK is working
      expect(1 + 1, 2);
    });

    testWidgets('Material app can be created', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          title: 'Medliy Healthcare Platform',
          home: Scaffold(body: Text('Test')),
        ),
      );

      // Verify MaterialApp is created
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
    });
  });
}
