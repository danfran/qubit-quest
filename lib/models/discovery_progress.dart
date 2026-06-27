import 'package:shared_preferences/shared_preferences.dart';

class DiscoveryProgress {
  static const String storageKey = 'unlockedDiscoveries';
  static const String openedNotebookEntriesKey = 'openedNotebookEntries';

  static const List<String> discoveryOrder = [
    'Information',
    'Reversibility',
    'Equivalent Results',
    'State Transformations',
    'The Quantum Bit',
    'Hidden Change',
    'Invisible Difference',
    'Relative Phase',
    'Phase Information',
    'Phase',
    'The Third State',
    'Two Possibilities',
    'Precise Superposition',
    'Prepared Possibilities',
    'Superposition',
    'Phase Is Hidden',
    'Phase Becomes Bit',
    'Bit Becomes Phase',
    'Destructive Interference',
    'Interference',
    'Two Qubits',
    'Correlation',
    'Bell State',
    'One Quantum System',
    'Entanglement',
    'Control',
    'Conditional Action',
    'Information Transfer',
    'Swap',
    'Information Flow',
    'Three Qubits',
    'Shared Information',
    'All Together',
    'GHZ State',
    'One System, Three Qubits',
    'Hidden Information',
    'Phase Carrier',
    'Phase Kickback',
    'Hidden Communication',
    'The Language of Quantum Algorithms',
    'A Special State',
    'Hidden Mark',
    'Oracle',
    'Invisible Mark',
    'Phase Marking',
    'Marked But Hidden',
    'Mark Becomes Probability',
    'Amplitude Amplification',
    'Mini Grover',
    'Search Through Interference',
  ];

  static Future<Set<String>> loadUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(storageKey) ?? const <String>[]).toSet();
  }

  static Future<void> unlock(String discoveryTitle) async {
    final String normalized = discoveryTitle.trim();
    if (normalized.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final unlocked =
        (prefs.getStringList(storageKey) ?? const <String>[]).toSet();
    unlocked.add(normalized);
    await prefs.setStringList(storageKey, unlocked.toList()..sort());
  }

  static Future<Set<String>> loadOpenedNotebookEntries() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(openedNotebookEntriesKey) ?? const <String>[])
        .toSet();
  }

  static Future<void> markNotebookEntryOpened(String discoveryTitle) async {
    final String normalized = discoveryTitle.trim();
    if (normalized.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final opened =
        (prefs.getStringList(openedNotebookEntriesKey) ?? const <String>[])
            .toSet();
    opened.add(normalized);
    await prefs.setStringList(
      openedNotebookEntriesKey,
      opened.toList()..sort(),
    );
  }

  static Future<bool> hasUnopenedNotebookEntries(
    Iterable<String> notebookDiscoveryTitles,
  ) async {
    final unlocked = await loadUnlocked();
    final opened = await loadOpenedNotebookEntries();
    final notebookTitles = notebookDiscoveryTitles.toSet();
    return unlocked.intersection(notebookTitles).difference(opened).isNotEmpty;
  }
}
