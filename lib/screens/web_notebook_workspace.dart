import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/executable_notebook_catalog.dart';
import 'package:quantumquiz/models/executable_notebook_example.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/notebook_entry.dart';
import 'package:quantumquiz/models/notebook_search.dart';
import 'package:quantumquiz/utils/quantum_state_formatter.dart';
import 'package:quantumquiz/widgets/executable_notebook_example_view.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';

const _background = QubitQuestColors.background;
const _surface = QubitQuestColors.surface;
const _inner = Color(0xFF07101F);
const _border = QubitQuestColors.border;
const _cyan = QubitQuestColors.accentInteractive;
const _purple = QubitQuestColors.accentStrong;
const _muted = Color(0xFF9BAAC4);

class WebNotebookWorkspace extends StatefulWidget {
  const WebNotebookWorkspace({
    super.key,
    required this.progressController,
    required this.onOpenJourney,
    this.requestedDiscoveryTitle,
    this.onOpenExampleInComposer,
    this.onOpenExampleInBlochExplorer,
  });

  final CampaignProgressController progressController;
  final VoidCallback onOpenJourney;
  final String? requestedDiscoveryTitle;
  final ValueChanged<ExecutableNotebookExample>? onOpenExampleInComposer;
  final void Function(
    ExecutableNotebookExample example,
    ExecutableNotebookResult result,
  )? onOpenExampleInBlochExplorer;

  @override
  State<WebNotebookWorkspace> createState() => _WebNotebookWorkspaceState();
}

class _WebNotebookWorkspaceState extends State<WebNotebookWorkspace> {
  static const double _twoPaneBreakpoint = 880;
  late final TextEditingController _searchController;
  late final NotebookSearchIndex _searchIndex;
  NotebookEntry? _selectedEntry;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchIndex = NotebookSearchIndex.build(
      entries: notebookEntries,
      executableExamples: executableNotebookExamples,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _honorRequest());
  }

  @override
  void didUpdateWidget(covariant WebNotebookWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requestedDiscoveryTitle != widget.requestedDiscoveryTitle) {
      _honorRequest();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Set<String> get _unlocked =>
      widget.progressController.unlockedDiscoveryTitles();

  bool _isUnlocked(NotebookEntry entry) =>
      isNotebookEntryAvailable(entry, _unlocked);

  void _honorRequest() {
    final title = widget.requestedDiscoveryTitle;
    if (!mounted || title == null || !widget.progressController.isLoaded) {
      return;
    }
    final entry = notebookEntriesByDiscoveryTitle[title];
    if (entry != null && _isUnlocked(entry)) {
      _clearSearch(rebuild: false);
      _selectEntry(entry);
    }
  }

  void _selectEntry(NotebookEntry entry) {
    if (!_isUnlocked(entry)) return;
    setState(() => _selectedEntry = entry);
    unawaited(
      widget.progressController.markNotebookEntryOpened(entry.discoveryTitle),
    );
  }

  void _selectSearchResult(NotebookEntry entry) {
    if (!_isUnlocked(entry)) return;
    _clearSearch(rebuild: false);
    _selectEntry(entry);
  }

  void _clearSearch({bool rebuild = true}) {
    _searchController.clear();
    if (rebuild) {
      setState(() => _query = '');
    } else {
      _query = '';
    }
  }

  List<NotebookSearchResult> get _results {
    if (normalizeNotebookSearchText(_query).isEmpty) return const [];
    return _searchIndex.search(
      _query,
      allowedEntryIds: notebookSearchAllowedEntryIds(
        entries: notebookEntries,
        unlockedDiscoveryTitles: _unlocked,
      ),
    );
  }

  NotebookEntry? _adjacent(int direction) {
    final current = _selectedEntry;
    if (current == null) return null;
    final index = notebookEntries.indexOf(current);
    for (int candidate = index + direction;
        candidate >= 0 && candidate < notebookEntries.length;
        candidate += direction) {
      if (_isUnlocked(notebookEntries[candidate])) {
        return notebookEntries[candidate];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.progressController,
        builder: (context, _) {
          if (!widget.progressController.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return ColoredBox(
            color: _background,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= _twoPaneBreakpoint;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _NotebookHeader(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      onClear: _clearSearch,
                    ),
                    const Divider(height: 1, color: _border),
                    Expanded(
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  key:
                                      const ValueKey('web-notebook-index-wide'),
                                  width:
                                      constraints.maxWidth < 1100 ? 300 : 350,
                                  child: _buildIndex(),
                                ),
                                const VerticalDivider(width: 1, color: _border),
                                Expanded(child: _buildReader(wide: true)),
                              ],
                            )
                          : normalizeNotebookSearchText(_query).isNotEmpty ||
                                  _selectedEntry == null
                              ? KeyedSubtree(
                                  key: const ValueKey(
                                      'web-notebook-index-narrow'),
                                  child: _buildIndex(),
                                )
                              : KeyedSubtree(
                                  key: const ValueKey(
                                      'web-notebook-reader-narrow'),
                                  child: _buildReader(wide: false),
                                ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      );

  Widget _buildIndex() => _NotebookIndex(
        unlocked: _unlocked,
        selectedEntry: _selectedEntry,
        query: _query,
        results: _results,
        onSelected: _selectEntry,
        onSearchResultSelected: _selectSearchResult,
        onOpenJourney: widget.onOpenJourney,
      );

  Widget _buildReader({required bool wide}) {
    final entry = _selectedEntry;
    if (entry == null) {
      return _NotebookWelcome(
        hasDiscoveries: _unlocked.isNotEmpty,
        onOpenJourney: widget.onOpenJourney,
      );
    }
    return _NotebookEntryPane(
      entry: entry,
      unlocked: _unlocked,
      showBack: !wide,
      onBack: () => setState(() => _selectedEntry = null),
      onSelectEntry: _selectEntry,
      previousEntry: _adjacent(-1),
      nextEntry: _adjacent(1),
      onOpenJourney: widget.onOpenJourney,
      onOpenExampleInComposer: widget.onOpenExampleInComposer,
      onOpenExampleInBlochExplorer: widget.onOpenExampleInBlochExplorer,
    );
  }
}

class _NotebookHeader extends StatelessWidget {
  const _NotebookHeader({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 15, 24, 15),
        child: Row(
          children: [
            const Icon(Icons.menu_book_outlined, color: _cyan, size: 26),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Quantum Notebook',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width < 650 ? 190 : 320,
                child: TextField(
                  key: const ValueKey('web-notebook-search-field'),
                  controller: controller,
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search Notebook',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: controller.text.isEmpty
                        ? null
                        : IconButton(
                            key: const ValueKey('web-notebook-clear-search'),
                            tooltip: 'Clear search',
                            onPressed: onClear,
                            icon: const Icon(Icons.clear, size: 19),
                          ),
                    filled: true,
                    fillColor: _surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _border),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _NotebookIndex extends StatelessWidget {
  const _NotebookIndex({
    required this.unlocked,
    required this.selectedEntry,
    required this.query,
    required this.results,
    required this.onSelected,
    required this.onSearchResultSelected,
    required this.onOpenJourney,
  });

  final Set<String> unlocked;
  final NotebookEntry? selectedEntry;
  final String query;
  final List<NotebookSearchResult> results;
  final ValueChanged<NotebookEntry> onSelected;
  final ValueChanged<NotebookEntry> onSearchResultSelected;
  final VoidCallback onOpenJourney;

  @override
  Widget build(BuildContext context) {
    if (normalizeNotebookSearchText(query).isNotEmpty) {
      return _SearchResults(
        query: query,
        results: results,
        onSelected: onSearchResultSelected,
      );
    }
    final chapters = <int, List<NotebookEntry>>{};
    for (final entry in notebookEntries) {
      chapters.putIfAbsent(entry.chapterIndex, () => []).add(entry);
    }
    return ListView(
      key: const ValueKey('web-notebook-index'),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
      children: [
        for (final chapter in chapters.values) ...[
          _ChapterHeading(entries: chapter, unlocked: unlocked),
          const SizedBox(height: 6),
          for (final entry in chapter)
            _EntryTile(
              entry: entry,
              unlocked: isNotebookEntryAvailable(entry, unlocked),
              selected: selectedEntry?.id == entry.id,
              onSelected: onSelected,
            ),
          const SizedBox(height: 16),
        ],
        if (unlocked.isEmpty)
          TextButton.icon(
            key: const ValueKey('web-notebook-go-journey'),
            onPressed: onOpenJourney,
            icon: const Icon(Icons.route_outlined),
            label: const Text('Discover entries in Journey'),
          ),
      ],
    );
  }
}

class _ChapterHeading extends StatelessWidget {
  const _ChapterHeading({required this.entries, required this.unlocked});
  final List<NotebookEntry> entries;
  final Set<String> unlocked;

  @override
  Widget build(BuildContext context) {
    final count = entries
        .where((entry) => isNotebookEntryAvailable(entry, unlocked))
        .length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entries.first.chapterTitle.toUpperCase(),
            style: const TextStyle(
              color: _purple,
              fontSize: 11,
              letterSpacing: .8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$count / ${entries.length} discovered',
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.unlocked,
    required this.selected,
    required this.onSelected,
  });
  final NotebookEntry entry;
  final bool unlocked;
  final bool selected;
  final ValueChanged<NotebookEntry> onSelected;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: ListTile(
          key: ValueKey('web-notebook-entry-${entry.id}'),
          dense: true,
          selected: selected,
          enabled: unlocked,
          selectedColor: _cyan,
          selectedTileColor: const Color(0x2222D3EE),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: Icon(
            unlocked ? Icons.check_circle_outline : Icons.lock_outline,
            size: 18,
            color: unlocked ? _cyan : Colors.white30,
          ),
          title: Text(
            entry.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: unlocked ? null : Colors.white38,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
          onTap: unlocked ? () => onSelected(entry) : null,
        ),
      );
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.query,
    required this.results,
    required this.onSelected,
  });
  final String query;
  final List<NotebookSearchResult> results;
  final ValueChanged<NotebookEntry> onSelected;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No discovered Notebook entries found for “${query.trim()}”.',
            key: const ValueKey('web-notebook-search-empty'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, height: 1.4),
          ),
        ),
      );
    }
    return ListView.separated(
      key: const ValueKey('web-notebook-search-results'),
      padding: const EdgeInsets.all(14),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final result = results[index];
        return Card(
          color: _surface,
          child: ListTile(
            key: ValueKey('web-notebook-search-${result.entry.id}'),
            leading: const Icon(Icons.menu_book_outlined, color: _cyan),
            title: Text(result.entry.title,
                style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text(
              '${result.entry.chapterTitle}\n${result.snippet}',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => onSelected(result.entry),
          ),
        );
      },
    );
  }
}

class _NotebookWelcome extends StatelessWidget {
  const _NotebookWelcome({
    required this.hasDiscoveries,
    required this.onOpenJourney,
  });
  final bool hasDiscoveries;
  final VoidCallback onOpenJourney;

  @override
  Widget build(BuildContext context) => Center(
        key: const ValueKey('web-notebook-welcome'),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_stories_outlined, color: _cyan, size: 44),
                const SizedBox(height: 14),
                Text(
                  hasDiscoveries
                      ? 'Select a discovered entry to begin reading.'
                      : 'Notebook entries unlock as you make discoveries in the Journey.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 16,
                    height: 1.45,
                  ),
                ),
                if (!hasDiscoveries) ...[
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: onOpenJourney,
                    icon: const Icon(Icons.route_outlined),
                    label: const Text('Return to Journey'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}

class _NotebookEntryPane extends StatelessWidget {
  const _NotebookEntryPane({
    required this.entry,
    required this.unlocked,
    required this.showBack,
    required this.onBack,
    required this.onSelectEntry,
    required this.previousEntry,
    required this.nextEntry,
    required this.onOpenJourney,
    required this.onOpenExampleInComposer,
    required this.onOpenExampleInBlochExplorer,
  });

  final NotebookEntry entry;
  final Set<String> unlocked;
  final bool showBack;
  final VoidCallback onBack;
  final ValueChanged<NotebookEntry> onSelectEntry;
  final NotebookEntry? previousEntry;
  final NotebookEntry? nextEntry;
  final VoidCallback onOpenJourney;
  final ValueChanged<ExecutableNotebookExample>? onOpenExampleInComposer;
  final void Function(
    ExecutableNotebookExample example,
    ExecutableNotebookResult result,
  )? onOpenExampleInBlochExplorer;

  @override
  Widget build(BuildContext context) {
    final examples = [
      ...entry.intuition.examples,
      ...?entry.whatChanged?.examples,
      ...?entry.quantumView?.examples,
    ];
    return ListView(
      key: ValueKey('web-notebook-reader-${entry.id}'),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showBack)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const ValueKey('web-notebook-back-index'),
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Notebook index'),
                    ),
                  ),
                Text(
                  entry.chapterTitle,
                  style: const TextStyle(
                    color: _cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  entry.title,
                  key: const ValueKey('web-notebook-entry-title'),
                  style: const TextStyle(
                    fontSize: 30,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  formatQuantumNotationForPlainText(entry.summary),
                  style: const TextStyle(
                    color: Color(0xFFD6E3F8),
                    fontSize: 16,
                    height: 1.45,
                  ),
                ),
                if (examples.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _ExamplesCard(examples: examples),
                ],
                for (final section in [
                  entry.intuition,
                  if (entry.whatChanged != null) entry.whatChanged!,
                  if (entry.quantumView != null) entry.quantumView!,
                ]) ...[
                  const SizedBox(height: 14),
                  _SectionCard(section: section),
                ],
                if (entry.executableExampleIds.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  for (final id in entry.executableExampleIds)
                    if (executableNotebookExamplesById[id]
                        case final example?) ...[
                      ExecutableNotebookExampleView(
                        example: example,
                        onOpenInComposer: onOpenExampleInComposer,
                        onOpenInBlochExplorer: onOpenExampleInBlochExplorer,
                      ),
                      const SizedBox(height: 10),
                    ],
                ],
                if (entry.advancedNotes != null) ...[
                  const SizedBox(height: 14),
                  _AdvancedSection(section: entry.advancedNotes!),
                ],
                if (entry.relatedDiscoveryTitles.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _RelatedEntries(
                    entry: entry,
                    unlocked: unlocked,
                    onSelected: onSelectEntry,
                    onOpenJourney: onOpenJourney,
                  ),
                ],
                if (previousEntry != null || nextEntry != null) ...[
                  const SizedBox(height: 18),
                  _PreviousNext(
                    previousEntry: previousEntry,
                    nextEntry: nextEntry,
                    onSelected: onSelectEntry,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});
  final NotebookSection section;

  @override
  Widget build(BuildContext context) => Padding(
        key: ValueKey('web-notebook-section-${section.title}'),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(section.title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
              formatQuantumNotationForPlainText(section.body),
              style: const TextStyle(
                color: Color(0xFFD6E3F8),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
}

class _ExamplesCard extends StatelessWidget {
  const _ExamplesCard({required this.examples});
  final List<NotebookExample> examples;

  @override
  Widget build(BuildContext context) {
    final blocks = <Widget>[];
    var index = 0;
    while (index < examples.length) {
      final example = examples[index];
      if (example.comparisonGroup case final group?) {
        final grouped = <NotebookExample>[];
        while (index < examples.length &&
            examples[index].comparisonGroup == group) {
          grouped.add(examples[index]);
          index++;
        }
        blocks.add(_WebNotebookComparison(examples: grouped));
      } else {
        blocks.add(_WebNotebookExampleBlock(example: example));
        index++;
      }
    }
    return Padding(
      key: const ValueKey('web-notebook-key-examples'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Key Examples',
              style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          for (var index = 0; index < blocks.length; index++) ...[
            blocks[index],
            if (index != blocks.length - 1)
              const Divider(height: 18, color: _border),
          ],
        ],
      ),
    );
  }
}

class _WebNotebookExampleBlock extends StatelessWidget {
  const _WebNotebookExampleBlock({required this.example});

  final NotebookExample example;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            example.label,
            style: const TextStyle(
              color: _cyan,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          if (example.presentation == NotebookExamplePresentation.math)
            Semantics(
              label: example.notation,
              child: ExcludeSemantics(
                child: Center(
                  child: LatexText(
                    math: r'\[' +
                        (example.latex ??
                            notebookMathNotationToLatex(
                              example.notation,
                            )) +
                        r'\]',
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                    displayMathHeight: 22,
                  ),
                ),
              ),
            )
          else
            Text(
              formatQuantumNotationForPlainText(example.notation),
              style: const TextStyle(
                color: Colors.white,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          if ((example.explanation ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(example.explanation!,
                style: const TextStyle(color: _muted, height: 1.35)),
          ],
        ],
      );
}

class _WebNotebookComparison extends StatelessWidget {
  const _WebNotebookComparison({required this.examples});

  final List<NotebookExample> examples;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final useColumns =
              constraints.maxWidth >= 430 && examples.length == 2;
          if (!useColumns) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < examples.length; index++) ...[
                  _WebNotebookExampleBlock(example: examples[index]),
                  if (index != examples.length - 1) const SizedBox(height: 8),
                ],
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < examples.length; index++) ...[
                Expanded(
                    child: _WebNotebookExampleBlock(example: examples[index])),
                if (index != examples.length - 1) const SizedBox(width: 20),
              ],
            ],
          );
        },
      );
}

class _AdvancedSection extends StatelessWidget {
  const _AdvancedSection({required this.section});
  final NotebookSection section;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('web-notebook-advanced-notes'),
        decoration: BoxDecoration(
          color: _inner,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Text(section.title,
              style: const TextStyle(fontWeight: FontWeight.w900)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              formatQuantumNotationForPlainText(section.body),
              style: const TextStyle(color: Color(0xFFD6E3F8), height: 1.5),
            ),
          ],
        ),
      );
}

class _RelatedEntries extends StatelessWidget {
  const _RelatedEntries({
    required this.entry,
    required this.unlocked,
    required this.onSelected,
    required this.onOpenJourney,
  });
  final NotebookEntry entry;
  final Set<String> unlocked;
  final ValueChanged<NotebookEntry> onSelected;
  final VoidCallback onOpenJourney;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('web-notebook-related'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _inner,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Related',
                style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final title in entry.relatedDiscoveryTitles)
                  if (notebookEntriesByDiscoveryTitle[title]
                      case final related?)
                    ActionChip(
                      avatar: Icon(
                        unlocked.contains(title)
                            ? Icons.auto_stories_outlined
                            : Icons.lock_outline,
                        size: 16,
                      ),
                      label: Text(title),
                      onPressed: unlocked.contains(title)
                          ? () => onSelected(related)
                          : null,
                    ),
                ActionChip(
                  avatar: const Icon(Icons.route_outlined, size: 16),
                  label: const Text('Journey'),
                  onPressed: onOpenJourney,
                ),
              ],
            ),
          ],
        ),
      );
}

class _PreviousNext extends StatelessWidget {
  const _PreviousNext({
    required this.previousEntry,
    required this.nextEntry,
    required this.onSelected,
  });
  final NotebookEntry? previousEntry;
  final NotebookEntry? nextEntry;
  final ValueChanged<NotebookEntry> onSelected;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: previousEntry == null
                ? const SizedBox.shrink()
                : OutlinedButton.icon(
                    key: const ValueKey('web-notebook-previous'),
                    onPressed: () => onSelected(previousEntry!),
                    icon: const Icon(Icons.chevron_left),
                    label: Text(previousEntry!.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: nextEntry == null
                ? const SizedBox.shrink()
                : FilledButton.icon(
                    key: const ValueKey('web-notebook-next'),
                    onPressed: () => onSelected(nextEntry!),
                    icon: const Icon(Icons.chevron_right),
                    label: Text(nextEntry!.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
          ),
        ],
      );
}
