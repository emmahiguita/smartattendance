// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartattendance/main.dart';
import 'package:smartattendance/core/network/dio_provider.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  final mockDio = MockDio();

  testWidgets('App structural smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioProvider.overrideWithValue(mockDio),
        ],
        child: const SmartAttendanceApp(),
      ),
    );

    // Advance the clock to exhaust the SplashScreen's timer
    // and wait for any other initialization timers to complete.
    await tester.pumpAndSettle(const Duration(seconds: 10));

    // Verify that the app mounts and builds successfully.
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(SmartAttendanceApp), findsOneWidget);
  });
}
