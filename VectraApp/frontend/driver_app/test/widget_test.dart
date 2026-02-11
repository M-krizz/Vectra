import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vectra/main.dart';

void main() {
  testWidgets('Vectra app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: VectraApp()));

    // Verify that the app loads with VECTRA branding
    await tester.pumpAndSettle();
    expect(find.text('VECTRA'), findsOneWidget);
  });
}
