import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// v2.6 M11C: the Sandbox uses the laboratory Composer (central analysis
/// with State / Measure tabs); lessons, Mastery and Notebook examples keep
/// the classic results column (State / Bloch / Measure). These finders
/// locate a results tab in either layout, so tests about measurement and
/// state semantics do not depend on which layout hosts them.

bool _under(Element element, List<Key> keys) {
  var found = false;
  element.visitAncestorElements((ancestor) {
    if (keys.contains(ancestor.widget.key)) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}

const _selectors = <Key>[
  ValueKey('quantum-inspector-view-selector'),
  ValueKey('composer-analysis-tabs'),
];

/// The "Measure" tab of whichever results selector is on screen.
final Finder anyMeasureTab = find.byElementPredicate(
  (e) =>
      e.widget is Text &&
      (e.widget as Text).data == 'Measure' &&
      _under(e, _selectors),
  description: 'Measure tab (classic or laboratory)',
);

/// The "State" tab of whichever results selector is on screen.
final Finder anyStateTab = find.byElementPredicate(
  (e) =>
      e.widget is Text &&
      (e.widget as Text).data == 'State' &&
      _under(e, _selectors),
  description: 'State tab (classic or laboratory)',
);

/// The Composer opens straight into the Sandbox (M11C) once it becomes
/// visible; storage is read asynchronously. Pumps until the header's qubit
/// selector is on screen, without settling unrelated animations.
Future<void> pumpUntilSandboxOpen(WidgetTester tester) async {
  final selector = find.byKey(const ValueKey('web-composer-qubit-selector'));
  for (var i = 0; i < 100 && selector.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}
