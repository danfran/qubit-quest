import 'package:flutter/material.dart';
import '../models/sandbox_workspace_persistence.dart';
import '../models/sandbox_program_snapshot.dart';

Future<({bool opened, SandboxProgramSnapshot? snapshot})>
    loadSandboxWithRecovery(BuildContext context,
        SandboxWorkspacePersistence owner, int qubits) async {
  var recover = false;
  while (context.mounted) {
    try {
      final snapshot =
          recover ? await owner.recover(qubits) : await owner.load(qubits);
      return (opened: context.mounted, snapshot: snapshot);
    } catch (_) {
      if (!context.mounted) break;
      final action = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('Sandbox could not be restored'),
                content: const Text(
                    'Your saved records have been retained. Retry loading, or explicitly recover a previous saved circuit.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, 'cancel'),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, 'recover'),
                      child: const Text('Recover previous')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, 'retry'),
                      child: const Text('Retry')),
                ],
              ));
      if (action == null || action == 'cancel') break;
      recover = action == 'recover';
    }
  }
  return (opened: false, snapshot: null);
}

class UnexecutedMeasuredCircuit extends StatelessWidget {
  const UnexecutedMeasuredCircuit({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Circuit contains measurements and has not been executed. '
            'Only its initial state is loaded; no final state, Bloch view or sampled '
            'probabilities are available yet.'),
      );
}
