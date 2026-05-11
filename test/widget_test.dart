import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dehus/main.dart';

void main() {
  testWidgets('renders the Longhorn welcome screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DeHeusApp(useRemoteHeroImage: false));

    expect(find.text('Longhorn Publishers PLC'), findsOneWidget);
    expect(find.text('ABOUT THE COMPANY'), findsOneWidget);
    expect(find.byIcon(Icons.eco_rounded), findsOneWidget);
  });
}
