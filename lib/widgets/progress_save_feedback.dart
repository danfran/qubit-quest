import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:flutter/material.dart';

/// Keeps persistence errors out of fire-and-forget activity callbacks while
/// making clear that a correct answer has not yet been saved as progress.
Future<bool> saveProgressWithFeedback(
    BuildContext context, Future<void> Function() save) async {
  try {
    await save();
    return true;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Progress not saved. Please retry.'),
        duration: const Duration(days: 1),
        action: SnackBarAction(
            label: 'Retry save',
            onPressed: () {
              saveProgressWithFeedback(context, save);
            }),
      ));
    }
    return false;
  }
}

class ProgressSaveStatusView extends StatelessWidget {
  const ProgressSaveStatusView({super.key, required this.controller});
  final CampaignProgressController controller;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (controller.saveStatus == ProgressSaveStatus.saved) {
            return const SizedBox.shrink();
          }
          return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(controller.saveStatus == ProgressSaveStatus.pending
                        ? 'Saving progress…'
                        : 'Progress not saved. Please retry.'),
                    if (controller.saveStatus == ProgressSaveStatus.failed)
                      TextButton(
                          onPressed: () => saveProgressWithFeedback(
                              context, controller.retrySave),
                          child: const Text('Retry save')),
                  ],
                ),
              ));
        },
      );
}
