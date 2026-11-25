import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:quantumquiz/storage/app_storage.dart';

/// The learner's preferred desktop workspace layout. Purely presentational:
/// it never contains circuit state and is independent of any
/// `ComposerSession`.
///
/// Sizes are *preferences*. Responsive layouts may show panels narrower than
/// preferred when space is short, but never write those temporary sizes back.
@immutable
class WorkspaceLayoutPreferences {
  const WorkspaceLayoutPreferences({
    this.paletteWidth = defaultPaletteWidth,
    this.resultsWidth = defaultResultsWidth,
    this.inspectorHeight = defaultInspectorHeight,
    this.paletteCollapsed = false,
    this.resultsCollapsed = false,
    this.inspectorCollapsed = false,
    this.navigationCollapsed = false,
    this.circuitScale = defaultCircuitScale,
  });

  /// Supported circuit display scales (M3.1, revised D5). Discrete steps,
  /// not continuous zoom.
  static const List<double> circuitScales = [1.0, 1.25, 1.5];

  /// 125%: on a 1280–1920 px desktop the 100% geometry (30 px gates, 40 px
  /// rows) leaves most of the canvas empty; 125% makes gates 37.5 px and a
  /// five-qubit circuit 250 px tall, which still leaves the inspector room
  /// at 800 px viewport height.
  static const double defaultCircuitScale = 1.25;

  /// The nearest supported scale; non-finite values give the default.
  static double normalizeScale(double value) {
    if (!value.isFinite) return defaultCircuitScale;
    return circuitScales
        .reduce((a, b) => (value - a).abs() <= (value - b).abs() ? a : b);
  }

  static const double defaultPaletteWidth = 196;
  static const double minPaletteWidth = 156;
  static const double maxPaletteWidth = 280;

  static const double defaultResultsWidth = 340;
  static const double minResultsWidth = 280;
  static const double maxResultsWidth = 560;

  static const double defaultInspectorHeight = 290;
  static const double minInspectorHeight = 150;
  static const double maxInspectorHeight = 520;

  static const WorkspaceLayoutPreferences defaults =
      WorkspaceLayoutPreferences();

  final double paletteWidth;
  final double resultsWidth;
  final double inspectorHeight;
  final bool paletteCollapsed;
  final bool resultsCollapsed;
  final bool inspectorCollapsed;

  /// Whether the application's navigation sidebar is collapsed to a rail.
  final bool navigationCollapsed;

  /// Circuit display scale, one of [circuitScales].
  final double circuitScale;

  WorkspaceLayoutPreferences copyWith({
    double? paletteWidth,
    double? resultsWidth,
    double? inspectorHeight,
    bool? paletteCollapsed,
    bool? resultsCollapsed,
    bool? inspectorCollapsed,
    bool? navigationCollapsed,
    double? circuitScale,
  }) =>
      WorkspaceLayoutPreferences(
        paletteWidth: _clamp(paletteWidth ?? this.paletteWidth, minPaletteWidth,
            maxPaletteWidth),
        resultsWidth: _clamp(resultsWidth ?? this.resultsWidth, minResultsWidth,
            maxResultsWidth),
        inspectorHeight: _clamp(inspectorHeight ?? this.inspectorHeight,
            minInspectorHeight, maxInspectorHeight),
        paletteCollapsed: paletteCollapsed ?? this.paletteCollapsed,
        resultsCollapsed: resultsCollapsed ?? this.resultsCollapsed,
        inspectorCollapsed: inspectorCollapsed ?? this.inspectorCollapsed,
        navigationCollapsed: navigationCollapsed ?? this.navigationCollapsed,
        circuitScale: normalizeScale(circuitScale ?? this.circuitScale),
      );

  static double _clamp(double value, double min, double max) =>
      value.isFinite ? value.clamp(min, max).toDouble() : min;

  Map<String, Object?> toJson() => {
        'version': 1,
        'paletteWidth': paletteWidth,
        'resultsWidth': resultsWidth,
        'inspectorHeight': inspectorHeight,
        'paletteCollapsed': paletteCollapsed,
        'resultsCollapsed': resultsCollapsed,
        'inspectorCollapsed': inspectorCollapsed,
        'navigationCollapsed': navigationCollapsed,
        'circuitScale': circuitScale,
      };

  /// Reads a stored record defensively: unknown, missing, malformed or
  /// out-of-range fields fall back to defaults or are clamped; a record from
  /// a future incompatible version is ignored entirely.
  static WorkspaceLayoutPreferences fromJsonString(String? source) {
    if (source == null) return defaults;
    try {
      final root = jsonDecode(source);
      if (root is! Map<String, dynamic>) return defaults;
      final version = root['version'];
      if (version is! int || version != 1) return defaults;
      double? number(String key) {
        final value = root[key];
        return value is num && value.isFinite ? value.toDouble() : null;
      }

      bool? flag(String key) {
        final value = root[key];
        return value is bool ? value : null;
      }

      return defaults.copyWith(
        paletteWidth: number('paletteWidth'),
        resultsWidth: number('resultsWidth'),
        inspectorHeight: number('inspectorHeight'),
        paletteCollapsed: flag('paletteCollapsed'),
        resultsCollapsed: flag('resultsCollapsed'),
        inspectorCollapsed: flag('inspectorCollapsed'),
        navigationCollapsed: flag('navigationCollapsed'),
        // Additive in v1: records written before M3.1 have no scale and
        // get the default; unsupported values snap to the nearest step.
        circuitScale: number('circuitScale'),
      );
    } on FormatException {
      return defaults;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is WorkspaceLayoutPreferences &&
      other.paletteWidth == paletteWidth &&
      other.resultsWidth == resultsWidth &&
      other.inspectorHeight == inspectorHeight &&
      other.paletteCollapsed == paletteCollapsed &&
      other.resultsCollapsed == resultsCollapsed &&
      other.inspectorCollapsed == inspectorCollapsed &&
      other.navigationCollapsed == navigationCollapsed &&
      other.circuitScale == circuitScale;

  @override
  int get hashCode => Object.hash(
        paletteWidth,
        resultsWidth,
        inspectorHeight,
        paletteCollapsed,
        resultsCollapsed,
        inspectorCollapsed,
        navigationCollapsed,
        circuitScale,
      );
}

/// Owns the layout preferences for the web shell and Composer workspace.
///
/// [preview] changes what is shown without writing storage (used on every
/// resize drag tick); [commit] persists once (drag end, toggles, reset).
/// Storage failures never affect the layout in use.
class WorkspaceLayoutController extends ChangeNotifier {
  WorkspaceLayoutController({AppStorage? storage}) : _storage = storage;

  static const String storageKey = 'qq_web_workspace_layout_v1';

  final AppStorage? _storage;
  WorkspaceLayoutPreferences _preferences = WorkspaceLayoutPreferences.defaults;
  bool _loaded = false;
  bool _disposed = false;

  WorkspaceLayoutPreferences get preferences => _preferences;
  bool get isLoaded => _loaded;

  /// Loads stored preferences once. Preferences changed before loading
  /// finishes win over the stored record.
  Future<void> load() async {
    if (_loaded) return;
    final storage = _storage;
    String? source;
    if (storage != null) {
      try {
        source = await storage.readString(storageKey);
      } catch (_) {
        source = null;
      }
    }
    if (_disposed || _loaded) return;
    _loaded = true;
    final stored = WorkspaceLayoutPreferences.fromJsonString(source);
    if (_preferences == WorkspaceLayoutPreferences.defaults &&
        stored != _preferences) {
      _preferences = stored;
      notifyListeners();
    }
  }

  /// Shows [next] immediately without writing storage.
  void preview(WorkspaceLayoutPreferences next) {
    if (_disposed || next == _preferences) return;
    _preferences = next;
    notifyListeners();
  }

  /// Shows and persists [next] (or the current preview when omitted).
  void commit([WorkspaceLayoutPreferences? next]) {
    if (_disposed) return;
    if (next != null && next != _preferences) {
      _preferences = next;
      notifyListeners();
    }
    _loaded = true;
    final storage = _storage;
    if (storage == null) return;
    unawaited(
      storage
          .writeString(storageKey, jsonEncode(_preferences.toJson()))
          .catchError((Object _) {}),
    );
  }

  /// Restores default panel sizes and visibility. The navigation preference
  /// belongs to the shell and is kept.
  void resetWorkspace() => commit(WorkspaceLayoutPreferences(
        navigationCollapsed: _preferences.navigationCollapsed,
      ));

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Clamps [preferred] into [min, max] where max may be smaller than the
/// preference because of the viewport. Never stored back.
double fitWithin(double preferred, double min, double max) =>
    math.max(min, math.min(preferred, max));
