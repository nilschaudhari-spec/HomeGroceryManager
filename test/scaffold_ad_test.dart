import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Verify banner ad bottom bar dimensions in Scaffold', (tester) async {
    const double bannerWidth = 320.0;
    const double bannerHeight = 50.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const Center(child: Text('Main Pantry Screen')),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              height: bannerHeight + 8,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                ),
              ),
              alignment: Alignment.center,
              child: SizedBox(
                width: bannerWidth,
                height: bannerHeight,
                child: Container(color: Colors.green),
              ),
            ),
          ),
        ),
      ),
    );

    final scaffold = tester.getSize(find.byType(Scaffold));
    final bottomNav = tester.getSize(find.byType(SafeArea));

    // BottomNav must only occupy bannerHeight + padding (58px), NOT the full screen (600px)!
    expect(bottomNav.height, bannerHeight + 8);
    expect(scaffold.height, 600.0);

    // Body content must still be visible and not blocked
    expect(find.text('Main Pantry Screen'), findsOneWidget);
  });
}
