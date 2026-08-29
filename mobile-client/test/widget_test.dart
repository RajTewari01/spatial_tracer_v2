import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spatial_tracer_mobile/main.dart';

void main() {
  testWidgets('App renders title', (WidgetTester tester) async {
    // Note: Camera tests require platform channels, so just verify rendering
    await tester.pumpWidget(const SpatialTracerApp(hasSeenOnboarding: true));
    // App should render without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
