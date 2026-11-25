/// Bounded linear undo/redo history of committed states.
///
/// Follows the Bloch Explorer pattern (`BlochExplorerHistory`): a list of
/// committed states and a cursor. Recording after an undo discards the redo
/// branch. At most [limit] undo steps are kept; the oldest states are dropped
/// first. Pure Dart, session-local and never persisted.
class EditHistory<T> {
  EditHistory(T initial, {this.limit = defaultLimit})
      : assert(limit > 0),
        _states = [initial];

  static const int defaultLimit = 100;

  /// Maximum number of undo steps retained.
  final int limit;
  final List<T> _states;
  int _index = 0;

  T get current => _states[_index];
  bool get canUndo => _index > 0;
  bool get canRedo => _index < _states.length - 1;

  /// Number of steps currently available to [undo].
  int get undoDepth => _index;

  /// Number of steps currently available to [redo].
  int get redoDepth => _states.length - 1 - _index;

  /// Records [state] as the newest committed state, discarding any redo
  /// branch and trimming to [limit] undo steps.
  void record(T state) {
    if (canRedo) _states.removeRange(_index + 1, _states.length);
    _states.add(state);
    _index = _states.length - 1;
    final excess = _states.length - 1 - limit;
    if (excess > 0) {
      _states.removeRange(0, excess);
      _index -= excess;
    }
  }

  /// Moves the cursor back and returns the state to restore, or null.
  T? undo() {
    if (!canUndo) return null;
    return _states[--_index];
  }

  /// Moves the cursor forward and returns the state to restore, or null.
  T? redo() {
    if (!canRedo) return null;
    return _states[++_index];
  }

  /// Forgets every state except [state], which becomes the only entry.
  void reset(T state) {
    _states
      ..clear()
      ..add(state);
    _index = 0;
  }
}
