import 'package:flutter/material.dart';
import 'package:quantumquiz/models/discovery_progress.dart';
import 'package:quantumquiz/models/level_completion_action.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/notebook_entry.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/screens/learning_flow_widgets.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/widgets/level_header_router.dart';
import 'package:quantumquiz/widgets/qubit_quest_dialog.dart';

class McqScreen extends StatefulWidget {
  final int levelId;
  final McqLevel level;
  final Function(int)? onLevelUnlocked;

  const McqScreen({
    super.key,
    required this.levelId,
    required this.level,
    required this.onLevelUnlocked,
  });

  @override
  State<McqScreen> createState() => _McqScreenState();
}

class _McqScreenState extends State<McqScreen> {
  int? _selected;
  bool _answered = false;
  bool _hasUnopenedNotebookEntries = false;

  bool get _isCorrect => _selected == widget.level.correctOptionIndex;

  String get _badgeLabel => widget.level is ConceptCheckLevel
      ? (widget.level as ConceptCheckLevel).badgeLabel
      : 'Concept Check';

  String get _displayTitle => widget.level.title ?? 'Concept Check';

  @override
  void initState() {
    super.initState();
    _loadNotebookAttentionState();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final compact = media.size.width < 680;
    final compactAppBar = media.size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFF00030A),
      appBar: _buildAppBar(compact: compactAppBar),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 16 : 24,
                    compact ? 16 : 24,
                    compact ? 16 : 24,
                    0,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _ConceptCheckCard(
                        badgeLabel: _badgeLabel,
                        title: _displayTitle,
                        conceptIntro: widget.level.conceptIntro,
                        taskDescription: widget.level.taskDescription,
                        options: widget.level.options,
                        selected: _selected,
                        answered: _answered,
                        correctOptionIndex: widget.level.correctOptionIndex,
                        onSelected: (idx) => setState(() => _selected = idx),
                      ),
                      if (_answered &&
                          widget.level.solutionExplanation != null) ...[
                        const SizedBox(height: 14),
                        _ExplanationCard(
                          correct: _isCorrect,
                          text: widget.level.solutionExplanation!,
                        ),
                      ],
                    ]),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 16 : 24,
                        16,
                        compact ? 16 : 24,
                        16,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 920),
                        child: SizedBox(
                          width: double.infinity,
                          child: QubitQuestDialogButton.primary(
                            label: _answered
                                ? (_isCorrect
                                    ? 'Continue Journey'
                                    : 'Back to Level Select')
                                : 'Confirm Answer',
                            onPressed: _answered
                                ? () {
                                    if (_isCorrect) {
                                      widget.onLevelUnlocked
                                          ?.call(widget.levelId + 1);
                                    }
                                    Navigator.of(context).pop(
                                      _isCorrect
                                          ? LevelCompletionAction.nextLevel
                                          : LevelCompletionAction.levelSelect,
                                    );
                                  }
                                : _selected == null
                                    ? null
                                    : () => setState(() => _answered = true),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar({required bool compact}) {
    return LevelHeaderRouter.headerFor(
      level: widget.level,
      levelId: widget.levelId,
      compact: compact,
      actions: _buildAppBarActions(compact),
    );
  }

  List<Widget> _buildAppBarActions(bool compact) {
    return [
      _buildNotebookHeaderAction(compact: compact),
      SizedBox(width: compact ? 6 : 8),
      _buildMenuHeaderAction(compact: compact),
      SizedBox(width: compact ? 10 : 12),
    ];
  }

  Widget _buildNotebookHeaderAction({required bool compact}) {
    return Tooltip(
      message: 'Quantum Notebook',
      child: InkWell(
        onTap: _openQuantumNotebook,
        borderRadius: BorderRadius.circular(16),
        child: compact
            ? _NotebookAttentionBadge(
                visible: _hasUnopenedNotebookEntries,
                child: _HeaderActionShell(
                  child: Icon(
                    Icons.school_outlined,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.94),
                  ),
                ),
              )
            : SizedBox(
                width: 54,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _NotebookAttentionBadge(
                      visible: _hasUnopenedNotebookEntries,
                      child: _HeaderActionShell(
                        size: 32,
                        child: Icon(
                          Icons.school_outlined,
                          size: 17,
                          color: Colors.white.withValues(alpha: 0.94),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Notebook',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 9,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMenuHeaderAction({required bool compact}) {
    final menuButton = PopupMenuButton<String>(
      tooltip: 'Menu',
      color: QubitQuestDialog.cardColor,
      offset: const Offset(0, 10),
      onSelected: _selectMenuAction,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'notebook',
          child: ListTile(
            leading: Icon(Icons.school_outlined, color: Colors.white),
            title: Text(
              'Quantum Notebook',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        PopupMenuItem(
          value: 'levelSelect',
          child: ListTile(
            leading: Icon(Icons.view_list_outlined, color: Colors.white),
            title: Text(
              'Back to Level Select',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
      child: _HeaderActionShell(
        size: compact ? 34 : 32,
        child: Icon(
          Icons.settings_outlined,
          size: compact ? 18 : 17,
          color: Colors.white.withValues(alpha: 0.94),
        ),
      ),
    );

    if (compact) return menuButton;

    return SizedBox(
      width: 54,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          menuButton,
          const SizedBox(height: 2),
          Text(
            'Menu',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 9,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadNotebookAttentionState() async {
    final discoveryTitle = widget.level.discoveryTitle?.trim();
    if (discoveryTitle == null || discoveryTitle.isEmpty) return;
    final hasUnopened =
        await DiscoveryProgress.hasUnopenedNotebookEntries({discoveryTitle});
    if (!mounted) return;
    setState(() {
      _hasUnopenedNotebookEntries = hasUnopened;
    });
  }

  Future<void> _openQuantumNotebook() async {
    final entry = _notebookEntryForLevel(widget.level);
    final unlocked = await DiscoveryProgress.loadUnlocked();
    if (!mounted) return;

    setState(() {
      _hasUnopenedNotebookEntries = false;
    });

    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) {
          if (entry != null && unlocked.contains(entry.discoveryTitle)) {
            return NotebookEntryScreen(entry: entry);
          }
          return const DiscoveriesScreen();
        },
      ),
    );
  }

  void _selectMenuAction(String action) {
    switch (action) {
      case 'notebook':
        _openQuantumNotebook();
        break;
      case 'levelSelect':
        Navigator.of(context).pop(LevelCompletionAction.levelSelect);
        break;
    }
  }

  NotebookEntry? _notebookEntryForLevel(McqLevel level) {
    final discoveryTitle = level.discoveryTitle?.trim();
    if (discoveryTitle == null || discoveryTitle.isEmpty) return null;
    return notebookEntriesByDiscoveryTitle[discoveryTitle];
  }
}

class _HeaderActionShell extends StatelessWidget {
  const _HeaderActionShell({
    required this.child,
    this.size = 34,
  });

  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: QubitQuestDialog.cardColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: QubitQuestDialog.borderColor,
        ),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _NotebookAttentionBadge extends StatelessWidget {
  const _NotebookAttentionBadge({
    required this.visible,
    required this.child,
  });

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (visible)
          Positioned(
            top: -1,
            right: -1,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD54F),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00030A),
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ConceptCheckCard extends StatelessWidget {
  const _ConceptCheckCard({
    required this.badgeLabel,
    required this.title,
    required this.conceptIntro,
    required this.taskDescription,
    required this.options,
    required this.selected,
    required this.answered,
    required this.correctOptionIndex,
    required this.onSelected,
  });

  final String badgeLabel;
  final String title;
  final String? conceptIntro;
  final String taskDescription;
  final List<String> options;
  final int? selected;
  final bool answered;
  final int correctOptionIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: QubitQuestDialog.panelColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: QubitQuestDialog.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.36),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: QubitQuestDialog.cyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: QubitQuestDialog.borderColor),
                  ),
                  child: const Icon(
                    Icons.psychology_alt_outlined,
                    color: QubitQuestDialog.cyan,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ConceptBadge(label: badgeLabel),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          height: 1.08,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if ((conceptIntro ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _Callout(text: conceptIntro!),
            ],
            const SizedBox(height: 18),
            const Text(
              'Question',
              style: TextStyle(
                color: QubitQuestDialog.mutedText,
                fontSize: 12,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            LatexText(
              math: taskDescription,
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.38,
              ),
              inlineMathHeight: 22,
            ),
            const SizedBox(height: 20),
            for (int idx = 0; idx < options.length; idx++) ...[
              _OptionCard(
                index: idx,
                text: options[idx],
                selected: selected == idx,
                correct: idx == correctOptionIndex,
                answered: answered,
                onTap: answered ? null : () => onSelected(idx),
              ),
              if (idx < options.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConceptBadge extends StatelessWidget {
  const _ConceptBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: QubitQuestDialog.purple.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: QubitQuestDialog.purple.withValues(alpha: 0.42),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: const TextStyle(
            color: QubitQuestDialog.purple,
            fontSize: 12,
            letterSpacing: 0.4,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: QubitQuestDialog.innerColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: QubitQuestDialog.borderSoftColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.lightbulb_outline,
              color: QubitQuestDialog.cyan,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFFD6E3F8),
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.index,
    required this.text,
    required this.selected,
    required this.correct,
    required this.answered,
    required this.onTap,
  });

  final int index;
  final String text;
  final bool selected;
  final bool correct;
  final bool answered;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = answered && correct
        ? const Color(0xFF7CFFB2)
        : answered && selected
            ? const Color(0xFFFF7A7A)
            : selected
                ? QubitQuestDialog.purple
                : QubitQuestDialog.cyan;
    final bool highlighted = selected || (answered && correct);

    Widget? trailing;
    if (answered && correct) {
      trailing = const Icon(Icons.check_circle, color: Color(0xFF7CFFB2));
    } else if (answered && selected) {
      trailing = const Icon(Icons.cancel, color: Color(0xFFFF7A7A));
    }

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: highlighted
                ? accent.withValues(alpha: 0.12)
                : QubitQuestDialog.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlighted
                  ? accent.withValues(alpha: 0.70)
                  : QubitQuestDialog.borderSoftColor,
              width: highlighted ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: highlighted ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: accent.withValues(alpha: 0.36)),
                ),
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(
                    color:
                        highlighted ? Colors.white : QubitQuestDialog.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.38,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({required this.correct, required this.text});

  final bool correct;
  final String text;

  @override
  Widget build(BuildContext context) {
    final accent = correct ? const Color(0xFF7CFFB2) : const Color(0xFFFFD54F);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: QubitQuestDialog.panelColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.38)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              correct ? Icons.verified_outlined : Icons.info_outline,
              color: accent,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFFD6E3F8),
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
