import 'package:quantumquiz/models/discovery_progress.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/notebook_entry.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/qq_levels_category.dart';
import 'package:quantumquiz/screens/learning_map_screen.dart';
import 'package:quantumquiz/screens/level_ui_router.dart';
import 'package:quantumquiz/widgets/level_header_router.dart';

class ChapterReleaseGateResult {
  const ChapterReleaseGateResult({
    required this.chapterName,
    required this.validatedSections,
    required this.failures,
    required this.fixPlan,
  });

  final String chapterName;
  final List<String> validatedSections;
  final List<String> failures;
  final List<String> fixPlan;

  bool get passed => failures.isEmpty;
  String get status => passed ? 'PASS' : 'FAIL';

  String toReport() {
    final buffer = StringBuffer()
      ..writeln('Chapter Release Gate: $status')
      ..writeln('Chapter: $chapterName')
      ..writeln('Validated sections:');
    for (final section in validatedSections) {
      buffer.writeln('- $section');
    }
    if (failures.isEmpty) {
      buffer.writeln('Missing or inconsistent items: none');
      buffer.writeln('Final confirmation: all checks passed.');
      return buffer.toString();
    }

    buffer.writeln('Missing or inconsistent items:');
    for (final failure in failures) {
      buffer.writeln('- $failure');
    }
    buffer.writeln('Fix plan:');
    for (final fix in fixPlan) {
      buffer.writeln('- $fix');
    }
    return buffer.toString();
  }
}

class ChapterReleaseGate {
  const ChapterReleaseGate._();

  static const List<String> mandatorySections = [
    'Level System Validation',
    'Notebook System Validation',
    'UI Consistency Validation',
    'Learning Map Integration',
    'Cross-System Consistency Check',
    'Misconception Safety Check',
  ];

  static ChapterReleaseGateResult validateChapter(QQLevelsCategory chapter) {
    final failures = <String>[];
    final fixPlan = <String>[];

    if (_isMasteryCategory(chapter)) {
      failures.add(
        '[Level System Validation] "${chapter.groupName}" is Phase 2 concept integration, not a single releasable chapter.',
      );
      fixPlan.add(
        'Run validateCurriculumJourney() to validate Guided Discovery plus Mastery Challenges as one curriculum.',
      );
      return ChapterReleaseGateResult(
        chapterName: chapter.groupName,
        validatedSections: mandatorySections,
        failures: failures,
        fixPlan: fixPlan,
      );
    }

    final levels = _levelsFor(chapter, failures, fixPlan);
    _validateLevelSystem(chapter, levels, failures, fixPlan);
    _validateNotebookSystem(chapter, levels, failures, fixPlan);
    _validateUiConsistency(chapter, levels, failures, fixPlan);
    _validateLearningMap(chapter, failures, fixPlan);
    _validateCrossSystemConsistency(chapter, levels, failures, fixPlan);
    _validateMisconceptionSafety(chapter, levels, failures, fixPlan);

    return ChapterReleaseGateResult(
      chapterName: chapter.groupName,
      validatedSections: mandatorySections,
      failures: failures,
      fixPlan: failures.isEmpty ? const [] : fixPlan.toSet().toList(),
    );
  }

  static List<ChapterReleaseGateResult> validateChapters(
    Iterable<QQLevelsCategory> chapters,
  ) {
    return [
      for (final chapter in chapters) validateChapter(chapter),
    ];
  }

  static List<QQLevelsCategory> campaignChaptersThrough(int chapterNumber) {
    return groupedLevels
        .where((chapter) => !_isMasteryCategory(chapter))
        .where((chapter) => _chapterNumber(chapter) <= chapterNumber)
        .toList(growable: false);
  }

  static ChapterReleaseGateResult validateCurriculumJourney() {
    final failures = <String>[];
    final fixPlan = <String>[];
    final guidedDiscovery =
        groupedLevels.where((category) => !category.isMasteryPhase).toList();
    final masteryPhases =
        groupedLevels.where((category) => category.isMasteryPhase).toList();

    if (guidedDiscovery.length != 12) {
      failures.add(
        '[Level System Validation] Phase 1 expected 12 guided discovery chapters but found ${guidedDiscovery.length}.',
      );
      fixPlan
          .add('Keep Chapters 1-12 as the Phase 1 concept acquisition path.');
    }
    if (masteryPhases.length != 1) {
      failures.add(
        '[Level System Validation] Phase 2 expected one Mastery Challenges section but found ${masteryPhases.length}.',
      );
      fixPlan.add(
          'Represent the existing 54 challenge levels as one Phase 2 integration section.');
    }

    final mastery = masteryPhases.isEmpty ? null : masteryPhases.first;
    if (mastery != null) {
      final masteryCount = mastery.to - mastery.from + 1;
      if (masteryCount != 54) {
        failures.add(
          '[Level System Validation] Phase 2 expected 54 Mastery Challenges but found $masteryCount.',
        );
        fixPlan.add(
            'Preserve the existing 54 challenge levels without redesigning their gameplay.');
      }
      if (mastery.from != 60) {
        failures.add(
          '[Level System Validation] Phase 2 should begin immediately after Chapter 12 at level 61.',
        );
        fixPlan.add(
            'Place Mastery Challenges after the 60 guided discovery levels.');
      }
      if (mastery.phasePurpose != 'Concept Integration') {
        failures.add(
          '[Cross-System Consistency Check] Phase 2 purpose must be Concept Integration.',
        );
        fixPlan
            .add('Set Mastery Challenges phasePurpose to Concept Integration.');
      }

      for (int index = mastery.from; index <= mastery.to; index++) {
        final levelNumber = index + 1;
        final level = getHistoricalMasteryById(levelNumber);
        if (level == null) {
          failures.add(
            '[Level System Validation] Missing Mastery Challenge $levelNumber.',
          );
          fixPlan.add(
              'Correct the Mastery Challenges range or restore the missing level.');
          continue;
        }
        if (level.conceptsUsed.isEmpty) {
          failures.add(
            '[Notebook System Validation] Mastery Challenge $levelNumber has no Concepts Used metadata.',
          );
          fixPlan
              .add('Add lightweight concept tags to every Mastery Challenge.');
        }
        if (level.difficulty?.trim().isEmpty ?? true) {
          failures.add(
            '[Level System Validation] Mastery Challenge $levelNumber has no difficulty metadata.',
          );
          fixPlan.add(
              'Add Beginner, Intermediate, Advanced, or Expert difficulty metadata.');
        }
        if (level.relatedDiscoveryTitles.isEmpty) {
          failures.add(
            '[Notebook System Validation] Mastery Challenge $levelNumber has no related discoveries.',
          );
          fixPlan.add(
              'Connect every Mastery Challenge to existing notebook discoveries.');
        }
        for (final discoveryTitle in level.relatedDiscoveryTitles) {
          if (!notebookEntriesByDiscoveryTitle.containsKey(discoveryTitle)) {
            failures.add(
              '[Notebook System Validation] Mastery Challenge $levelNumber links to unknown discovery "$discoveryTitle".',
            );
            fixPlan.add(
                'Use relatedDiscoveryTitles that already exist in the Quantum Notebook.');
          }
        }
      }
    }

    if (groupedLevels.isNotEmpty && !groupedLevels.last.isMasteryPhase) {
      failures.add(
        '[Learning Map Integration] The journey should end by flowing into Mastery Challenges.',
      );
      fixPlan.add('Keep Mastery Challenges after Chapter 12 in groupedLevels.');
    }

    return ChapterReleaseGateResult(
      chapterName: 'Qubit Quest Continuous Curriculum',
      validatedSections: const [
        'Phase 1 Concept Acquisition',
        'Phase 2 Concept Integration',
        'Notebook Reference Integration',
        'Learning Map Continuity',
        'Cross-System Consistency Check',
      ],
      failures: failures,
      fixPlan: failures.isEmpty ? const [] : fixPlan.toSet().toList(),
    );
  }

  static bool _isMasteryCategory(QQLevelsCategory chapter) {
    return chapter.isMasteryPhase || chapter.groupName == 'Mastery Challenges';
  }

  static int _chapterNumber(QQLevelsCategory chapter) {
    final match = RegExp(r'^Chapter\s+(\d+)\b').firstMatch(chapter.groupName);
    return int.tryParse(match?.group(1) ?? '') ?? -1;
  }

  static List<QQLevel> _levelsFor(
    QQLevelsCategory chapter,
    List<String> failures,
    List<String> fixPlan,
  ) {
    if (chapter.from > chapter.to) {
      failures.add(
        '[Level System Validation] ${chapter.groupName} has an invalid range: ${chapter.from}..${chapter.to}.',
      );
      fixPlan.add('Fix the groupedLevels range for ${chapter.groupName}.');
      return const [];
    }

    final levels = <QQLevel>[];
    for (int index = chapter.from; index <= chapter.to; index++) {
      final level = getJourneyLessonById(index + 1);
      if (level == null) {
        failures.add(
          '[Level System Validation] Missing level ${index + 1} in ${chapter.groupName}.',
        );
        fixPlan.add(
          'Add the missing level or correct the groupedLevels range for ${chapter.groupName}.',
        );
        continue;
      }
      levels.add(level);
    }
    return levels;
  }

  static void _validateLevelSystem(
    QQLevelsCategory chapter,
    List<QQLevel> levels,
    List<String> failures,
    List<String> fixPlan,
  ) {
    final expectedCount = chapter.to - chapter.from + 1;
    if (levels.length != expectedCount) {
      failures.add(
        '[Level System Validation] ${chapter.groupName} expected $expectedCount levels but resolved ${levels.length}.',
      );
    }

    final discoveryTitles = <String>{};
    final visibleTitles = <String>{};
    for (int offset = 0; offset < levels.length; offset++) {
      final levelNumber = chapter.from + offset + 1;
      final level = levels[offset];

      final title = level.title?.trim();
      if (title == null || title.isEmpty) {
        failures.add(
          '[Level System Validation] Level $levelNumber in ${chapter.groupName} has no display title.',
        );
        fixPlan.add('Add a display title to every released chapter level.');
      } else if (!visibleTitles.add(title)) {
        failures.add(
          '[Level System Validation] Duplicate active level title "$title" in ${chapter.groupName}.',
        );
        fixPlan.add('Remove or rename duplicate active levels before release.');
      }

      if (level.taskDescription.trim().isEmpty) {
        failures.add(
          '[Level System Validation] Level $levelNumber in ${chapter.groupName} has an empty task description.',
        );
        fixPlan.add('Add a beginner-facing task description to every level.');
      }

      final discoveryTitle = level.discoveryTitle?.trim();
      if (discoveryTitle == null || discoveryTitle.isEmpty) {
        failures.add(
          '[Level System Validation] Level $levelNumber in ${chapter.groupName} has no discoveryTitle.',
        );
        fixPlan.add(
          'Every released chapter level must unlock one notebook discovery.',
        );
      } else if (!discoveryTitles.add(discoveryTitle)) {
        failures.add(
          '[Level System Validation] Duplicate discovery "$discoveryTitle" inside ${chapter.groupName}.',
        );
        fixPlan.add(
          'Ensure each released level maps to a distinct discovery entry.',
        );
      }
    }
  }

  static void _validateNotebookSystem(
    QQLevelsCategory chapter,
    List<QQLevel> levels,
    List<String> failures,
    List<String> fixPlan,
  ) {
    final levelDiscoveryTitles = [
      for (final level in levels)
        if (level.discoveryTitle?.trim().isNotEmpty ?? false)
          level.discoveryTitle!.trim(),
    ];

    final chapterEntries = notebookEntries
        .where((entry) => entry.chapterTitle == chapter.groupName)
        .toList(growable: false);

    if (chapterEntries.length != levelDiscoveryTitles.length) {
      failures.add(
        '[Notebook System Validation] ${chapter.groupName} has ${levelDiscoveryTitles.length} level discoveries but ${chapterEntries.length} notebook entries.',
      );
      fixPlan.add(
        'Add missing notebook entries or remove orphan entries so the notebook matches level progression.',
      );
    }

    for (final discoveryTitle in levelDiscoveryTitles) {
      final entry = notebookEntriesByDiscoveryTitle[discoveryTitle];
      if (entry == null) {
        failures.add(
          '[Notebook System Validation] Discovery "$discoveryTitle" has no notebook entry.',
        );
        fixPlan.add(
          'Register a NotebookEntry keyed by discoveryTitle "$discoveryTitle".',
        );
        continue;
      }
      if (entry.chapterTitle != chapter.groupName) {
        failures.add(
          '[Notebook System Validation] Discovery "$discoveryTitle" is grouped under "${entry.chapterTitle}" instead of "${chapter.groupName}".',
        );
        fixPlan.add('Correct the NotebookEntry chapterTitle/chapterIndex.');
      }
      if (!DiscoveryProgress.discoveryOrder.contains(discoveryTitle)) {
        failures.add(
          '[Notebook System Validation] Discovery "$discoveryTitle" is missing from DiscoveryProgress.discoveryOrder.',
        );
        fixPlan.add(
          'Register "$discoveryTitle" in DiscoveryProgress.discoveryOrder.',
        );
      }
      _validateNotebookEntryContent(entry, failures, fixPlan);
    }

    final entryDiscoveryTitles = [
      for (final entry in chapterEntries) entry.discoveryTitle,
    ];
    if (!_sameOrder(levelDiscoveryTitles, entryDiscoveryTitles)) {
      failures.add(
        '[Notebook System Validation] Notebook ordering for ${chapter.groupName} does not match level progression.',
      );
      fixPlan.add(
        'Order notebook entries in the same sequence as the chapter levels.',
      );
    }

    for (final entry in chapterEntries) {
      if (!levelDiscoveryTitles.contains(entry.discoveryTitle)) {
        failures.add(
          '[Notebook System Validation] Orphan notebook entry "${entry.discoveryTitle}" exists in ${chapter.groupName} without a matching level.',
        );
        fixPlan.add(
          'Remove the orphan entry or connect it to an active level discoveryTitle.',
        );
      }
    }
  }

  static void _validateNotebookEntryContent(
    NotebookEntry entry,
    List<String> failures,
    List<String> fixPlan,
  ) {
    if (entry.title.trim().isEmpty ||
        entry.summary.trim().isEmpty ||
        entry.intuition.body.trim().isEmpty ||
        (entry.whatChanged?.body.trim().isEmpty ?? true) ||
        (entry.quantumView?.body.trim().isEmpty ?? true)) {
      failures.add(
        '[Notebook System Validation] Notebook entry "${entry.discoveryTitle}" is missing required display content.',
      );
      fixPlan.add(
        'Complete title, summary, intuition, What Changed, and Quantum View for each notebook entry.',
      );
    }
    for (final relatedTitle in entry.relatedDiscoveryTitles) {
      if (!DiscoveryProgress.discoveryOrder.contains(relatedTitle)) {
        failures.add(
          '[Notebook System Validation] Notebook entry "${entry.discoveryTitle}" links to unknown related discovery "$relatedTitle".',
        );
        fixPlan.add(
          'Use related discovery titles that exist in DiscoveryProgress.discoveryOrder.',
        );
      }
    }
  }

  static void _validateUiConsistency(
    QQLevelsCategory chapter,
    List<QQLevel> levels,
    List<String> failures,
    List<String> fixPlan,
  ) {
    for (int offset = 0; offset < levels.length; offset++) {
      final levelNumber = chapter.from + offset + 1;
      final level = levels[offset];
      final routeKind = LevelUIRouter.routeKindFor(level);
      final headerKind = LevelHeaderRouter.headerKindFor(level);

      final routeMatches = switch (level) {
        ComposerLevel _ => routeKind == LevelUIRouteKind.composer,
        ConceptCheckLevel _ ||
        McqLevel _ =>
          routeKind == LevelUIRouteKind.conceptCheck,
        FillTheGateLevel _ => routeKind == LevelUIRouteKind.fillGate,
        CircuitReadingLevel _ => routeKind == LevelUIRouteKind.circuitReading,
        MeasurementLabLevel _ => routeKind == LevelUIRouteKind.measurementLab,
      };
      final headerMatches = switch (level) {
        ComposerLevel _ => headerKind == LevelHeaderKind.composer,
        ConceptCheckLevel _ ||
        McqLevel _ =>
          headerKind == LevelHeaderKind.conceptCheck,
        FillTheGateLevel _ => headerKind == LevelHeaderKind.fillGate,
        CircuitReadingLevel _ => headerKind == LevelHeaderKind.reading,
        MeasurementLabLevel _ => headerKind == LevelHeaderKind.experiment,
      };

      if (!routeMatches) {
        failures.add(
          '[UI Consistency Validation] Level $levelNumber (${level.runtimeType}) resolves to the wrong LevelUIRouter route: $routeKind.',
        );
        fixPlan.add(
          'Update LevelUIRouter so UI selection is based on QQLevel runtime type.',
        );
      }
      if (!headerMatches) {
        failures.add(
          '[UI Consistency Validation] Level $levelNumber (${level.runtimeType}) resolves to the wrong header route: $headerKind.',
        );
        fixPlan.add(
          'Update LevelHeaderRouter so each level type owns its header.',
        );
      }
    }
  }

  static void _validateLearningMap(
    QQLevelsCategory chapter,
    List<String> failures,
    List<String> fixPlan,
  ) {
    final campaignChapters = groupedLevels
        .where((category) => !_isMasteryCategory(category))
        .toList();
    final chapterNumber = _chapterNumber(chapter);

    if (!campaignChapters.contains(chapter)) {
      failures.add(
        '[Learning Map Integration] ${chapter.groupName} is not present in groupedLevels campaign chapters.',
      );
      fixPlan.add(
        'Add the chapter to groupedLevels before Mastery Challenges so the Learning Map can render it.',
      );
    }

    final chapterEntries = notebookEntries
        .where((entry) => entry.chapterTitle == chapter.groupName)
        .toList(growable: false);
    if (chapterEntries.isEmpty ||
        chapterEntries.first.chapterIdentity.isEmpty) {
      failures.add(
        '[Learning Map Integration] ${chapter.groupName} has no chapterIdentity available through notebook metadata.',
      );
      fixPlan.add(
        'Add chapterIdentity metadata for this chapter and at least one notebook entry.',
      );
    }

    for (final link in LearningMapScreen.conceptLinks) {
      if (link.fromChapter < 1 ||
          link.toChapter < 1 ||
          link.fromChapter > campaignChapters.length ||
          (!link.targetsMastery && link.toChapter > campaignChapters.length)) {
        failures.add(
          '[Learning Map Integration] Concept link ${link.label} references a missing chapter.',
        );
        fixPlan.add(
          'Update LearningMapScreen.conceptLinks so every link references an existing guided discovery chapter.',
        );
      }
    }

    if (chapterNumber >= 7) {
      final hasGhzDependency = LearningMapScreen.conceptLinks
          .any((link) => link.fromChapter == 5 && link.toChapter == 7);
      if (!hasGhzDependency) {
        failures.add(
          '[Learning Map Integration] Missing Chapter 5 -> Chapter 7 conceptual dependency link.',
        );
        fixPlan.add(
          'Restore the entanglement-to-GHZ concept link in the Learning Map.',
        );
      }
    }
  }

  static void _validateCrossSystemConsistency(
    QQLevelsCategory chapter,
    List<QQLevel> levels,
    List<String> failures,
    List<String> fixPlan,
  ) {
    for (final level in levels) {
      final discoveryTitle = level.discoveryTitle?.trim();
      if (discoveryTitle == null || discoveryTitle.isEmpty) continue;

      final notebookEntry = notebookEntriesByDiscoveryTitle[discoveryTitle];
      if (notebookEntry == null) continue;

      final levelText = [
        level.title,
        level.taskDescription,
        level.discoveryText,
        level.keyInsight,
        level.whyItMatters,
      ].whereType<String>().join(' ').toLowerCase();
      final notebookText = [
        notebookEntry.title,
        notebookEntry.summary,
        notebookEntry.intuition.body,
        notebookEntry.whatChanged?.body,
        notebookEntry.quantumView?.body,
      ].whereType<String>().join(' ').toLowerCase();

      final chapterKeywords = _chapterKeywords(chapter.groupName);
      if (chapterKeywords.isNotEmpty &&
          !chapterKeywords.any(levelText.contains) &&
          !chapterKeywords.any(notebookText.contains)) {
        failures.add(
          '[Cross-System Consistency Check] Discovery "$discoveryTitle" does not reference the core chapter concept in level or notebook text.',
        );
        fixPlan.add(
          'Align level copy and notebook copy with the chapter core concept.',
        );
      }
      _validateChapterForbiddenOverlap(
        chapter.groupName,
        discoveryTitle,
        '$levelText $notebookText',
        failures,
        fixPlan,
      );
    }
  }

  static void _validateChapterForbiddenOverlap(
    String chapterName,
    String discoveryTitle,
    String text,
    List<String> failures,
    List<String> fixPlan,
  ) {
    for (final term in _forbiddenOverlapTerms(chapterName)) {
      if (!text.contains(term)) continue;
      failures.add(
        '[Cross-System Consistency Check] Discovery "$discoveryTitle" uses forbidden overlap term "$term" for $chapterName.',
      );
      fixPlan.add(
        'Reword $chapterName around its core abstraction and remove "$term" from learner-facing framing.',
      );
    }
  }

  static void _validateMisconceptionSafety(
    QQLevelsCategory chapter,
    List<QQLevel> levels,
    List<String> failures,
    List<String> fixPlan,
  ) {
    final notebookTextParts = <String>[];
    for (final level in levels) {
      final title = level.discoveryTitle?.trim();
      if (title == null || title.isEmpty) continue;

      final entry = notebookEntriesByDiscoveryTitle[title];
      if (entry == null) continue;

      notebookTextParts.addAll([
        entry.summary,
        entry.intuition.body,
        entry.whatChanged?.body,
        entry.quantumView?.body,
        entry.advancedNotes?.body,
      ].whereType<String>());
    }
    final chapterText = notebookTextParts.join(' ').toLowerCase();

    final requiredTerms = _misconceptionSafetyTerms(chapter.groupName);
    for (final term in requiredTerms) {
      if (!chapterText.contains(term)) {
        failures.add(
          '[Misconception Safety Check] ${chapter.groupName} notebook coverage does not address "$term".',
        );
        fixPlan.add(
          'Add concise notebook reinforcement that directly addresses "$term".',
        );
      }
    }
  }

  static List<String> _chapterKeywords(String chapterName) {
    if (chapterName.contains('Phase Kickback')) {
      return const ['kickback', 'controlled', 'phase'];
    }
    if (chapterName.contains('Oracle Thinking')) {
      return const ['oracle', 'function', 'rule'];
    }
    if (chapterName.contains('Amplitude Amplification')) {
      return const ['probability', 'likelihood', 'amplification'];
    }
    if (chapterName.contains('Grover Loop Intuition')) {
      return const ['iteration', 'repeat', 'probability'];
    }
    if (chapterName.contains('Quantum Algorithm Structure')) {
      return const ['algorithm', 'structure', 'probability'];
    }
    if (chapterName.contains('GHZ')) {
      return const ['ghz', 'global', 'constraint'];
    }
    if (chapterName.contains('Information Flow')) {
      return const ['information', 'control', 'swap'];
    }
    if (chapterName.contains('Interference')) {
      return const ['interference', 'phase'];
    }
    if (chapterName.contains('Entanglement')) {
      return const ['entanglement', 'bell'];
    }
    return const [];
  }

  static List<String> _misconceptionSafetyTerms(String chapterName) {
    if (chapterName.contains('Phase Kickback')) {
      return const [
        'interference reveals',
        'not measurement',
        'not entanglement',
        'not ghz',
        'control',
      ];
    }
    if (chapterName.contains('GHZ')) {
      return const [
        'allowed',
        'forbidden',
        'full register',
      ];
    }
    if (chapterName.contains('Oracle Thinking')) {
      return const [
        'function',
        'rule',
        'valid',
        'invalid',
      ];
    }
    if (chapterName.contains('Amplitude Amplification')) {
      return const [
        'probability',
        'likelihood',
        'valid',
        'distribution',
        'not just finding',
      ];
    }
    if (chapterName.contains('Grover Loop Intuition')) {
      return const [
        'iteration',
        'repeated',
        'probability',
        'likelihood',
        'oracle',
        'amplification',
      ];
    }
    if (chapterName.contains('Quantum Algorithm Structure')) {
      return const [
        'define',
        'bias',
        'iterate',
        'structured',
        'valid',
        'probability',
      ];
    }
    return const [];
  }

  static List<String> _forbiddenOverlapTerms(String chapterName) {
    if (chapterName.contains('Oracle Thinking')) {
      return const [
        'phase kickback',
        'kickback',
        'interference',
        'entanglement',
        'ghz',
        'global constraint',
        'swap',
        'routing',
      ];
    }
    if (chapterName.contains('Amplitude Amplification')) {
      return const [
        'phase kickback',
        'kickback',
        'phase',
        'interference',
        'oracle',
        'diffuser',
        'cz',
        'gate',
        'circuit construction',
        'controlled operation',
        'entanglement',
        'ghz',
        'global constraint',
        'swap',
        'routing',
      ];
    }
    if (chapterName.contains('Grover Loop Intuition')) {
      return const [
        'phase kickback',
        'kickback',
        'phase',
        'interference',
        'diffuser',
        'cz',
        'gate',
        'circuit',
        'controlled operation',
        'entanglement',
        'ghz',
        'global constraint',
        'swap',
        'routing',
      ];
    }
    if (chapterName.contains('Quantum Algorithm Structure')) {
      return const [
        'grover',
        'phase kickback',
        'kickback',
        'phase',
        'interference',
        'diffuser',
        'cz',
        'gate',
        'circuit',
        'physics',
        'mechanics',
        'mechanism',
        'controlled operation',
        'entanglement',
        'ghz',
        'global constraint',
        'swap',
        'routing',
      ];
    }
    return const [];
  }

  static bool _sameOrder(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (int i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }
}
