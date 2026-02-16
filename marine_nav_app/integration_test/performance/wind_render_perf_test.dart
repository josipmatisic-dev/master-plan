import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:marine_nav_app/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Wind render performance profiling', (WidgetTester tester) async {
    // Launch app
    app.main();
    await tester.pumpAndSettle();

    // Find the center of the screen to simulate map pan
    final center = tester.getCenter(find.byType(MaterialApp));

    debugPrint('Starting performance trace...');
    
    // Record performance timeline
    await binding.traceAction(
      () async {
        // Pan map up
        await tester.dragFrom(center, const Offset(0, -200));
        await tester.pump(); // frame
        await Future.delayed(const Duration(milliseconds: 100)); // allow settle
        
        // Pan map down
        await tester.dragFrom(center, const Offset(0, 200));
        await tester.pump();
        await Future.delayed(const Duration(milliseconds: 100));

        // Pan map left
        await tester.dragFrom(center, const Offset(-200, 0));
        await tester.pump();
        await Future.delayed(const Duration(milliseconds: 100));

        // Pan map right
        await tester.dragFrom(center, const Offset(200, 0));
        await tester.pump();
        await Future.delayed(const Duration(milliseconds: 100));
      },
      reportKey: 'wind_scrolling_timeline',
    );

    debugPrint('Performance trace completed.');
  });
}
