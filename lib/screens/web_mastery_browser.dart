import 'package:flutter/material.dart';
import 'package:quantumquiz/models/mastery_2_presentation.dart';
import 'package:quantumquiz/models/mastery_challenge_catalogue.dart';
import 'package:quantumquiz/models/notebook_knowledge_base.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/web_learning_text.dart';

/// Which part of the library a [WebMasteryBrowser] renders (v2.6 M11D):
/// the whole page (narrow hosts), the persistent list pane, or the detail.
enum MasteryBrowserPart { full, pane, detail }

/// Completion filter of the Mastery library.
enum MasteryCompletionFilter { all, incomplete, completed }

String masteryInteractionLabel(MasteryInteractionType type) => switch (type) {
      MasteryInteractionType.prediction => 'Prediction',
      MasteryInteractionType.construction => 'Circuit construction',
      MasteryInteractionType.debugging => 'Debugging',
      MasteryInteractionType.evidence => 'Evidence',
      MasteryInteractionType.measurement => 'Measurement',
      MasteryInteractionType.fillGate => 'Missing gate',
      MasteryInteractionType.uncomputation => 'Uncomputation',
      MasteryInteractionType.algorithm => 'Algorithm',
    };

String masteryDifficultyLabel(MasteryDifficulty difficulty) =>
    switch (difficulty) {
      MasteryDifficulty.foundation => 'Foundation',
      MasteryDifficulty.application => 'Application',
      MasteryDifficulty.integration => 'Integration',
      MasteryDifficulty.advanced => 'Advanced',
    };

String masteryConceptLabel(MasteryConceptTag tag) => switch (tag) {
      MasteryConceptTag.reversibility => 'Reversibility',
      MasteryConceptTag.physicalState => 'Physical state',
      MasteryConceptTag.operatorAction => 'Operator action',
      MasteryConceptTag.inverseOrder => 'Inverse order',
      MasteryConceptTag.globalPhase => 'Global phase',
      MasteryConceptTag.relativePhase => 'Relative phase',
      MasteryConceptTag.superposition => 'Superposition',
      MasteryConceptTag.interference => 'Interference',
      MasteryConceptTag.measurementBasis => 'Measurement basis',
      MasteryConceptTag.classicalMixture => 'Classical mixture',
      MasteryConceptTag.entanglement => 'Entanglement',
      MasteryConceptTag.control => 'Controlled gates',
      MasteryConceptTag.ghz => 'GHZ states',
      MasteryConceptTag.kickback => 'Phase kickback',
      MasteryConceptTag.oracle => 'Oracles',
      MasteryConceptTag.amplification => 'Amplitude amplification',
      MasteryConceptTag.iteration => 'Iteration',
      MasteryConceptTag.algorithmStructure => 'Algorithm structure',
    };

/// The activity's format, derived from its definition (never invented):
/// a circuit to build in the Composer, or a question.
String masteryFormatLabel(MasteryChallengeDefinition challenge) =>
    switch (challenge.levelDefinition) {
      ComposerLevel level =>
        'Circuit · ${level.numQubits} qubit${level.numQubits == 1 ? '' : 's'}',
      _ => 'Question',
    };

/// Filters and search over the catalogue. Purely a view: never changes
/// completion or availability (every challenge is always open).
@immutable
class MasteryLibraryQuery {
  const MasteryLibraryQuery({
    this.text = '',
    this.completion = MasteryCompletionFilter.all,
    this.type,
    this.difficulty,
    this.concept,
  });

  final String text;
  final MasteryCompletionFilter completion;
  final MasteryInteractionType? type;
  final MasteryDifficulty? difficulty;
  final MasteryConceptTag? concept;

  bool get isDefault =>
      text.trim().isEmpty &&
      completion == MasteryCompletionFilter.all &&
      type == null &&
      difficulty == null &&
      concept == null;

  MasteryLibraryQuery copyWith({
    String? text,
    MasteryCompletionFilter? completion,
    MasteryInteractionType? Function()? type,
    MasteryDifficulty? Function()? difficulty,
    MasteryConceptTag? Function()? concept,
  }) =>
      MasteryLibraryQuery(
        text: text ?? this.text,
        completion: completion ?? this.completion,
        type: type == null ? this.type : type(),
        difficulty: difficulty == null ? this.difficulty : difficulty(),
        concept: concept == null ? this.concept : concept(),
      );

  /// Search covers the title, number, type, difficulty and concept tags.
  bool matches(MasteryChallengeDefinition c, Set<String> completedIds) {
    final done = completedIds.contains(c.semanticId);
    if (completion == MasteryCompletionFilter.completed && !done) return false;
    if (completion == MasteryCompletionFilter.incomplete && done) return false;
    if (type != null && c.interactionType != type) return false;
    if (difficulty != null && c.difficulty != difficulty) return false;
    if (concept != null && !c.conceptTags.contains(concept)) return false;
    final q = text.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = [
      c.title,
      '${c.displayOrder}',
      masteryInteractionLabel(c.interactionType),
      masteryDifficultyLabel(c.difficulty),
      for (final tag in c.conceptTags) masteryConceptLabel(tag),
    ].join(' ').toLowerCase();
    return q.split(RegExp(r'\s+')).every(haystack.contains);
  }
}

/// The Mastery Challenges library (v2.6 M6a): search and filters, a compact
/// challenge list and the selected challenge's details. Selecting never
/// starts a challenge; the details' primary action does.
class WebMasteryBrowser extends StatelessWidget {
  const WebMasteryBrowser({
    super.key,
    required this.challenges,
    required this.completedIds,
    required this.selected,
    required this.openSemanticId,
    required this.query,
    required this.searchController,
    required this.onQuery,
    required this.onSelect,
    required this.onStart,
    required this.onBackToJourney,
    this.onOpenNotebookArticle,
    required this.narrowShowsDetail,
    required this.onNarrowBack,
    this.listController,
    this.part = MasteryBrowserPart.full,
    this.onCollapsePane,
  });

  final MasteryBrowserPart part;

  /// Pane only: collapse the pane to the numbered rail (circuit work).
  final VoidCallback? onCollapsePane;

  final List<MasteryChallengeDefinition> challenges;
  final Set<String> completedIds;
  final MasteryChallengeDefinition? selected;

  /// The challenge whose activity is open (kept alive), if any.
  final String? openSemanticId;
  final MasteryLibraryQuery query;
  final TextEditingController searchController;
  final ValueChanged<MasteryLibraryQuery> onQuery;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onStart;
  final VoidCallback onBackToJourney;

  /// Opens a Notebook gate article (v2.6 M6b).
  final ValueChanged<String>? onOpenNotebookArticle;
  final bool narrowShowsDetail;
  final VoidCallback onNarrowBack;
  final ScrollController? listController;

  static const double masterDetailWidth = 760;

  /// List row height: two-line titles fit (M11D.1).
  static const double rowExtent = 70;
  static const double listTopPadding = 10;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final visible =
              challenges.where((c) => query.matches(c, completedIds)).toList();
          final wide = constraints.maxWidth >= masterDetailWidth;
          final listWidth = constraints.maxWidth >= 1200 ? 400.0 : 340.0;
          final list = _list(visible);
          if (part == MasteryBrowserPart.pane) {
            return ColoredBox(
              key: const ValueKey('web-mastery-pane'),
              color: QubitQuestSurfaces.section,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _paneHeader(context, visible.length),
                  const Divider(height: 1, color: QubitQuestSurfaces.rule),
                  Expanded(child: list),
                ],
              ),
            );
          }
          final header = _header(context, visible.length, wide);
          final detail = selected == null
              ? const Center(
                  child: Text('Select a challenge to see its details.',
                      style: QqType.meta))
              : _ChallengeDetail(
                  key: ValueKey('web-mastery-detail-${selected!.semanticId}'),
                  challenge: selected!,
                  completed: completedIds.contains(selected!.semanticId),
                  open: openSemanticId == selected!.semanticId,
                  inResults: visible.contains(selected),
                  onStart: () => onStart(selected!.semanticId),
                  onOpenNotebookArticle: onOpenNotebookArticle,
                  onNarrowBack: wide ? null : onNarrowBack,
                );
          if (part == MasteryBrowserPart.detail) {
            return ColoredBox(
                key: const ValueKey('web-mastery-overview'),
                color: QubitQuestSurfaces.page,
                child: detail);
          }
          return ColoredBox(
            key: const ValueKey('web-mastery-overview'),
            color: QubitQuestColors.background,
            child: wide
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      const Divider(height: 1, color: QubitQuestColors.border),
                      Expanded(
                        child: Row(
                          key: const ValueKey('web-mastery-master-detail'),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(width: listWidth, child: list),
                            const VerticalDivider(
                                width: 1, color: QubitQuestColors.border),
                            Expanded(child: detail),
                          ],
                        ),
                      ),
                    ],
                  )
                : narrowShowsDetail && selected != null
                    ? detail
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          header,
                          const Divider(
                              height: 1, color: QubitQuestColors.border),
                          Expanded(child: list),
                        ],
                      ),
          );
        },
      );

  int get _completedCount =>
      challenges.where((c) => completedIds.contains(c.semanticId)).length;

  Widget _header(BuildContext context, int visibleCount, bool wide) {
    final total = challenges.length;
    final done = _completedCount;
    Widget dropdown<T>({
      required Key key,
      required String label,
      required T? value,
      required List<T> values,
      required String Function(T) name,
      required ValueChanged<T?> onChanged,
    }) =>
        DropdownButtonHideUnderline(
          child: Container(
            // Fixed width: long concept names ellipsise instead of
            // widening the control past narrow screens.
            width: 172,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(
                  color: value == null
                      ? QubitQuestColors.border
                      : QubitQuestColors.accentInteractive),
              borderRadius: QubitQuestRadii.control,
            ),
            child: DropdownButton<T?>(
              key: key,
              value: value,
              isDense: true,
              isExpanded: true,
              hint: Text('Any $label',
                  overflow: TextOverflow.ellipsis,
                  style: QqType.meta),
              items: [
                DropdownMenuItem<T?>(
                    value: null,
                    child: Text('Any $label', overflow: TextOverflow.ellipsis)),
                for (final v in values)
                  DropdownMenuItem<T?>(
                      value: v,
                      child: Text(name(v), overflow: TextOverflow.ellipsis)),
              ],
              onChanged: onChanged,
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mastery Challenges',
                        key: ValueKey('web-mastery-title'),
                        style: QqType.sectionTitle),
                    const SizedBox(height: 2),
                    const Text(
                      'Independent quantum reasoning challenges, open at any '
                      'time and in any order.',
                      style: QqType.meta,
                    ),
                  ],
                ),
              ),
              if (wide)
                TextButton.icon(
                  key: const ValueKey('web-mastery-back-journey'),
                  onPressed: onBackToJourney,
                  icon: const Icon(Icons.route_outlined, size: 18),
                  label: const Text('Learning Journey'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('$done / $total complete',
                  key: const ValueKey('web-mastery-progress'),
                  style: QqType.meta),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    key: const ValueKey('web-mastery-progress-bar'),
                    value: total == 0 ? 0 : done / total,
                    minHeight: 4,
                    backgroundColor: QubitQuestColors.border,
                    color: QubitQuestColors.accentInteractive,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('web-mastery-search'),
            controller: searchController,
            onChanged: (text) => onQuery(query.copyWith(text: text)),
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Search challenges, concepts or types',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      key: const ValueKey('web-mastery-search-clear'),
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        searchController.clear();
                        onQuery(query.copyWith(text: ''));
                      },
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final value in MasteryCompletionFilter.values)
                ChoiceChip(
                  key: ValueKey('web-mastery-filter-${value.name}'),
                  label: Text(switch (value) {
                    MasteryCompletionFilter.all => 'All',
                    MasteryCompletionFilter.incomplete => 'Incomplete',
                    MasteryCompletionFilter.completed => 'Completed',
                  }),
                  selected: query.completion == value,
                  onSelected: (_) => onQuery(query.copyWith(completion: value)),
                ),
              dropdown<MasteryInteractionType>(
                key: const ValueKey('web-mastery-filter-type'),
                label: 'type',
                value: query.type,
                values: MasteryInteractionType.values
                    .where((t) => challenges.any((c) => c.interactionType == t))
                    .toList(),
                name: masteryInteractionLabel,
                onChanged: (v) => onQuery(query.copyWith(type: () => v)),
              ),
              dropdown<MasteryDifficulty>(
                key: const ValueKey('web-mastery-filter-difficulty'),
                label: 'level',
                value: query.difficulty,
                values: MasteryDifficulty.values,
                name: masteryDifficultyLabel,
                onChanged: (v) => onQuery(query.copyWith(difficulty: () => v)),
              ),
              dropdown<MasteryConceptTag>(
                key: const ValueKey('web-mastery-filter-concept'),
                label: 'concept',
                value: query.concept,
                values: MasteryConceptTag.values
                    .where(
                        (t) => challenges.any((c) => c.conceptTags.contains(t)))
                    .toList(),
                name: masteryConceptLabel,
                onChanged: (v) => onQuery(query.copyWith(concept: () => v)),
              ),
              Text('$visibleCount of $total challenges',
                  key: const ValueKey('web-mastery-result-count'),
                  style: QqType.meta),
              if (!query.isDefault)
                TextButton(
                  key: const ValueKey('web-mastery-clear-filters'),
                  onPressed: () {
                    searchController.clear();
                    onQuery(const MasteryLibraryQuery());
                  },
                  child: const Text('Clear filters'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required Key key,
    required String label,
    required T? value,
    required List<T> values,
    required String Function(T) name,
    required ValueChanged<T?> onChanged,
    double? width,
  }) =>
      DropdownButtonHideUnderline(
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(
                color: value == null
                    ? QubitQuestColors.border
                    : QubitQuestColors.accentInteractive),
            borderRadius: QubitQuestRadii.control,
          ),
          child: DropdownButton<T?>(
            key: key,
            value: value,
            isDense: true,
            isExpanded: true,
            style: QqType.navLabel.copyWith(fontSize: 13.5),
            hint: Text('Any $label',
                overflow: TextOverflow.ellipsis, style: QqType.meta),
            items: [
              DropdownMenuItem<T?>(
                  value: null,
                  child: Text('Any $label', overflow: TextOverflow.ellipsis)),
              for (final v in values)
                DropdownMenuItem<T?>(
                    value: v,
                    child: Text(name(v), overflow: TextOverflow.ellipsis)),
            ],
            onChanged: onChanged,
          ),
        ),
      );

  /// The list pane's own compact header (M11B prototype 9): search, the
  /// completion chips, the three filters and the counts. The same query and
  /// controllers as the full page, so nothing resets between views.
  Widget _paneHeader(BuildContext context, int visibleCount) {
    final total = challenges.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Mastery Challenges',
                    key: ValueKey('web-mastery-title'),
                    style: QqType.subjectTitle),
              ),
              if (onCollapsePane != null)
                IconButton(
                  key: const ValueKey('web-mastery-pane-collapse'),
                  tooltip: 'Collapse the challenge list',
                  visualDensity: VisualDensity.compact,
                  onPressed: onCollapsePane,
                  icon: const Icon(Icons.keyboard_double_arrow_left_rounded,
                      size: 18),
                )
              else
                IconButton(
                  key: const ValueKey('web-mastery-back-journey'),
                  tooltip: 'Learning Journey',
                  visualDensity: VisualDensity.compact,
                  onPressed: onBackToJourney,
                  icon: const Icon(Icons.route_outlined, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('web-mastery-search'),
            controller: searchController,
            onChanged: (text) => onQuery(query.copyWith(text: text)),
            style: QqType.navLabel,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search challenges',
              prefixIcon: const Icon(Icons.search, size: 18),
              border: const OutlineInputBorder(),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      key: const ValueKey('web-mastery-search-clear'),
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        searchController.clear();
                        onQuery(query.copyWith(text: ''));
                      },
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final value in MasteryCompletionFilter.values)
                ChoiceChip(
                  key: ValueKey('web-mastery-filter-${value.name}'),
                  visualDensity: VisualDensity.compact,
                  showCheckmark: false,
                  labelStyle: QqType.control.copyWith(fontSize: 13),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  label: Text(switch (value) {
                    MasteryCompletionFilter.all => 'All',
                    MasteryCompletionFilter.incomplete => 'Incomplete',
                    MasteryCompletionFilter.completed => 'Completed',
                  }),
                  selected: query.completion == value,
                  onSelected: (_) => onQuery(query.copyWith(completion: value)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, c) {
            final w = (c.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _dropdown<MasteryInteractionType>(
                  key: const ValueKey('web-mastery-filter-type'),
                  label: 'type',
                  width: w,
                  value: query.type,
                  values: MasteryInteractionType.values
                      .where(
                          (t) => challenges.any((c) => c.interactionType == t))
                      .toList(),
                  name: masteryInteractionLabel,
                  onChanged: (v) => onQuery(query.copyWith(type: () => v)),
                ),
                _dropdown<MasteryDifficulty>(
                  key: const ValueKey('web-mastery-filter-difficulty'),
                  label: 'level',
                  width: w,
                  value: query.difficulty,
                  values: MasteryDifficulty.values,
                  name: masteryDifficultyLabel,
                  onChanged: (v) =>
                      onQuery(query.copyWith(difficulty: () => v)),
                ),
                _dropdown<MasteryConceptTag>(
                  key: const ValueKey('web-mastery-filter-concept'),
                  label: 'concept',
                  width: c.maxWidth,
                  value: query.concept,
                  values: MasteryConceptTag.values
                      .where((t) =>
                          challenges.any((c) => c.conceptTags.contains(t)))
                      .toList(),
                  name: masteryConceptLabel,
                  onChanged: (v) => onQuery(query.copyWith(concept: () => v)),
                ),
              ],
            );
          }),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                child: Text('$_completedCount / $total complete',
                    key: const ValueKey('web-mastery-progress'),
                    overflow: TextOverflow.ellipsis,
                    style: QqType.navMeta),
              ),
              const Text('  ·  ', style: QqType.navMeta),
              Expanded(
                child: Text('$visibleCount of $total challenges',
                    key: const ValueKey('web-mastery-result-count'),
                    overflow: TextOverflow.ellipsis,
                    style: QqType.navMeta),
              ),
              if (!query.isDefault)
                TextButton(
                  key: const ValueKey('web-mastery-clear-filters'),
                  style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact),
                  onPressed: () {
                    searchController.clear();
                    onQuery(const MasteryLibraryQuery());
                  },
                  child: const Text('Clear'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _list(List<MasteryChallengeDefinition> visible) {
    if (visible.isEmpty) {
      return Padding(
        key: const ValueKey('web-mastery-empty'),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('No matching challenges.',
                style: QqType.body),
            const SizedBox(height: 8),
            TextButton(
              key: const ValueKey('web-mastery-empty-reset'),
              onPressed: () {
                searchController.clear();
                onQuery(const MasteryLibraryQuery());
              },
              child: const Text('Show all challenges'),
            ),
          ],
        ),
      );
    }
    // Lazy rows keep browsing proportional to the visible list, not the
    // catalogue's size.
    return ListView.builder(
      key: const ValueKey('web-mastery-list'),
      controller: listController,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
      itemCount: visible.length,
      itemExtent: WebMasteryBrowser.rowExtent,
      itemBuilder: (context, index) {
        final c = visible[index];
        return _ChallengeRow(
          challenge: c,
          completed: completedIds.contains(c.semanticId),
          selected: selected?.semanticId == c.semanticId,
          open: openSemanticId == c.semanticId,
          onTap: () => onSelect(c.semanticId),
        );
      },
    );
  }
}

class _ChallengeRow extends StatelessWidget {
  const _ChallengeRow({
    required this.challenge,
    required this.completed,
    required this.selected,
    required this.open,
    required this.onTap,
  });
  final MasteryChallengeDefinition challenge;
  final bool completed;
  final bool selected;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: '${challenge.displayOrder}. ${challenge.title}',
        waitDuration: const Duration(milliseconds: 700),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Material(
            color: selected
                ? QubitQuestColors.navigationSelected
                : Colors.transparent,
            borderRadius: QubitQuestRadii.control,
            child: InkWell(
              key: ValueKey('web-mastery-challenge-${challenge.semanticId}'),
              borderRadius: QubitQuestRadii.control,
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: QubitQuestRadii.control,
                  border: Border(
                    left: BorderSide(
                      width: 3,
                      color: selected
                          ? QubitQuestColors.accentInteractive
                          : Colors.transparent,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      completed
                          ? Icons.check_circle
                          : open
                              ? Icons.play_circle
                              : Icons.radio_button_unchecked,
                      key: ValueKey(
                          'web-mastery-status-${challenge.semanticId}-${completed ? 'completed' : open ? 'open' : 'incomplete'}'),
                      size: 18,
                      color: completed
                          ? QubitQuestColors.success
                          : open
                              ? QubitQuestColors.accentInteractive
                              : QubitQuestColors.textMuted,
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 24,
                      child: Text(
                        challenge.displayOrder.toString().padLeft(2, '0'),
                        style: QqType.meta,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // The title takes what the fixed row height
                          // leaves (large text: one line, ellipsised).
                          Flexible(
                            child: Text(
                              challenge.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: QqType.navLabel.copyWith(
                                color: selected
                                    ? QubitQuestColors.accentInteractive
                                    : QubitQuestColors.textPrimary,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            '${masteryInteractionLabel(challenge.interactionType)}'
                            ' · ${masteryDifficultyLabel(challenge.difficulty)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: QqType.navMeta.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

/// What a learner may know before starting: identity, format, concepts and
/// the task statement shown at the start anyway. Never the question's
/// options, hints, explanation or any solution.
class _ChallengeDetail extends StatelessWidget {
  const _ChallengeDetail({
    super.key,
    required this.challenge,
    required this.completed,
    required this.open,
    required this.onStart,
    this.onNarrowBack,
    this.inResults = true,
    this.onOpenNotebookArticle,
  });

  final ValueChanged<String>? onOpenNotebookArticle;
  final MasteryChallengeDefinition challenge;

  /// False when the current search or filters hide this challenge's row.
  final bool inResults;
  final bool completed;
  final bool open;
  final VoidCallback onStart;
  final VoidCallback? onNarrowBack;

  @override
  Widget build(BuildContext context) {
    final presentation = mastery2Presentations[challenge.semanticId];
    // Question challenges may carry their task in evidence and question
    // only; then the level's own task description is the statement shown
    // at the start. Never options, hints or explanations.
    final instruction = presentation?.instruction.trim() ?? '';
    final task = instruction.isNotEmpty
        ? instruction
        : challenge.levelDefinition.taskDescription.trim();
    final status = completed ? 'COMPLETED' : 'NOT COMPLETED';
    final label = completed
        ? 'Review challenge'
        : open
            ? 'Continue challenge'
            : 'Start challenge';
    return SingleChildScrollView(
      key: const ValueKey('web-mastery-detail-scroll'),
      padding: const EdgeInsets.fromLTRB(36, 28, 36, 32),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (onNarrowBack != null)
                TextButton.icon(
                  key: const ValueKey('web-mastery-back-to-list'),
                  onPressed: onNarrowBack,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('All challenges'),
                ),
              if (!inResults)
                const Padding(
                  key: ValueKey('web-mastery-detail-filtered'),
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Not in the current results (hidden by the search or '
                    'filters).',
                    style: QqType.meta,
                  ),
                ),
              Text(
                'CHALLENGE ${challenge.displayOrder.toString().padLeft(2, '0')} · $status',
                key: const ValueKey('web-mastery-detail-status'),
                style: QqType.panelHeading
                    .copyWith(color: QubitQuestColors.textMuted),
              ),
              const SizedBox(height: 6),
              Text(challenge.title,
                  key: const ValueKey('web-mastery-detail-title'),
                  style: QqType.activityTitle.copyWith(fontSize: 28)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _Meta(masteryInteractionLabel(challenge.interactionType)),
                  _Meta(masteryDifficultyLabel(challenge.difficulty)),
                  _Meta(masteryFormatLabel(challenge),
                      key: const ValueKey('web-mastery-detail-format')),
                ],
              ),
              const SizedBox(height: 16),
              // The primary action sits above the task text, so it is always
              // reachable without scrolling.
              Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton.icon(
                    key: const ValueKey('web-mastery-start'),
                    onPressed: onStart,
                    icon: Icon(completed ? Icons.replay : Icons.play_arrow),
                    label: Text(label),
                  ),
                  if (completed)
                    const Text(
                      'Reviewing never resets completion.',
                      style: QqType.meta,
                    ),
                ],
              ),
              const SizedBox(height: 18),
              if (task.isNotEmpty) ...[
                Text('TASK',
                    style: QqType.panelHeading
                        .copyWith(color: QubitQuestColors.textMuted)),
                const SizedBox(height: 4),
                WebLearningText(task,
                    key: const ValueKey('web-mastery-detail-task'),
                    role: WebLearningTextRole.task),
                const SizedBox(height: 16),
              ],
              Text('CONCEPTS',
                  style: QqType.panelHeading
                      .copyWith(color: QubitQuestColors.textMuted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in challenge.conceptTags)
                    Chip(
                      key: ValueKey('web-mastery-concept-${tag.name}'),
                      visualDensity: VisualDensity.compact,
                      label: Text(masteryConceptLabel(tag)),
                    ),
                ],
              ),
              if (onOpenNotebookArticle != null &&
                  challenge.levelDefinition is ComposerLevel) ...[
                const SizedBox(height: 16),
                Text('GATE REFERENCE',
                    style: QqType.panelHeading
                        .copyWith(color: QubitQuestColors.textMuted)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    // The challenge's own palette: shown on opening anyway,
                    // so these links reveal nothing about its solution.
                    for (final type in {
                      for (final g
                          in (challenge.levelDefinition as ComposerLevel)
                              .availableGates)
                        g.type
                    })
                      ActionChip(
                        key: ValueKey('web-mastery-gate-ref-${type.name}'),
                        avatar: const Icon(Icons.menu_book_outlined, size: 16),
                        label: Text(gateSymbol(type)),
                        onPressed: () => onOpenNotebookArticle!(
                            NotebookArticle.gateId(type)),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: QubitQuestColors.border),
          borderRadius: QubitQuestRadii.control,
        ),
        child: Text(text, style: QqType.meta.copyWith(fontSize: 12.5)),
      );
}
