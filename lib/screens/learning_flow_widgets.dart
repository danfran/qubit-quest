import 'package:flutter/material.dart';
import 'package:quantumquiz/models/discovery_progress.dart';
import 'package:quantumquiz/models/bloch_explorer_model.dart';
import 'package:quantumquiz/models/executable_notebook_catalog.dart';
import 'package:quantumquiz/models/executable_notebook_example.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/notebook_entry.dart';
import 'package:quantumquiz/models/notebook_search.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/utils/quantum_state_formatter.dart';
import 'package:quantumquiz/widgets/qubit_quest_dialog.dart';
import 'package:quantumquiz/widgets/executable_notebook_example_view.dart';
import 'package:quantumquiz/widgets/notebook_typography.dart';
import 'package:quantumquiz/screens/bloch_explorer_screen.dart';
import 'package:quantumquiz/screens/quantum_composer.dart';

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

class ChapterCompleteScreen extends StatelessWidget {
  const ChapterCompleteScreen({
    super.key,
    required this.chapterTitle,
    required this.chapterIdentity,
  });

  final String chapterTitle;
  final String chapterIdentity;

  @override
  Widget build(BuildContext context) {
    return _LearningScaffold(
      child: _LearningCard(
        title: 'Chapter Complete',
        body: '',
        icon: Icons.flag_circle_outlined,
        actions: [
          QubitQuestDialogButton.secondary(
            label: 'Review Notebook',
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (context) => const DiscoveriesScreen(),
                ),
              );
            },
          ),
          QubitQuestDialogButton.primary(
            label: 'Continue Journey',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
        child: _ChapterCompleteBody(
          chapterTitle: chapterTitle,
          chapterIdentity: chapterIdentity,
        ),
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
      title: 'Discovery Complete',
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
          label: 'Continue Journey',
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
  bool _searching = false;
  String _searchQuery = '';
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  late final NotebookSearchIndex _searchIndex;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _searchIndex = NotebookSearchIndex.build(
      entries: notebookEntries,
      executableExamples: executableNotebookExamples,
    );
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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
    final normalizedQuery = normalizeNotebookSearchText(_searchQuery);
    final results = normalizedQuery.isEmpty
        ? const <NotebookSearchResult>[]
        : _searchIndex.search(
            _searchQuery,
            allowedEntryIds: notebookSearchAllowedEntryIds(
              entries: notebookEntries,
              unlockedDiscoveryTitles: _unlocked,
            ),
          );
    return Scaffold(
      backgroundColor: const Color(0xFF00030A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00030A),
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: _searching
            ? TextField(
                key: const ValueKey('notebook-search-field'),
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: true,
                textInputAction: TextInputAction.search,
                style: const TextStyle(color: Colors.white, fontSize: 17),
                decoration: const InputDecoration(
                  hintText: 'Search Notebook',
                  hintStyle: TextStyle(color: QubitQuestDialog.mutedText),
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : const Text(
                'Quantum Notebook',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
        actions: [
          if (!_searching)
            IconButton(
              key: const ValueKey('open-notebook-search'),
              tooltip: 'Search Notebook',
              onPressed: () {
                setState(() => _searching = true);
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _searchFocusNode.requestFocus(),
                );
              },
              icon: const Icon(Icons.search_rounded),
            )
          else ...[
            if (_searchQuery.isNotEmpty)
              IconButton(
                key: const ValueKey('clear-notebook-search'),
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                  _searchFocusNode.requestFocus();
                },
                icon: const Icon(Icons.clear_rounded),
              ),
          ],
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : normalizedQuery.isNotEmpty
                ? _NotebookSearchResults(
                    query: _searchQuery,
                    results: results,
                    onOpen: (entry) {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (context) =>
                              NotebookEntryScreen(entry: entry),
                        ),
                      );
                    },
                  )
                : ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      for (final chapter in _notebookChapters()) ...[
                        _NotebookChapterHeader(
                          title: chapter.title,
                          identity: chapter.identity,
                          unlockedCount: chapter.entries
                              .where(
                                (entry) =>
                                    isNotebookEntryAvailable(entry, _unlocked),
                              )
                              .length,
                          totalCount: chapter.entries.length,
                        ),
                        const SizedBox(height: 10),
                        for (final entry in chapter.entries) ...[
                          _NotebookEntryTile(
                            entry: entry,
                            unlocked:
                                isNotebookEntryAvailable(entry, _unlocked),
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

class _NotebookSearchResults extends StatelessWidget {
  const _NotebookSearchResults({
    required this.query,
    required this.results,
    required this.onOpen,
  });

  final String query;
  final List<NotebookSearchResult> results;
  final ValueChanged<NotebookEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            'No Notebook entries found for “${query.trim()}”.',
            key: const ValueKey('notebook-search-empty'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: QubitQuestDialog.mutedText,
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      key: const ValueKey('notebook-search-results'),
      padding: const EdgeInsets.all(18),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final result = results[index];
        return Semantics(
          button: true,
          label: 'Open ${result.entry.title}',
          child: InkWell(
            key: ValueKey('notebook-search-result-${result.entry.id}'),
            onTap: () => onOpen(result.entry),
            borderRadius: BorderRadius.circular(12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: QubitQuestDialog.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: QubitQuestDialog.cyan.withValues(alpha: 0.38),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.menu_book_outlined,
                        color: QubitQuestDialog.cyan,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.entry.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            result.entry.chapterTitle,
                            style: const TextStyle(
                              color: QubitQuestDialog.cyan,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            result.snippet,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFD6E3F8),
                              fontSize: 13,
                              height: 1.3,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: QubitQuestDialog.mutedText,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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

  List<ExecutableNotebookExample> get _executableExamples => [
        for (final id in widget.entry.executableExampleIds)
          if (executableNotebookExamplesById[id] case final example?) example,
      ];

  void _openExampleInComposer(ExecutableNotebookExample example) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => QuantumComposer(
          levelId: -1,
          level: example.createEditableComposerLevel(),
          onLevelUnlocked: null,
          sessionOwnership: ComposerSessionOwnership.temporary,
        ),
      ),
    );
  }

  void _openExampleInBloch(
    ExecutableNotebookExample example,
    ExecutableNotebookResult result,
  ) {
    final state = result.state;
    if (example.qubitCount != 1 || state.length != 2) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => BlochExplorerScreen(
          initialState: BlochState.fromAmplitudes(state[0], state[1]),
        ),
      ),
    );
  }

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
        title: Text(
          'Quantum Notebook',
          style: NotebookTypography.text(
            NotebookTextRole.pageTitle,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              widget.entry.chapterTitle,
              style: NotebookTypography.text(
                NotebookTextRole.context,
                color: QubitQuestDialog.mutedText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.entry.title,
              style: NotebookTypography.text(
                NotebookTextRole.entryTitle,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _formatNotebookDisplayText(widget.entry.summary),
              style: NotebookTypography.text(
                NotebookTextRole.lead,
                color: const Color(0xFFD6E3F8),
              ),
            ),
            const SizedBox(height: 18),
            if (keyExamples.isNotEmpty) ...[
              _NotebookKeyExamples(examples: keyExamples),
              const SizedBox(height: 12),
            ],
            if (_executableExamples.isNotEmpty) ...[
              Text(
                'Try it',
                style: NotebookTypography.text(
                  NotebookTextRole.sectionHeading,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              for (final example in _executableExamples) ...[
                ExecutableNotebookExampleView(
                  example: example,
                  onOpenInComposer: _openExampleInComposer,
                  onOpenInBlochExplorer: _openExampleInBloch,
                ),
                const SizedBox(height: 12),
              ],
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
    return Padding(
      key: ValueKey('notebook-section-${section.title}'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            section.title,
            style: NotebookTypography.text(
              NotebookTextRole.sectionHeading,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 7),
          _NotebookBodyText(section.body),
        ],
      ),
    );
  }
}

class _NotebookKeyExamples extends StatelessWidget {
  const _NotebookKeyExamples({required this.examples});

  final List<NotebookExample> examples;

  @override
  Widget build(BuildContext context) {
    final blocks = <Widget>[];
    var index = 0;
    while (index < examples.length) {
      final example = examples[index];
      final group = example.comparisonGroup;
      if (group != null) {
        final grouped = <NotebookExample>[];
        while (index < examples.length &&
            examples[index].comparisonGroup == group) {
          grouped.add(examples[index]);
          index++;
        }
        blocks.add(_NotebookExampleComparison(examples: grouped));
      } else {
        blocks.add(_NotebookExampleBlock(example: example));
        index++;
      }
    }

    return Column(
      key: const ValueKey('notebook-key-examples'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Key Examples',
          style: NotebookTypography.text(
            NotebookTextRole.sectionHeading,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < blocks.length; index++) ...[
          blocks[index],
          if (index != blocks.length - 1)
            Divider(
              height: 17,
              color: QubitQuestDialog.borderSoftColor.withValues(alpha: 0.65),
            ),
        ],
      ],
    );
  }
}

class _NotebookExampleBlock extends StatelessWidget {
  const _NotebookExampleBlock({required this.example});

  final NotebookExample example;

  @override
  Widget build(BuildContext context) {
    final isMath = example.presentation == NotebookExamplePresentation.math;

    return Padding(
      key: ValueKey('notebook-example-${example.label}'),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            example.label,
            style: NotebookTypography.text(
              NotebookTextRole.subsection,
              color: isMath ? QubitQuestDialog.cyan : const Color(0xFFD6E3F8),
            ),
          ),
          const SizedBox(height: 4),
          if (isMath)
            NotebookMathEvidence(example: example)
          else
            Text(
              _formatNotebookDisplayText(example.notation),
              style: NotebookTypography.text(
                NotebookTextRole.lead,
                color: Colors.white,
              ),
            ),
          if ((example.explanation ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              _formatNotebookDisplayText(example.explanation!),
              style: NotebookTypography.text(
                NotebookTextRole.supporting,
                color: const Color(0xFFD6E3F8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotebookExampleComparison extends StatelessWidget {
  const _NotebookExampleComparison({required this.examples});

  final List<NotebookExample> examples;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useColumns = constraints.maxWidth >= 430 && examples.length == 2;
        if (!useColumns) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < examples.length; index++) ...[
                _NotebookExampleBlock(example: examples[index]),
                if (index != examples.length - 1) const SizedBox(height: 8),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < examples.length; index++) ...[
              Expanded(child: _NotebookExampleBlock(example: examples[index])),
              if (index != examples.length - 1) const SizedBox(width: 20),
            ],
          ],
        );
      },
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
        style: NotebookTypography.text(
          NotebookTextRole.body,
          color: const Color(0xFFD6E3F8),
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
            style: NotebookTypography.text(
              NotebookTextRole.body,
              color: const Color(0xFFD6E3F8),
            ),
          ),
          const SizedBox(height: 10),
        ],
        const _NotebookWarningCallout(text: _warning),
        if (after.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            after,
            style: NotebookTypography.text(
              NotebookTextRole.body,
              color: const Color(0xFFD6E3F8),
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
            style: NotebookTypography.text(
              NotebookTextRole.sectionHeading,
              color: Colors.white,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _formatNotebookDisplayText(section.body),
                style: NotebookTypography.text(
                  NotebookTextRole.body,
                  color: const Color(0xFFD6E3F8),
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
  return formatQuantumNotationForPlainText(value);
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
    this.child,
  });

  final String title;
  final String body;
  final IconData icon;
  final List<Widget> actions;
  final Widget? child;

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
            if (child != null) ...[
              const SizedBox(height: 16),
              child!,
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

class _ChapterCompleteBody extends StatelessWidget {
  const _ChapterCompleteBody({
    required this.chapterTitle,
    required this.chapterIdentity,
  });

  final String chapterTitle;
  final String chapterIdentity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
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
                Text(
                  chapterTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (chapterIdentity.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    chapterIdentity,
                    style: const TextStyle(
                      color: QubitQuestDialog.mutedText,
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: QubitQuestDialog.cyan.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: QubitQuestDialog.cyan.withValues(alpha: 0.34),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  color: QubitQuestDialog.cyan,
                  size: 22,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'All discoveries unlocked. Your Quantum Notebook has the chapter synthesis ready for review.',
                    style: TextStyle(
                      color: Color(0xFFD6E3F8),
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
