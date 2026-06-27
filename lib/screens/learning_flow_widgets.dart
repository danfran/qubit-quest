import 'package:flutter/material.dart';
import 'package:quantumquiz/models/discovery_progress.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/notebook_entry.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/widgets/qubit_quest_dialog.dart';

class ChapterIntroScreen extends StatelessWidget {
  const ChapterIntroScreen({
    super.key,
    required this.title,
    required this.text,
    this.buttonLabel = 'Begin',
  });

  final String title;
  final String text;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return _LearningScaffold(
      child: _LearningCard(
        title: title,
        body: text,
        icon: Icons.auto_stories_outlined,
        actions: [
          QubitQuestDialogButton.primary(
            label: buttonLabel,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class MysteryPanel extends StatelessWidget {
  const MysteryPanel({
    super.key,
    required this.level,
  });

  final QQLevel level;

  @override
  Widget build(BuildContext context) {
    return _LearningScaffold(
      child: _LearningCard(
        title: level.mysteryTitle ?? 'Mystery',
        body: level.mysteryText ?? '',
        icon: Icons.travel_explore_outlined,
        actions: [
          QubitQuestDialogButton.primary(
            label: 'Experiment',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class DiscoveryDialog extends StatelessWidget {
  const DiscoveryDialog({
    super.key,
    required this.level,
  });

  final QQLevel level;

  @override
  Widget build(BuildContext context) {
    final discoveryTitle = level.discoveryTitle?.trim();
    final notebookEntry = discoveryTitle == null
        ? null
        : notebookEntriesByDiscoveryTitle[discoveryTitle];

    return QubitQuestDialog(
      title: '✓ Level Complete',
      maxWidth: 560,
      actions: [
        if (notebookEntry != null)
          QubitQuestDialogButton.secondary(
            label: 'Open Notebook',
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (context) =>
                      NotebookEntryScreen(entry: notebookEntry),
                ),
              );
            },
          ),
        QubitQuestDialogButton.primary(
          label: 'Next Level',
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if ((level.discoveryTitle ?? '').trim().isNotEmpty) ...[
            Text(
              level.discoveryTitle!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                height: 1.14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
          ],
          if ((level.discoveryText ?? '').trim().isNotEmpty)
            _LearningText(level.discoveryText!),
          if ((level.keyInsight ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _InsightBox(text: level.keyInsight!),
          ],
          if (notebookEntry != null) ...[
            const SizedBox(height: 12),
            _NotebookUpdatedBox(title: notebookEntry.title),
          ],
        ],
      ),
    );
  }
}

class DiscoveriesScreen extends StatefulWidget {
  const DiscoveriesScreen({
    super.key,
    this.onStartPrototypeLevel,
    this.prototypeLevelNumber,
    this.prototypeChapters = const [],
  });

  final Future<void> Function(int levelNumber)? onStartPrototypeLevel;
  final int? prototypeLevelNumber;
  final List<DiscoveryPrototypeChapter> prototypeChapters;

  @override
  State<DiscoveriesScreen> createState() => _DiscoveriesScreenState();
}

class _DiscoveriesScreenState extends State<DiscoveriesScreen> {
  Set<String> _unlocked = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final unlocked = await DiscoveryProgress.loadUnlocked();
    if (!mounted) return;
    setState(() {
      _unlocked = unlocked;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00030A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00030A),
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          'Quantum Notebook',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  for (final chapter in _notebookChapters()) ...[
                    _NotebookChapterHeader(
                      title: chapter.title,
                      identity: chapter.identity,
                      unlockedCount: chapter.entries
                          .where((entry) =>
                              _unlocked.contains(entry.discoveryTitle))
                          .length,
                      totalCount: chapter.entries.length,
                    ),
                    const SizedBox(height: 10),
                    for (final entry in chapter.entries) ...[
                      _NotebookEntryTile(
                        entry: entry,
                        unlocked: _unlocked.contains(entry.discoveryTitle),
                        onTap: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (context) =>
                                  NotebookEntryScreen(entry: entry),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 12),
                  ],
                ],
              ),
      ),
    );
  }

  List<_NotebookChapterGroup> _notebookChapters() {
    final Map<String, List<NotebookEntry>> grouped = {};
    for (final entry in notebookEntries) {
      grouped.putIfAbsent(entry.chapterTitle, () => []).add(entry);
    }

    return grouped.entries
        .map(
          (entry) => _NotebookChapterGroup(
            title: entry.key,
            identity: entry.value.first.chapterIdentity,
            entries: entry.value,
          ),
        )
        .toList()
      ..sort(
        (a, b) => a.entries.first.chapterIndex
            .compareTo(b.entries.first.chapterIndex),
      );
  }
}

class _NotebookChapterGroup {
  const _NotebookChapterGroup({
    required this.title,
    required this.identity,
    required this.entries,
  });

  final String title;
  final String identity;
  final List<NotebookEntry> entries;
}

class NotebookEntryScreen extends StatefulWidget {
  const NotebookEntryScreen({
    super.key,
    required this.entry,
  });

  final NotebookEntry entry;

  @override
  State<NotebookEntryScreen> createState() => _NotebookEntryScreenState();
}

class _NotebookEntryScreenState extends State<NotebookEntryScreen> {
  Set<String> _unlocked = const {};
  bool _loadingUnlocks = true;

  @override
  void initState() {
    super.initState();
    DiscoveryProgress.markNotebookEntryOpened(widget.entry.discoveryTitle);
    _loadUnlocks();
  }

  Future<void> _loadUnlocks() async {
    final unlocked = await DiscoveryProgress.loadUnlocked();
    if (!mounted) return;
    setState(() {
      _unlocked = unlocked;
      _loadingUnlocks = false;
    });
  }

  NotebookEntry? get _nextEntry {
    if (_loadingUnlocks) return null;

    final chapterEntries = _chapterEntries;
    final currentIndex = chapterEntries.indexWhere(
      (entry) => entry.discoveryTitle == widget.entry.discoveryTitle,
    );
    if (currentIndex < 0 || currentIndex + 1 >= chapterEntries.length) {
      return null;
    }

    final candidate = chapterEntries[currentIndex + 1];
    return _unlocked.contains(candidate.discoveryTitle) ? candidate : null;
  }

  NotebookEntry? get _previousEntry {
    if (_loadingUnlocks) return null;

    final chapterEntries = _chapterEntries;
    final currentIndex = chapterEntries.indexWhere(
      (entry) => entry.discoveryTitle == widget.entry.discoveryTitle,
    );
    if (currentIndex <= 0) {
      return null;
    }

    final candidate = chapterEntries[currentIndex - 1];
    return _unlocked.contains(candidate.discoveryTitle) ? candidate : null;
  }

  List<NotebookEntry> get _chapterEntries => notebookEntries
      .where((entry) => entry.chapterIndex == widget.entry.chapterIndex)
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final previousEntry = _previousEntry;
    final nextEntry = _nextEntry;
    final keyExamples = _keyExamples;

    return Scaffold(
      backgroundColor: const Color(0xFF00030A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00030A),
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          'Quantum Notebook',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              widget.entry.chapterTitle,
              style: const TextStyle(
                color: QubitQuestDialog.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.entry.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                height: 1.08,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _formatNotebookDisplayText(widget.entry.summary),
              style: const TextStyle(
                color: Color(0xFFD6E3F8),
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            if (keyExamples.isNotEmpty) ...[
              _NotebookKeyExamples(examples: keyExamples),
              const SizedBox(height: 12),
            ],
            _NotebookSectionCard(section: widget.entry.intuition),
            if (widget.entry.whatChanged != null) ...[
              const SizedBox(height: 12),
              _NotebookSectionCard(section: widget.entry.whatChanged!),
            ],
            if (widget.entry.quantumView != null) ...[
              const SizedBox(height: 12),
              _NotebookSectionCard(section: widget.entry.quantumView!),
            ],
            if (widget.entry.advancedNotes != null) ...[
              const SizedBox(height: 12),
              _AdvancedNotebookSection(section: widget.entry.advancedNotes!),
            ],
            if (widget.entry.relatedDiscoveryTitles.isNotEmpty) ...[
              const SizedBox(height: 12),
              _RelatedDiscoveries(
                titles: widget.entry.relatedDiscoveryTitles,
                unlocked: _unlocked,
              ),
            ],
            if (previousEntry != null || nextEntry != null) ...[
              const SizedBox(height: 14),
              _NotebookEntryNavigationRow(
                previousEntry: previousEntry,
                nextEntry: nextEntry,
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<NotebookExample> get _keyExamples => [
        ...widget.entry.intuition.examples,
        ...?widget.entry.whatChanged?.examples,
        ...?widget.entry.quantumView?.examples,
      ];
}

class _NotebookEntryNavigationRow extends StatelessWidget {
  const _NotebookEntryNavigationRow({
    required this.previousEntry,
    required this.nextEntry,
  });

  final NotebookEntry? previousEntry;
  final NotebookEntry? nextEntry;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runAlignment: WrapAlignment.spaceBetween,
      spacing: 10,
      runSpacing: 10,
      children: [
        if (previousEntry != null)
          _NotebookEntryNavigationLink(
            entry: previousEntry!,
            label: 'Previous: ${previousEntry!.title}',
            icon: Icons.chevron_left_rounded,
          )
        else
          const SizedBox.shrink(),
        if (nextEntry != null)
          _NotebookEntryNavigationLink(
            entry: nextEntry!,
            label: 'Next: ${nextEntry!.title}',
            icon: Icons.chevron_right_rounded,
          ),
      ],
    );
  }
}

class _NotebookEntryNavigationLink extends StatelessWidget {
  const _NotebookEntryNavigationLink({
    required this.entry,
    required this.label,
    required this.icon,
  });

  final NotebookEntry entry;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: QubitQuestDialog.cyan.withValues(alpha: 0.10),
        side: BorderSide(
          color: QubitQuestDialog.cyan.withValues(alpha: 0.32),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
      onPressed: () {
        Navigator.of(context).pushReplacement<void, void>(
          MaterialPageRoute(
            builder: (context) => NotebookEntryScreen(entry: entry),
          ),
        );
      },
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

class _NotebookSectionCard extends StatelessWidget {
  const _NotebookSectionCard({required this.section});

  final NotebookSection section;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: QubitQuestDialog.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: QubitQuestDialog.borderSoftColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              section.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            _NotebookBodyText(section.body),
          ],
        ),
      ),
    );
  }
}

class _NotebookKeyExamples extends StatelessWidget {
  const _NotebookKeyExamples({required this.examples});

  final List<NotebookExample> examples;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: QubitQuestDialog.innerColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: QubitQuestDialog.cyan.withValues(alpha: 0.28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Key Examples',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            for (final example in examples) ...[
              _NotebookExampleBlock(example: example),
              if (example != examples.last) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotebookExampleBlock extends StatelessWidget {
  const _NotebookExampleBlock({required this.example});

  final NotebookExample example;

  _NotebookExampleKind get _kind {
    final notation = example.notation;
    if (notation.contains('P(') || example.label.contains('Measurement')) {
      return _NotebookExampleKind.probability;
    }
    if (notation.contains('→')) {
      return _NotebookExampleKind.transformation;
    }
    if (notation.contains('=')) {
      return _NotebookExampleKind.formula;
    }
    return _NotebookExampleKind.state;
  }

  @override
  Widget build(BuildContext context) {
    final kind = _kind;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: kind.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kind.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: kind.accentColor.withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const SizedBox(width: 4),
              ),
              const SizedBox(width: 10),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: kind.accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: kind.accentColor.withValues(alpha: 0.32),
                  ),
                ),
                child: Icon(kind.icon, size: 16, color: kind.accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            example.label,
                            style: TextStyle(
                              color: kind.accentColor,
                              fontSize: 11,
                              letterSpacing: 0.2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          kind.displayLabel,
                          style: TextStyle(
                            color: kind.accentColor.withValues(alpha: 0.78),
                            fontSize: 10,
                            letterSpacing: 0.4,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    SelectableText(
                      _formatNotebookDisplayText(example.notation),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.35,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if ((example.explanation ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        _formatNotebookDisplayText(example.explanation!),
                        style: const TextStyle(
                          color: Color(0xFFD6E3F8),
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotebookBodyText extends StatelessWidget {
  const _NotebookBodyText(this.text);

  static const _warning = 'This is not entanglement.';

  final String text;

  @override
  Widget build(BuildContext context) {
    final formattedText = _formatNotebookDisplayText(text);
    final warningIndex = formattedText.indexOf(_warning);
    if (warningIndex < 0) {
      return Text(
        formattedText,
        style: const TextStyle(
          color: Color(0xFFD6E3F8),
          fontSize: 14,
          height: 1.42,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final before = formattedText.substring(0, warningIndex).trimRight();
    final after =
        formattedText.substring(warningIndex + _warning.length).trimLeft();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (before.isNotEmpty) ...[
          Text(
            before,
            style: const TextStyle(
              color: Color(0xFFD6E3F8),
              fontSize: 14,
              height: 1.42,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
        ],
        const _NotebookWarningCallout(text: _warning),
        if (after.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            after,
            style: const TextStyle(
              color: Color(0xFFD6E3F8),
              fontSize: 14,
              height: 1.42,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _NotebookWarningCallout extends StatelessWidget {
  const _NotebookWarningCallout({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFD54F).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFFD54F).withValues(alpha: 0.34),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFFFD54F),
              size: 17,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _NotebookExampleKind {
  state,
  formula,
  probability,
  transformation;

  Color get accentColor {
    switch (this) {
      case _NotebookExampleKind.probability:
        return const Color(0xFFFFD54F);
      case _NotebookExampleKind.transformation:
        return const Color(0xFF7CFFB2);
      case _NotebookExampleKind.formula:
        return QubitQuestDialog.cyan;
      case _NotebookExampleKind.state:
        return const Color(0xFFD6E3F8);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case _NotebookExampleKind.probability:
        return const Color(0xFFFFD54F).withValues(alpha: 0.08);
      case _NotebookExampleKind.transformation:
        return const Color(0xFF7CFFB2).withValues(alpha: 0.07);
      case _NotebookExampleKind.formula:
        return QubitQuestDialog.cyan.withValues(alpha: 0.08);
      case _NotebookExampleKind.state:
        return QubitQuestDialog.cardColor;
    }
  }

  Color get borderColor => accentColor.withValues(alpha: 0.24);

  IconData get icon {
    switch (this) {
      case _NotebookExampleKind.probability:
        return Icons.percent_rounded;
      case _NotebookExampleKind.transformation:
        return Icons.trending_flat_rounded;
      case _NotebookExampleKind.formula:
        return Icons.functions_rounded;
      case _NotebookExampleKind.state:
        return Icons.memory_rounded;
    }
  }

  String get displayLabel {
    switch (this) {
      case _NotebookExampleKind.probability:
        return 'PROBABILITY';
      case _NotebookExampleKind.transformation:
        return 'TRANSFORM';
      case _NotebookExampleKind.formula:
        return 'FORMULA';
      case _NotebookExampleKind.state:
        return 'STATE';
    }
  }
}

class _AdvancedNotebookSection extends StatelessWidget {
  const _AdvancedNotebookSection({required this.section});

  final NotebookSection section;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: QubitQuestDialog.innerColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: QubitQuestDialog.borderSoftColor),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          iconColor: QubitQuestDialog.cyan,
          collapsedIconColor: QubitQuestDialog.mutedText,
          title: Text(
            section.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _formatNotebookDisplayText(section.body),
                style: const TextStyle(
                  color: Color(0xFFD6E3F8),
                  fontSize: 14,
                  height: 1.42,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RelatedDiscoveries extends StatelessWidget {
  const _RelatedDiscoveries({
    required this.titles,
    required this.unlocked,
  });

  final List<String> titles;
  final Set<String> unlocked;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Related Discoveries',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Open unlocked links to follow the idea.',
              style: TextStyle(
                color: QubitQuestDialog.mutedText,
                fontSize: 12,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final title in titles)
                  _RelatedDiscoveryChip(
                    title: title,
                    entry: notebookEntriesByDiscoveryTitle[title],
                    unlocked: unlocked.contains(title),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RelatedDiscoveryChip extends StatelessWidget {
  const _RelatedDiscoveryChip({
    required this.title,
    required this.entry,
    required this.unlocked,
  });

  final String title;
  final NotebookEntry? entry;
  final bool unlocked;

  bool get _canOpen => unlocked && entry != null;

  @override
  Widget build(BuildContext context) {
    final foreground =
        _canOpen ? const Color(0xFFD6E3F8) : QubitQuestDialog.mutedText;

    return InkWell(
      onTap: _canOpen
          ? () {
              Navigator.of(context).pushReplacement<void, void>(
                MaterialPageRoute(
                  builder: (context) => NotebookEntryScreen(entry: entry!),
                ),
              );
            }
          : null,
      borderRadius: BorderRadius.circular(999),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _canOpen
              ? QubitQuestDialog.cardColor
              : QubitQuestDialog.innerColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: _canOpen
                ? QubitQuestDialog.cyan.withValues(alpha: 0.32)
                : QubitQuestDialog.borderSoftColor,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_canOpen) ...[
                Icon(Icons.lock_outline_rounded, size: 12, color: foreground),
                const SizedBox(width: 5),
              ],
              Text(
                _formatNotebookDisplayText(title),
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (_canOpen) ...[
                const SizedBox(width: 3),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: QubitQuestDialog.mutedText,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _formatNotebookDisplayText(String value) {
  return value
      .replaceAllMapped(
        RegExp(r'\|([01+\-−]+)>'),
        (match) => '|${match.group(1)!.replaceAll('-', '−')}⟩',
      )
      .replaceAll(r'\sqrt{2}', '√2')
      .replaceAll('sqrt(2)', '√2')
      .replaceAll('sqrt2', '√2')
      .replaceAll('->', '→');
}

class DiscoveryPrototypeChapter {
  const DiscoveryPrototypeChapter({
    required this.title,
    required this.subtitle,
    required this.levelNumber,
  });

  final String title;
  final String subtitle;
  final int levelNumber;
}

class _LearningScaffold extends StatelessWidget {
  const _LearningScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00030A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _LearningCard extends StatelessWidget {
  const _LearningCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.actions,
  });

  final String title;
  final String body;
  final IconData icon;
  final List<Widget> actions;

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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: QubitQuestDialog.cyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: QubitQuestDialog.borderColor),
                  ),
                  child: Icon(icon, color: QubitQuestDialog.cyan, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
            if (body.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _LearningText(body),
            ],
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 8,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}

class _LearningText extends StatelessWidget {
  const _LearningText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFD6E3F8),
        fontSize: 15,
        height: 1.45,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _InsightBox extends StatelessWidget {
  const _InsightBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: QubitQuestDialog.purple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: QubitQuestDialog.purple.withValues(alpha: 0.42),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _NotebookUpdatedBox extends StatelessWidget {
  const _NotebookUpdatedBox({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: QubitQuestDialog.innerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QubitQuestDialog.borderSoftColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.38),
                ),
              ),
              child: const Icon(
                Icons.star_rounded,
                color: Color(0xFFFFD54F),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Notebook Updated',
                    style: TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 12,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$title is saved with deeper notes and examples.',
                    style: const TextStyle(
                      color: Color(0xFFD6E3F8),
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotebookChapterHeader extends StatelessWidget {
  const _NotebookChapterHeader({
    required this.title,
    required this.identity,
    required this.unlockedCount,
    required this.totalCount,
  });

  final String title;
  final String identity;
  final int unlockedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (identity.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    identity,
                    style: const TextStyle(
                      color: QubitQuestDialog.mutedText,
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              color: QubitQuestDialog.innerColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: QubitQuestDialog.borderSoftColor),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(
                '$unlockedCount / $totalCount discovered',
                style: const TextStyle(
                  color: QubitQuestDialog.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotebookEntryTile extends StatelessWidget {
  const _NotebookEntryTile({
    required this.entry,
    required this.unlocked,
    required this.onTap,
  });

  final NotebookEntry entry;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: unlocked ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: unlocked
              ? QubitQuestDialog.cardColor
              : QubitQuestDialog.innerColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: unlocked
                ? QubitQuestDialog.cyan.withValues(alpha: 0.38)
                : QubitQuestDialog.borderSoftColor,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(
                unlocked
                    ? Icons.menu_book_outlined
                    : Icons.lock_outline_rounded,
                color: unlocked
                    ? QubitQuestDialog.cyan
                    : QubitQuestDialog.mutedText,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unlocked ? entry.title : 'Undiscovered',
                      style: TextStyle(
                        color: unlocked
                            ? Colors.white
                            : QubitQuestDialog.mutedText,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unlocked
                          ? entry.summary
                          : 'Complete this discovery to unlock its notebook entry.',
                      style: TextStyle(
                        color: unlocked
                            ? const Color(0xFFD6E3F8)
                            : QubitQuestDialog.mutedText,
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (unlocked)
                const Icon(
                  Icons.chevron_right,
                  color: QubitQuestDialog.mutedText,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
