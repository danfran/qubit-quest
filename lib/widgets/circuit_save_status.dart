import 'package:flutter/material.dart';
import 'package:quantumquiz/models/circuit_save_queue.dart';

class CircuitSaveStatusView extends StatelessWidget {
  const CircuitSaveStatusView({super.key, required this.queue});
  final CircuitSaveQueue queue;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: queue,
        builder: (context, _) => Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(
                switch (queue.status) {
                  CircuitSaveStatus.idle => 'No pending circuit changes',
                  CircuitSaveStatus.pending => 'Saving circuit…',
                  CircuitSaveStatus.saved => 'Circuit saved',
                  CircuitSaveStatus.failed =>
                    'Circuit not saved. Please retry.',
                },
                style: Theme.of(context).textTheme.bodySmall),
            if (queue.status == CircuitSaveStatus.failed)
              TextButton(
                  onPressed: queue.retry, child: const Text('Retry save')),
          ],
        ),
      );
}
