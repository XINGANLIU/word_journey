import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:word_journey/main.dart';

void main() {
  testWidgets('renders app shell', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const WordJourneyApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
