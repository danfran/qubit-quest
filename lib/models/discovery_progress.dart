import 'package:shared_preferences/shared_preferences.dart';

class DiscoveryProgress {
  static const String storageKey = 'unlockedDiscoveries';

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
    'Interference',
    'Destructive Interference',
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
}
