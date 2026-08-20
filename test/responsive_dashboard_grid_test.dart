import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/widgets/responsive_dashboard_grid.dart';

void main() {
  const actionKeys = [
    Key('continue'),
    Key('map'),
    Key('bloch'),
    Key('sandbox'),
  ];

  Future<void> pumpGrid(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 700);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: ResponsiveDashboardGrid(
            minimumTileWidth: 250,
            maxColumns: 4,
            mainAxisExtent: 94,
            spacing: 14,
            children: [
              for (final key in actionKeys)
                ColoredBox(key: key, color: Colors.blue),
            ],
          ),
        ),
      ),
    ));
  }

  testWidgets('tablet landscape uses four equal cards across full width',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpGrid(tester, 1180);
    final widths =
        actionKeys.map((key) => tester.getSize(find.byKey(key)).width).toList();
    expect(widths.toSet().length, 1);
    expect(widths.first, closeTo((1180 - 3 * 14) / 4, .01));
    expect(
        tester.getTopRight(find.byKey(actionKeys.last)).dx, closeTo(1180, .01));
    expect(
        find.byKey(const ValueKey('dashboard-grid-4-columns')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('landscape phone uses a balanced two by two grid',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpGrid(tester, 760);
    expect(
        find.byKey(const ValueKey('dashboard-grid-2-columns')), findsOneWidget);
    expect(tester.getSize(find.byKey(actionKeys.first)).width,
        closeTo((760 - 14) / 2, .01));
    expect(tester.getTopRight(find.byKey(actionKeys[1])).dx, closeTo(760, .01));
    expect(tester.getTopLeft(find.byKey(actionKeys[2])).dy,
        greaterThan(tester.getTopLeft(find.byKey(actionKeys[0])).dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('card width responds to available width without trailing gap',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpGrid(tester, 1100);
    final initialWidth = tester.getSize(find.byKey(actionKeys.first)).width;
    expect(
        tester.getTopRight(find.byKey(actionKeys.last)).dx, closeTo(1100, .01));

    await pumpGrid(tester, 1250);
    final expandedWidth = tester.getSize(find.byKey(actionKeys.first)).width;
    expect(expandedWidth, greaterThan(initialWidth));
    expect(
        tester.getTopRight(find.byKey(actionKeys.last)).dx, closeTo(1250, .01));
  });

  test('lesson and action grids share the same responsive policy', () {
    expect(
      DashboardGridPolicy.columnsFor(
        availableWidth: 1180,
        minimumTileWidth: 250,
        maxColumns: 4,
        spacing: 14,
      ),
      4,
    );
    expect(
      DashboardGridPolicy.columnsFor(
        availableWidth: 1180,
        minimumTileWidth: 120,
        maxColumns: 10,
        spacing: 10,
      ),
      9,
    );
  });
}
