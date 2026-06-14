import 'package:shared_preferences/shared_preferences.dart';

class DiscoveryProgress {
  static const String storageKey = 'unlockedDiscoveries';

  static const List<String> discoveryOrder = [
    'Reversibility',
    'Superposition',
    'Phase',
    'Phase Is Hidden',
    'Phase Becomes Bit',
    'Bit Becomes Phase',
    'Interference',
    'Destructive Interference',
    'Entanglement',
    'Hidden Information',
    'Phase Carrier',
    'Phase Kickback',
    'Hidden Communication',
    'The Language of Quantum Algorithms',
    'A Special State',
    'Hidden Mark',
    'Oracle Thinking',
    'Oracle',
    'Invisible Difference',
    'Phase Marking',
    'Marked But Hidden',
    'Mark Becomes Probability',
    'Amplitude Amplification',
    'Mini Grover',
    'Search Through Interference',
    'Variational Circuits',
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
