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
    final prototypeChapters = [
      if (widget.prototypeLevelNumber != null)
        DiscoveryPrototypeChapter(
          title: 'Chapter 4',
          subtitle: 'Start Interference',
          levelNumber: widget.prototypeLevelNumber!,
        ),
      ...widget.prototypeChapters,
    ];

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
                  if (widget.onStartPrototypeLevel != null &&
                      prototypeChapters.isNotEmpty) ...[
                    for (final chapter in prototypeChapters) ...[
                      _PrototypeChapterCard(
                        title: chapter.title,
                        subtitle: chapter.subtitle,
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await widget.onStartPrototypeLevel!(
                            chapter.levelNumber,
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 14),
                  ],
                  for (final chapter in _notebookChapters()) ...[
                    _NotebookChapterHeader(
                      title: chapter.title,
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
    required this.entries,
  });

  final String title;
  final List<NotebookEntry> entries;
}

class NotebookEntryScreen extends StatelessWidget {
  const NotebookEntryScreen({
    super.key,
    required this.entry,
  });

  final NotebookEntry entry;

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
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              entry.chapterTitle,
              style: const TextStyle(
                color: QubitQuestDialog.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              entry.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                height: 1.08,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              entry.summary,
              style: const TextStyle(
                color: Color(0xFFD6E3F8),
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            _NotebookSectionCard(section: entry.intuition),
            if (entry.whatChanged != null) ...[
              const SizedBox(height: 12),
              _NotebookSectionCard(section: entry.whatChanged!),
            ],
            if (entry.quantumView != null) ...[
              const SizedBox(height: 12),
              _NotebookSectionCard(section: entry.quantumView!),
            ],
            if (entry.advancedNotes != null) ...[
              const SizedBox(height: 12),
              _AdvancedNotebookSection(section: entry.advancedNotes!),
            ],
            if (entry.relatedDiscoveryTitles.isNotEmpty) ...[
              const SizedBox(height: 12),
              _RelatedDiscoveries(titles: entry.relatedDiscoveryTitles),
            ],
          ],
        ),
      ),
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
            Text(
              section.body,
              style: const TextStyle(
                color: Color(0xFFD6E3F8),
                fontSize: 14,
                height: 1.42,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (section.examples.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final example in section.examples) ...[
                _NotebookExampleBlock(example: example),
                if (example != section.examples.last) const SizedBox(height: 8),
              ],
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

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: QubitQuestDialog.innerColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: QubitQuestDialog.borderSoftColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              example.label,
              style: const TextStyle(
                color: QubitQuestDialog.mutedText,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              example.notation,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
              ),
            ),
            if ((example.explanation ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                example.explanation!,
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
    );
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
                section.body,
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
  const _RelatedDiscoveries({required this.titles});

  final List<String> titles;

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
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final title in titles)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: QubitQuestDialog.cardColor,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: QubitQuestDialog.borderSoftColor,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFFD6E3F8),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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

class _PrototypeChapterCard extends StatelessWidget {
  const _PrototypeChapterCard({
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: QubitQuestDialog.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: QubitQuestDialog.purple.withValues(alpha: 0.42),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: QubitQuestDialog.purple.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: QubitQuestDialog.borderColor),
              ),
              child: const Icon(
                Icons.science_outlined,
                color: QubitQuestDialog.purple,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFFD6E3F8),
                      fontSize: 13,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            QubitQuestDialogButton.primary(
              label: 'Start',
              onPressed: onPressed,
            ),
          ],
        ),
      ),
    );
  }
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
                    'New Discovery',
                    style: TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 12,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$title added to Quantum Notebook',
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
    required this.unlockedCount,
    required this.totalCount,
  });

  final String title;
  final int unlockedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
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
