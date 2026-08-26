import 'package:flutter/material.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/lesson_content_safe_area.dart';

/// Canonical page-level frame for the reviewed Qubit Quest activity screens.
///
/// Presenters retain ownership of educational content and interaction logic;
/// this widget owns only product background, safe bounds, and the shared outer
/// content grid.
class QubitQuestActivityShell extends StatelessWidget {
  const QubitQuestActivityShell({
    super.key,
    required this.header,
    required this.body,
    this.bottomAction,
    this.constrainBody = true,
  });

  static const double maxContentWidth =
      QubitQuestLayout.activityMaxContentWidth;

  final PreferredSizeWidget header;
  final Widget body;
  final Widget? bottomAction;

  /// Composer is a domain workspace and manages its own internal responsive
  /// geometry. Other activity bodies use the canonical readable page grid.
  final bool constrainBody;

  @override
  Widget build(BuildContext context) {
    Widget safeBody = KeyedSubtree(
      key: const ValueKey('qubit-quest-activity-body'),
      child: body,
    );
    if (constrainBody) {
      safeBody = Center(
        child: ConstrainedBox(
          key: const ValueKey('qubit-quest-activity-content-grid'),
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: safeBody,
        ),
      );
    }

    return Scaffold(
      key: const ValueKey('qubit-quest-activity-shell'),
      backgroundColor: QubitQuestColors.background,
      appBar: header,
      body: LessonContentSafeArea(child: safeBody),
      bottomNavigationBar: bottomAction == null
          ? null
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.only(
                bottom: QubitQuestSpacing.component,
              ),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: maxContentWidth,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.sizeOf(context).width <
                              QubitQuestLayout.activityCompactBreakpoint
                          ? QubitQuestSpacing.component
                          : QubitQuestSpacing.section,
                    ),
                    child: KeyedSubtree(
                      key: const ValueKey(
                        'qubit-quest-activity-bottom-action',
                      ),
                      child: bottomAction!,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
