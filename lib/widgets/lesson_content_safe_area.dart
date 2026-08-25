import 'package:flutter/widgets.dart';

/// Applies the platform's usable viewport bounds to a mobile lesson body.
///
/// Activity presenters remain responsible for their own responsive padding and
/// composition. This boundary only prevents lesson content from extending into
/// display cutouts and other unsafe system regions.
class LessonContentSafeArea extends StatelessWidget {
  const LessonContentSafeArea({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: KeyedSubtree(
          key: const ValueKey('lesson-content-safe-content'),
          child: child,
        ),
      );
}
