// v2.6 M3: desktop Composer workspace — layout preferences, tier geometry
// and angle parsing (pure logic, no widgets).
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/utils/angle_expression.dart';
import 'package:quantumquiz/widgets/composer_workspace/desktop_composer_workspace.dart';
import 'package:quantumquiz/widgets/composer_workspace/workspace_layout_state.dart';

class _CountingStorage extends InMemoryAppStorage {
  int writes = 0;
  @override
  Future<void> writeString(String key, String value) {
    writes++;
    return super.writeString(key, value);
  }
}

void main() {
  group('parseAngleExpression', () {
    test('accepts radians and π notation without rounding', () {
      expect(parseAngleExpression('1.5708'), 1.5708);
      expect(parseAngleExpression('-0.25'), -0.25);
      expect(parseAngleExpression('2 rad'), 2);
      expect(parseAngleExpression('π'), math.pi);
      expect(parseAngleExpression('pi/2'), math.pi / 2);
      expect(parseAngleExpression('3π/4'), 3 * math.pi / 4);
      expect(parseAngleExpression('-π/8'), -math.pi / 8);
      expect(parseAngleExpression('0.25π'), 0.25 * math.pi);
      expect(parseAngleExpression('2*pi'), 2 * math.pi);
      expect(parseAngleExpression('(3/4)π'), 3 * math.pi / 4);
      expect(parseAngleExpression(' 3 / 4 π '), 3 * math.pi / 4);
      expect(parseAngleExpression('7π'), 7 * math.pi,
          reason: 'no range reduction, like the existing dialog');
      expect(parseAngleExpression('1e-3'), 1e-3);
    });

    test('rejects anything else', () {
      for (final input in [
        '',
        'abc',
        'π/0',
        'ππ',
        'π2',
        '1/2/3',
        '--1',
        '1..2',
        'pi/x',
      ]) {
        expect(parseAngleExpression(input), isNull, reason: input);
      }
    });

    test('formatAngleAsPi prefers simple fractions of π', () {
      expect(formatAngleAsPi(0), '0');
      expect(formatAngleAsPi(math.pi), 'π');
      expect(formatAngleAsPi(math.pi / 2), 'π/2');
      expect(formatAngleAsPi(3 * math.pi / 4), '3π/4');
      expect(formatAngleAsPi(-math.pi / 8), '-π/8');
      expect(formatAngleAsPi(1), '0.3183π');
      // Round-trips through the parser.
      for (final a in [math.pi / 3, 5 * math.pi / 6, -math.pi]) {
        expect(parseAngleExpression(formatAngleAsPi(a)), closeTo(a, 1e-12));
      }
    });
  });

  group('WorkspaceLayoutPreferences', () {
    test('round-trips through JSON', () {
      final prefs = WorkspaceLayoutPreferences.defaults.copyWith(
        paletteWidth: 230,
        resultsWidth: 400,
        inspectorHeight: 320,
        paletteCollapsed: true,
        navigationCollapsed: true,
      );
      expect(
        WorkspaceLayoutPreferences.fromJsonString(jsonEncode(prefs.toJson())),
        prefs,
      );
    });

    test('missing, malformed and future records fall back safely', () {
      const defaults = WorkspaceLayoutPreferences.defaults;
      expect(WorkspaceLayoutPreferences.fromJsonString(null), defaults);
      expect(WorkspaceLayoutPreferences.fromJsonString('not json'), defaults);
      expect(WorkspaceLayoutPreferences.fromJsonString('[1,2]'), defaults);
      expect(
        WorkspaceLayoutPreferences.fromJsonString(
            jsonEncode({'version': 2, 'paletteWidth': 250})),
        defaults,
        reason: 'unknown future version is ignored',
      );
      final mixed = WorkspaceLayoutPreferences.fromJsonString(jsonEncode({
        'version': 1,
        'paletteWidth': 'wide',
        'resultsWidth': 99999,
        'inspectorHeight': -5,
        'paletteCollapsed': 'yes',
        'resultsCollapsed': true,
      }));
      expect(mixed.paletteWidth, defaults.paletteWidth);
      expect(mixed.resultsWidth, WorkspaceLayoutPreferences.maxResultsWidth);
      expect(
          mixed.inspectorHeight, WorkspaceLayoutPreferences.minInspectorHeight);
      expect(mixed.paletteCollapsed, isFalse);
      expect(mixed.resultsCollapsed, isTrue);
    });

    test('controller previews without writing and commits once', () async {
      final storage = _CountingStorage();
      final layout = WorkspaceLayoutController(storage: storage);
      await layout.load();
      for (var i = 0; i < 20; i++) {
        layout.preview(layout.preferences.copyWith(paletteWidth: 200.0 + i));
      }
      await Future<void>.delayed(Duration.zero);
      expect(storage.writes, 0, reason: 'drag ticks never write storage');
      layout.commit();
      await Future<void>.delayed(Duration.zero);
      expect(storage.writes, 1);
      final reloaded = WorkspaceLayoutController(storage: storage);
      await reloaded.load();
      expect(reloaded.preferences.paletteWidth, 219);
    });

    test('reset restores panel defaults but keeps the navigation choice',
        () async {
      final layout = WorkspaceLayoutController(storage: InMemoryAppStorage());
      layout.commit(layout.preferences.copyWith(
        paletteWidth: 260,
        resultsCollapsed: true,
        navigationCollapsed: true,
      ));
      layout.resetWorkspace();
      expect(layout.preferences.paletteWidth,
          WorkspaceLayoutPreferences.defaultPaletteWidth);
      expect(layout.preferences.resultsCollapsed, isFalse);
      expect(layout.preferences.navigationCollapsed, isTrue);
    });

    test('unreadable storage never breaks the layout', () async {
      final layout = WorkspaceLayoutController(storage: _ThrowingStorage());
      await layout.load();
      expect(layout.preferences, WorkspaceLayoutPreferences.defaults);
      layout.commit(layout.preferences.copyWith(paletteWidth: 210));
      await Future<void>.delayed(Duration.zero);
      expect(layout.preferences.paletteWidth, 210);
    });
  });

  group('ComposerWorkspaceGeometry', () {
    const defaults = WorkspaceLayoutPreferences.defaults;
    ComposerWorkspaceGeometry at(double width,
            [WorkspaceLayoutPreferences prefs = defaults]) =>
        ComposerWorkspaceGeometry.resolve(width, prefs);

    test('workspace widths of real browser viewports', () {
      // Workspace = viewport − 238 px sidebar − 1 px divider.
      expect(at(1920 - 239).tier, ComposerWorkspaceTier.wide);
      expect(at(1440 - 239).tier, ComposerWorkspaceTier.wide);
      expect(at(1280 - 239).tier, ComposerWorkspaceTier.wide);
      expect(at(1280 - 65).tier, ComposerWorkspaceTier.wide,
          reason: 'collapsed navigation rail');
      expect(at(1024 - 239).tier, ComposerWorkspaceTier.medium);
      expect(at(1024 - 65).tier, ComposerWorkspaceTier.compact,
          reason: 'collapsing the navigation buys three columns');
      expect(at(800).tier, ComposerWorkspaceTier.medium);
      expect(at(600).tier, ComposerWorkspaceTier.narrow);
    });

    test('preferred widths are shown exactly while the canvas fits', () {
      final prefs = defaults.copyWith(paletteWidth: 260, resultsWidth: 420);
      final g = at(1201, prefs);
      expect(g.tier, ComposerWorkspaceTier.wide);
      expect(g.paletteWidth, 260);
      expect(g.resultsWidth, 420);
    });

    test('compact shrinks side panels to keep the minimum canvas', () {
      final g = at(960);
      expect(g.tier, ComposerWorkspaceTier.compact);
      final canvas = 960 -
          ComposerWorkspaceGeometry.gutter * 2 -
          ComposerWorkspaceGeometry.gap * 2 -
          g.paletteWidth -
          g.resultsWidth;
      expect(canvas, closeTo(ComposerWorkspaceGeometry.minCanvasWidth, 0.5));
      expect(g.paletteWidth,
          greaterThanOrEqualTo(WorkspaceLayoutPreferences.minPaletteWidth));
      expect(g.resultsWidth,
          greaterThanOrEqualTo(WorkspaceLayoutPreferences.minResultsWidth));
    });

    test('collapsed panels use rails and free width for the canvas', () {
      final g = at(
          800,
          defaults.copyWith(
            paletteCollapsed: true,
            resultsCollapsed: true,
          ));
      expect(g.tier, ComposerWorkspaceTier.wide);
      expect(g.paletteWidth, ComposerWorkspaceGeometry.paletteRailWidth);
      expect(g.resultsWidth, ComposerWorkspaceGeometry.resultsRailWidth);
    });

    test('three expanded columns need 908 px', () {
      expect(ComposerWorkspaceGeometry.minimumThreeColumnWidth, 908);
      expect(at(908).tier, ComposerWorkspaceTier.compact);
      expect(at(907).tier, ComposerWorkspaceTier.medium);
    });
  });

  group('circuit scale preference (M3.1)', () {
    test('defaults to 125% and pre-M3.1 records keep working', () {
      expect(WorkspaceLayoutPreferences.defaults.circuitScale, 1.25);
      final old = jsonEncode({
        'version': 1,
        'paletteWidth': 220,
        'resultsWidth': 400,
        'inspectorHeight': 300,
        'paletteCollapsed': true,
        'resultsCollapsed': false,
        'inspectorCollapsed': false,
        'navigationCollapsed': true,
      });
      final prefs = WorkspaceLayoutPreferences.fromJsonString(old);
      expect(prefs.circuitScale, 1.25);
      expect(prefs.paletteWidth, 220, reason: 'other fields untouched');
      expect(prefs.paletteCollapsed, isTrue);
      expect(prefs.navigationCollapsed, isTrue);
    });

    test('invalid values fall back or snap to a supported step', () {
      String record(Object? scale) =>
          jsonEncode({'version': 1, 'circuitScale': scale});
      for (final (value, expected) in [
        ('big', 1.25),
        (null, 1.25),
        (true, 1.25),
        (1.0, 1.0),
        (1.5, 1.5),
        (1.3, 1.25),
        (0.2, 1.0),
        (9, 1.5),
      ]) {
        expect(
            WorkspaceLayoutPreferences.fromJsonString(record(value))
                .circuitScale,
            expected,
            reason: '$value');
      }
      expect(WorkspaceLayoutPreferences.normalizeScale(double.nan), 1.25);
    });

    test('round-trips, commits once and resets to the default', () async {
      final storage = _CountingStorage();
      final controller = WorkspaceLayoutController(storage: storage);
      await controller.load();
      controller.commit(controller.preferences.copyWith(circuitScale: 1.5));
      await Future<void>.delayed(Duration.zero);
      expect(storage.writes, 1);
      final reloaded = WorkspaceLayoutController(storage: storage);
      await reloaded.load();
      expect(reloaded.preferences.circuitScale, 1.5);
      reloaded.resetWorkspace();
      expect(reloaded.preferences.circuitScale, 1.25);
    });
  });
}

class _ThrowingStorage extends InMemoryAppStorage {
  @override
  Future<String?> readString(String key) async => throw StateError('blocked');
  @override
  Future<void> writeString(String key, String value) async =>
      throw StateError('blocked');
}
