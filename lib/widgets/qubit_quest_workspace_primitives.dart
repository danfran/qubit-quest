import 'package:flutter/material.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';

/// Shared workspace layout primitives (v2.6 M11C, from the M11B visual
/// design). Screens compose these instead of restyling panels locally, so
/// the Composer now and Journey, Mastery and the Notebook later share one
/// set of headings, panels, disclosures and maths wells.

/// Panel heading. Uppercase and letter-spaced by default; [preserveCase]
/// keeps the text exactly as written and must be used whenever the label
/// contains mathematics (uppercasing turns θ into Θ, M11B §5).
class QqPanelLabel extends StatelessWidget {
  const QqPanelLabel(
    this.text, {
    super.key,
    this.preserveCase = false,
    this.color = QubitQuestColors.accentInteractive,
  });

  final String text;
  final bool preserveCase;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
        preserveCase ? text : text.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: QqType.panelHeading.copyWith(
          color: color,
          letterSpacing: preserveCase ? .2 : null,
        ),
      );
}

/// A primary workspace panel: work-tone surface, a label row with optional
/// trailing controls, and content. Peer panels in a grid use this; content
/// inside a panel is divided by spacing and rules, not nested cards.
class QqWorkspacePanel extends StatelessWidget {
  const QqWorkspacePanel({
    super.key,
    required this.label,
    required this.child,
    this.trailing,
    this.subtitle,
    this.preserveCase = false,
    this.padding = QqSpace.panel,
    this.color = QubitQuestSurfaces.work,
  });

  final String label;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final bool preserveCase;
  final EdgeInsets padding;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: QubitQuestRadii.card,
          border: Border.all(color: QubitQuestSurfaces.rule),
        ),
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row: the heading and its contextual actions share
              // one line, vertically centred (actions are ≥ 34 px tall).
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 30),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: QqPanelLabel(label, preserveCase: preserveCase),
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
              if (subtitle case final text?) ...[
                const SizedBox(height: 2),
                Text(text, style: QqType.meta),
              ],
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      );
}

/// Progressive disclosure row: chevron, title and an optional inline
/// summary of what is inside, so a closed section still says what it holds.
/// The open state is reported through [onChanged] so hosts can remember it
/// in memory (M11B D5: not persisted).
class QqDisclosure extends StatefulWidget {
  const QqDisclosure({
    super.key,
    required this.title,
    required this.child,
    this.summary,
    this.initiallyExpanded = false,
    this.onChanged,
    this.toggleKey,
  });

  /// Key on the tappable header row (for tests and focus).
  final Key? toggleKey;
  final String title;
  final String? summary;
  final Widget child;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onChanged;

  @override
  State<QqDisclosure> createState() => _QqDisclosureState();
}

class _QqDisclosureState extends State<QqDisclosure> {
  late bool _open = widget.initiallyExpanded;

  void _toggle() {
    setState(() => _open = !_open);
    widget.onChanged?.call(_open);
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1, color: QubitQuestSurfaces.rule),
          Semantics(
            button: true,
            expanded: _open,
            label: widget.title,
            excludeSemantics: true,
            child: InkWell(
              key: widget.toggleKey,
              onTap: _toggle,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Row(
                  children: [
                    Icon(
                      _open
                          ? Icons.expand_more_rounded
                          : Icons.chevron_right_rounded,
                      size: 18,
                      color: QubitQuestColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    // The summary follows the title and wraps beneath it
                    // when the row is narrow, rather than being truncated.
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          runSpacing: 2,
                          children: [
                            Text(widget.title, style: QqType.subheading),
                            if (widget.summary case final summary? when !_open)
                              Text(summary, style: QqType.meta),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 14, top: 2),
              child: DefaultTextStyle.merge(
                style: QqType.body.copyWith(fontSize: 14),
                child: widget.child,
              ),
            ),
        ],
      );
}

/// Inset well for displayed mathematics: darker than its surroundings, with
/// a violet left rule. Content scrolls horizontally rather than shrinking
/// below readability.
class QqMathWell extends StatelessWidget {
  const QqMathWell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: QubitQuestSurfaces.inset,
          borderRadius: BorderRadius.horizontal(right: Radius.circular(8)),
          border: Border(
            left: BorderSide(color: QubitQuestColors.accentStrong, width: 3),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        child: child,
      );
}
