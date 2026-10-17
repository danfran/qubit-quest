import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quantumquiz/screens/web_app.dart';
import 'package:quantumquiz/storage/app_storage.dart';

void main() {
  for (final width in [1440.0, 390.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets(
          'metadata version is contained in navigation at $width / $scale',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 800);
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final version = scale == 1 ? '2.4.0' : '9.8.7';
        final build = scale == 1 ? '33' : '654';
        // Deliberately different values prove the release label is not hardcoded.
        PackageInfo.setMockInitialValues(
            appName: 'Qubit Quest',
            packageName: 'quantumquiz',
            version: version,
            buildNumber: build,
            buildSignature: '');
        await tester
            .pumpWidget(QubitQuestWebApp(storage: InMemoryAppStorage()));
        await tester.pumpAndSettle();
        if (width < 900) {
          await tester.tap(find.byKey(const ValueKey('web-navigation-menu')));
          await tester.pumpAndSettle();
        }
        await tester.ensureVisible(find.byKey(const ValueKey('web-nav-bloch')));
        await tester.pumpAndSettle();
        final label = find.byKey(const ValueKey('web-navigation-version'));
        expect(find.text('Web v$version · Build $build'), findsOneWidget);
        final navigation = find.byKey(ValueKey(
            width < 900 ? 'web-navigation-drawer' : 'web-navigation-sidebar'));
        expect(
            find.descendant(of: navigation, matching: label), findsOneWidget);
        final rect = tester.getRect(label);
        final bounds = tester.getRect(navigation);
        expect(rect.left, greaterThanOrEqualTo(bounds.left));
        expect(rect.right, lessThanOrEqualTo(bounds.right));
        expect(rect.bottom, lessThanOrEqualTo(bounds.bottom));
        expect(
            rect.top,
            greaterThan(tester
                .getRect(find.byKey(const ValueKey('web-nav-bloch')))
                .bottom));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
