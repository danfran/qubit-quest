import 'package:flutter/material.dart';
import 'package:quantumquiz/models/composer_policy.dart';
import 'package:quantumquiz/models/composer_session.dart';
import 'package:quantumquiz/models/mastery_2_presentation.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/activity_instruction_presentation.dart';
import 'package:quantumquiz/widgets/composer_workspace/composer_session_workspace.dart';
import 'package:quantumquiz/widgets/composer_workspace/laboratory_composer_workspace.dart'
    show LaboratoryComposerWorkspace;
import 'package:quantumquiz/widgets/composer_workspace/workspace_layout_state.dart';
import 'package:quantumquiz/widgets/mastery_evidence_view.dart';
import 'package:quantumquiz/widgets/web_learning_text.dart';

/// Test seam (v2.6 M11D): exercises use the learning layout; tests that
/// verify the classic three-column exercise layout switch it back.
@visibleForTesting
bool debugClassicExerciseLayout = false;

// ── Check feedback ──────────────────────────────────────────────────────────

/// What an explicit Check reported. Feedback never changes the circuit,
/// its history or progress; the next committed edit clears it.
@immutable
class ExerciseCheckFeedback {
  const ExerciseCheckFeedback._(this.success, this.message);
  final bool success;
  final String message;

  static const ExerciseCheckFeedback correct =
      ExerciseCheckFeedback._(true, 'Correct circuit.');

  /// Learner-facing explanation of a failed Check, from the level's own
  /// evaluator result. It names what the evaluator compares (exact state,
  /// state up to global phase, or action on every input) without revealing
  /// a solution.
  factory ExerciseCheckFeedback.failure(
    ComposerLevel level,
    ComposerValidationResult result,
  ) {
    if (result.explicitConstraint == 'valid circuit metadata') {
      return ExerciseCheckFeedback._(
          false, 'Not quite yet: ${result.finalReason}');
    }
    final message = switch (level.validationMode) {
      ValidationMode.finalState => result.globalPhaseMatches
          ? 'Not quite yet. Your state differs from the target only by a '
              'global phase (an overall factor such as −1). This activity '
              'checks the exact amplitudes, so keep investigating.'
          : 'Not quite yet. Your final state does not match the target. '
              'Compare the current and target states in Results, then keep '
              'editing.',
      ValidationMode.physicalState => 'Not quite yet. Your final state is '
          'not the target state, even allowing for a global phase. Compare '
          'the amplitudes and their relative phases in Results.',
      ValidationMode.unitary => 'Not quite yet. This activity checks what '
          'the circuit does to every input state, not only the one shown. '
          'Your circuit acts differently on at least one input.',
    };
    return ExerciseCheckFeedback._(false, message);
  }
}

// ── Lesson/challenge context header ─────────────────────────────────────────

/// Compact educational context shared by Journey lessons and Mastery
/// challenges: return action, identity, title, the objective, and an
/// expandable section for longer context (concept introduction, evidence,
/// mystery text). Keeps the objective visible while the learner works.
class WebActivityContextHeader extends StatefulWidget {
  const WebActivityContextHeader({
    super.key,
    required this.backKey,
    required this.backTooltip,
    required this.onBack,
    required this.breadcrumb,
    required this.level,
    this.presentation,
    this.showInstruction = true,
    this.trailing,
    this.status,
    this.breadcrumbInfo,
    this.objectiveKey = const ValueKey('web-compact-task'),
    this.compact = false,
    this.compactNavigation,
  });

  /// Narrow hosts (v2.6 M11D.1): one row for back navigation and position
  /// ([compactNavigation] replaces the breadcrumb and [trailing]); the
  /// title with a status icon; the question; the task with its label above
  /// it so the text keeps the full width. Shown in the page's scroll.
  final bool compact;
  final Widget? compactNavigation;

  final Key backKey;
  final String backTooltip;
  final VoidCallback onBack;
  final String breadcrumb;
  final QQLevel level;
  final MasteryChallengePresentation? presentation;

  /// False when the page body presents the full instruction itself (for
  /// example a Mastery concept check whose evidence is the question).
  final bool showInstruction;

  /// Position and progress (lesson chooser, previous/next).
  final Widget? trailing;

  /// Short state label, e.g. "Completed · review".
  final String? status;

  /// Optional description shown as a tooltip beside the breadcrumb.
  final String? breadcrumbInfo;
  final Key objectiveKey;

  @override
  State<WebActivityContextHeader> createState() =>
      _WebActivityContextHeaderState();
}

class _WebActivityContextHeaderState extends State<WebActivityContextHeader> {
  late bool _expanded = _evidenceIsEssential;

  MasteryChallengePresentation? get _p => widget.presentation;

  /// Mastery evidence can be part of the task itself; it starts open,
  /// except beside a circuit workspace, where the circuit already shows the
  /// fixed operations and the evidence stays one tap away (v2.6 M11D).
  bool get _evidenceIsEssential =>
      (_p?.evidence.isNotEmpty ?? false) && widget.level is! ComposerLevel;

  bool get _hasDetails {
    final p = _p;
    return (widget.level.conceptIntro ?? '').trim().isNotEmpty ||
        (widget.level.mysteryText ?? '').trim().isNotEmpty ||
        (p != null &&
            (p.evidence.isNotEmpty ||
                p.intro != null ||
                p.helperText != null ||
                p.instructionAfterEvidence.isNotEmpty));
  }

  @override
  void didUpdateWidget(covariant WebActivityContextHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.level, widget.level)) {
      _expanded = _evidenceIsEssential;
    }
  }

  Widget _details(BuildContext context) {
    final level = widget.level;
    final p = _p;
    final hasEvidence = p != null &&
        (p.evidence.isNotEmpty || p.intro != null || p.helperText != null);
    return ConstrainedBox(
      constraints: BoxConstraints(
          maxHeight: widget.compact
              ? double.infinity
              : MediaQuery.sizeOf(context).height * .32),
      child: SingleChildScrollView(
        key: const ValueKey('web-activity-details'),
        padding: const EdgeInsets.only(top: 8, right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if ((level.conceptIntro ?? '').trim().isNotEmpty) ...[
              const Text('Concept', style: QubitQuestTypography.label),
              const SizedBox(height: QubitQuestSpacing.micro),
              WebLearningText(level.conceptIntro!,
                  role: WebLearningTextRole.concept),
              const SizedBox(height: QubitQuestSpacing.compact),
            ],
            if (hasEvidence) ...[
              MasteryEvidenceView(
                presentation: p,
                includeInstruction: false,
                webLearning: true,
              ),
              const SizedBox(height: QubitQuestSpacing.compact),
            ],
            if (p != null && p.instructionAfterEvidence.isNotEmpty) ...[
              WebLearningText(p.instructionAfterEvidence,
                  role: WebLearningTextRole.task),
              const SizedBox(height: QubitQuestSpacing.compact),
            ],
            if ((level.mysteryText ?? '').trim().isNotEmpty)
              WebLearningText(level.mysteryText!,
                  role: WebLearningTextRole.supporting),
          ],
        ),
      ),
    );
  }

  Widget _compact(BuildContext context) {
    final p = _p;
    final instructions = normalizeActivityInstructions(
      task: p?.instruction ?? widget.level.taskDescription,
      question: p?.question ?? widget.level.mysteryTitle,
    );
    return Padding(
      key: const ValueKey('web-compact-activity-header'),
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      child: Column(
        key: const ValueKey('web-compact-activity-context'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                key: widget.backKey,
                tooltip: widget.backTooltip,
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: widget.compactNavigation ??
                    Text(widget.breadcrumb,
                        key: const ValueKey('web-activity-breadcrumb'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: QqType.breadcrumb),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.level.title ?? 'Quantum Challenge',
                        key: const ValueKey('web-lesson-title'),
                        style: QqType.activityTitle.copyWith(fontSize: 20),
                      ),
                    ),
                    if (widget.status != null)
                      Tooltip(
                        message: widget.status!,
                        child: Padding(
                          key: const ValueKey('web-activity-status'),
                          padding: const EdgeInsets.only(left: 8, top: 4),
                          child: Semantics(
                            label: widget.status,
                            child: const Icon(Icons.check_circle_rounded,
                                size: 18, color: QubitQuestColors.success),
                          ),
                        ),
                      ),
                  ],
                ),
                if (widget.showInstruction) ...[
                  if (instructions.question.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    WebLearningText(instructions.question,
                        key: const ValueKey('web-compact-question'),
                        style: QqType.question.copyWith(fontSize: 16)),
                  ],
                  if (instructions.task.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _TaskCallout(
                      label: 'Task',
                      stacked: true,
                      child: WebLearningText(instructions.task,
                          key: widget.objectiveKey, style: QqType.task),
                    ),
                  ],
                  if (_hasDetails) ...[
                    TextButton.icon(
                      key: const ValueKey('web-activity-details-toggle'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      onPressed: () => setState(() => _expanded = !_expanded),
                      icon: Icon(
                          _expanded
                              ? Icons.expand_less
                              : Icons.chevron_right_rounded,
                          size: 18),
                      label: Text(_expanded
                          ? 'Hide context'
                          : p != null && p.evidence.isNotEmpty
                              ? 'Show evidence and context'
                              : 'More context'),
                    ),
                    if (_expanded) _details(context),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) return _compact(context);
    final p = _p;
    final instructions = normalizeActivityInstructions(
      task: p?.instruction ?? widget.level.taskDescription,
      question: p?.question ?? widget.level.mysteryTitle,
    );
    final title = Text(
      widget.level.title ?? 'Quantum Challenge',
      key: const ValueKey('web-lesson-title'),
      style: QqType.activityTitle,
    );
    final status = widget.status == null
        ? null
        : Container(
            key: const ValueKey('web-activity-status'),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: QubitQuestRadii.pill,
              border: Border.all(
                  color: QubitQuestColors.success.withValues(alpha: .6)),
            ),
            child: Text(widget.status!,
                style: QqType.meta
                    .copyWith(color: QubitQuestColors.success, fontSize: 12.5)),
          );
    // Never more than half the viewport: the workspace and its Check action
    // keep their room; longer context scrolls inside the header.
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .5),
      child: SingleChildScrollView(
        key: const ValueKey('web-activity-header-scroll'),
        child: Padding(
          key: const ValueKey('web-compact-activity-header'),
          padding: const EdgeInsets.fromLTRB(12, 12, 20, 14),
          child: LayoutBuilder(builder: (context, constraints) {
            // Narrow: position/progress move below the title instead of beside it.
            final stacked = constraints.maxWidth < 640;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  key: widget.backKey,
                  tooltip: widget.backTooltip,
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: ConstrainedBox(
                      // A reading width for the question and the task.
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: Column(
                        key: const ValueKey('web-compact-activity-context'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 10,
                            runSpacing: 4,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.breadcrumb,
                                      key: const ValueKey(
                                          'web-activity-breadcrumb'),
                                      overflow: TextOverflow.ellipsis,
                                      style: QqType.breadcrumb,
                                    ),
                                  ),
                                  if ((widget.breadcrumbInfo ?? '')
                                      .trim()
                                      .isNotEmpty)
                                    Tooltip(
                                      key: const ValueKey(
                                          'web-chapter-description'),
                                      message: widget.breadcrumbInfo!,
                                      child: const Padding(
                                        padding: EdgeInsets.only(left: 6),
                                        child: Icon(Icons.info_outline,
                                            size: 16,
                                            color: QubitQuestColors.textMuted),
                                      ),
                                    ),
                                ],
                              ),
                              if (status != null) status,
                            ],
                          ),
                          if (stacked && widget.trailing != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: widget.trailing,
                              ),
                            ),
                          const SizedBox(height: 4),
                          title,
                          if (widget.showInstruction) ...[
                            if (instructions.question.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              WebLearningText(instructions.question,
                                  key: const ValueKey('web-compact-question'),
                                  style: QqType.question),
                            ],
                            if (instructions.task.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _TaskCallout(
                                label: p == null ? 'Task' : 'Task',
                                child: WebLearningText(instructions.task,
                                    key: widget.objectiveKey,
                                    style: QqType.task),
                              ),
                            ],
                            if (_hasDetails) ...[
                              const SizedBox(height: 4),
                              TextButton.icon(
                                key: const ValueKey(
                                    'web-activity-details-toggle'),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                ),
                                onPressed: () =>
                                    setState(() => _expanded = !_expanded),
                                icon: Icon(
                                    _expanded
                                        ? Icons.expand_less
                                        : Icons.chevron_right_rounded,
                                    size: 18),
                                label: Text(_expanded
                                    ? 'Hide context'
                                    : p != null && p.evidence.isNotEmpty
                                        ? 'Show evidence and context'
                                        : 'More context · concept and notation'),
                              ),
                              if (_expanded) _details(context),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (!stacked && widget.trailing != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: widget.trailing,
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// The task, visibly distinct from explanation: a labelled block with an
/// accent rule (M11B prototype 6).
class _TaskCallout extends StatelessWidget {
  const _TaskCallout(
      {required this.label, required this.child, this.stacked = false});
  final String label;
  final Widget child;

  /// The label above the text (narrow widths) instead of beside it.
  final bool stacked;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('web-task-callout'),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
        decoration: const BoxDecoration(
          color: QubitQuestSurfaces.work,
          borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
          border: Border(
            left:
                BorderSide(color: QubitQuestColors.accentInteractive, width: 3),
          ),
        ),
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(label.toUpperCase(),
                      style: QqType.panelHeading.copyWith(fontSize: 11.5)),
                  const SizedBox(height: 4),
                  child,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 14),
                    child: Text(label.toUpperCase(),
                        style: QqType.panelHeading.copyWith(fontSize: 11.5)),
                  ),
                  Expanded(child: child),
                ],
              ),
      );
}

// ── Success presentation ────────────────────────────────────────────────────

/// Existing completion content (explanation, discovery, Notebook update)
/// with the path onward. Shown only after a successful explicit Check.
class WebActivitySuccessPanel extends StatelessWidget {
  const WebActivitySuccessPanel({
    super.key,
    required this.level,
    required this.isMastery,
    required this.onOpenNotebook,
    this.onOpenNotebookEntry,
    required this.onNext,
    this.onBack,
    this.backLabel,
  });
  final QQLevel level;
  final bool isMastery;
  final VoidCallback onOpenNotebook;
  final ValueChanged<String>? onOpenNotebookEntry;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final String? backLabel;

  @override
  Widget build(BuildContext context) {
    final notebook = (level.discoveryTitle ?? '').trim().isNotEmpty &&
        notebookEntriesByDiscoveryTitle.containsKey(level.discoveryTitle);
    return Container(
      key: const ValueKey('web-lesson-success'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10251F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: .55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.greenAccent),
              const SizedBox(width: 9),
              Text(
                isMastery ? 'Challenge Complete' : 'Lesson Complete',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if ((level.solutionExplanation ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(level.solutionExplanation!,
                style: const TextStyle(height: 1.45)),
          ],
          if (level.hasDiscovery) ...[
            const SizedBox(height: 14),
            Text(
              level.discoveryTitle ?? 'Discovery',
              style: const TextStyle(
                  color: QubitQuestColors.accentInteractive,
                  fontWeight: FontWeight.w900),
            ),
            if ((level.discoveryText ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(level.discoveryText!, style: const TextStyle(height: 1.45)),
            ],
            if ((level.keyInsight ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Key takeaway: ${level.keyInsight!}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ],
          if ((level.whyItMatters ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(level.whyItMatters!,
                style: const TextStyle(color: Colors.white70)),
          ],
          if ((level.nextMystery ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Next mystery: ${level.nextMystery!}',
              style: const TextStyle(
                  color: QubitQuestColors.accentStrong,
                  fontWeight: FontWeight.w700),
            ),
          ],
          if (notebook) ...[
            const SizedBox(height: 12),
            Text('Notebook updated: ${level.discoveryTitle}',
                key: const ValueKey('web-notebook-updated')),
          ],
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 8,
            children: [
              if (onBack != null)
                TextButton(
                  key: const ValueKey('web-activity-success-back'),
                  onPressed: onBack,
                  child: Text(backLabel ?? 'Back'),
                ),
              if (notebook)
                OutlinedButton.icon(
                  key: const ValueKey('web-open-notebook'),
                  onPressed: () {
                    final discoveryTitle = level.discoveryTitle;
                    if (discoveryTitle != null && onOpenNotebookEntry != null) {
                      onOpenNotebookEntry!(discoveryTitle);
                    } else {
                      onOpenNotebook();
                    }
                  },
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('Open Notebook'),
                ),
              FilledButton.icon(
                key: const ValueKey('web-next-lesson'),
                onPressed: onNext,
                icon: const Icon(Icons.arrow_forward),
                label: Text(isMastery ? 'Next Challenge' : 'Next Lesson'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Circuit exercise host ───────────────────────────────────────────────────

/// A Journey circuit lesson or Mastery circuit challenge in the shared
/// desktop Composer workspace (v2.6 M6a).
///
/// The host owns educational orchestration only: one exercise
/// [ComposerSession] (never persisted, never the Sandbox's), hint
/// sequencing, the explicit Check and completion. Editing, simulation,
/// undo/redo, restrictions and results are the shared session's and
/// workspace's.
///
/// Completion contract: only [_check] can complete the exercise. Reaching
/// the target while editing updates the live results but reports nothing,
/// writes no progress and shows no success.
class WebComposerExercise extends StatefulWidget {
  const WebComposerExercise({
    super.key,
    required this.level,
    required this.mode,
    required this.contextLabel,
    required this.onCompleted,
    required this.onNext,
    required this.onOpenNotebook,
    this.onOpenNotebookEntry,
    this.onBack,
    this.backLabel,
    this.layout,
    this.shortcutsEnabled = true,
    this.header,
    this.scrollingHeader,
    this.revealTarget = true,
  });

  /// Shown inside the workspace's scroll above the palette (narrow hosts),
  /// instead of a fixed header above it (v2.6 M11D.1).
  final Widget? scrollingHeader;

  final ComposerLevel level;

  /// [ComposerMode.journeyExercise] or [ComposerMode.masteryChallenge].
  final ComposerMode mode;
  final String contextLabel;

  /// Records completion through the existing progression system. Called
  /// only after a successful explicit Check.
  final Future<void> Function() onCompleted;
  final VoidCallback onNext;
  final VoidCallback onOpenNotebook;
  final ValueChanged<String>? onOpenNotebookEntry;
  final VoidCallback? onBack;
  final String? backLabel;

  /// Shared workspace layout preferences; a private controller is used when
  /// none is given (tests, embedded hosts).
  final WorkspaceLayoutController? layout;
  final bool shortcutsEnabled;
  final Widget? header;
  final bool revealTarget;

  bool get isMastery => mode == ComposerMode.masteryChallenge;

  @override
  State<WebComposerExercise> createState() => WebComposerExerciseState();
}

@visibleForTesting
class WebComposerExerciseState extends State<WebComposerExercise> {
  late ComposerSession _session;
  late ComposerWorkspaceSlot _slot;
  WorkspaceLayoutController? _ownLayout;

  ExerciseCheckFeedback? _feedback;
  int? _feedbackRevision;
  int _visibleHints = 0;
  bool _saving = false;
  bool _solved = false;

  /// The exercise's session (tests).
  ComposerSession get session => _session;
  bool get solved => _solved;

  WorkspaceLayoutController get _layout =>
      widget.layout ?? (_ownLayout ??= WorkspaceLayoutController());

  static Future<void> _endOfFrame() => WidgetsBinding.instance.endOfFrame;

  ComposerSession _newSession() => ComposerSession(
        circuit: QuantumCircuit(currentLevel: widget.level),
        policy: ComposerPolicy.forMode(widget.mode, widget.level,
            revealTarget: widget.revealTarget),
        beforeRun: _endOfFrame,
      )..addListener(_sessionChanged);

  @override
  void initState() {
    super.initState();
    _session = _newSession();
    _slot = ComposerWorkspaceSlot(_session, status: '');
  }

  @override
  void didUpdateWidget(covariant WebComposerExercise oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.level, widget.level) ||
        oldWidget.mode != widget.mode ||
        oldWidget.revealTarget != widget.revealTarget) {
      final old = _session;
      old.removeListener(_sessionChanged);
      _session = _newSession();
      _slot = ComposerWorkspaceSlot(_session, status: '');
      _feedback = null;
      _visibleHints = 0;
      _solved = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
  }

  @override
  void dispose() {
    _session
      ..removeListener(_sessionChanged)
      ..dispose();
    _ownLayout?.dispose();
    super.dispose();
  }

  void _sessionChanged() {
    if (!mounted) return;
    setState(() {
      // Check feedback describes one circuit; any committed edit, undo,
      // redo or reset retires it.
      if (_feedback != null && _feedbackRevision != _session.revision) {
        _feedback = null;
      }
    });
  }

  /// The explicit Check: the only path to completion.
  Future<void> _check() async {
    if (_solved || _saving) return;
    final circuit = _session.circuit;
    if (!circuit.hasMeasurements) circuit.runSimulation();
    final result = widget.level.evaluateCircuit(circuit);
    if (!result.success) {
      setState(() {
        _feedback = ExerciseCheckFeedback.failure(widget.level, result);
        _feedbackRevision = _session.revision;
      });
      return;
    }
    setState(() {
      _saving = true;
      _feedback = ExerciseCheckFeedback.correct;
      _feedbackRevision = _session.revision;
    });
    await widget.onCompleted();
    if (!mounted) return;
    // The solved circuit stays on screen, inspectable and runnable, but no
    // longer editable (enforced by the session).
    _session.readOnly = true;
    setState(() {
      _saving = false;
      _solved = true;
    });
  }

  Widget _footer(BuildContext context) {
    final hints = widget.level.hints ?? const <String>[];
    final details = <Widget>[
      if (_feedback != null)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _feedback!.success ? Icons.check_circle : Icons.info_outline,
              size: 18,
              color:
                  _feedback!.success ? Colors.greenAccent : Colors.orangeAccent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _feedback!.message,
                key: const ValueKey('web-lesson-feedback'),
                style: QqType.body.copyWith(
                  color: _feedback!.success
                      ? QubitQuestColors.success
                      : QubitQuestColors.warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      for (var index = 0; index < _visibleHints; index++)
        Padding(
          key: ValueKey('web-lesson-hint-${index + 1}'),
          padding: const EdgeInsets.only(top: 2),
          child: WebLearningText('Hint ${index + 1}: ${hints[index]}',
              role: WebLearningTextRole.hint),
        ),
      if (_saving) const LinearProgressIndicator(),
      if (_solved)
        WebActivitySuccessPanel(
          level: widget.level,
          isMastery: widget.isMastery,
          onOpenNotebook: widget.onOpenNotebook,
          onOpenNotebookEntry: widget.onOpenNotebookEntry,
          onNext: widget.onNext,
          onBack: widget.onBack,
          backLabel: widget.backLabel,
        ),
    ];
    final maxDetails = MediaQuery.sizeOf(context).height * (_solved ? .45 : .3);
    return DecoratedBox(
      key: const ValueKey('web-exercise-actions'),
      decoration: const BoxDecoration(
        color: QubitQuestSurfaces.nav,
        border: Border(top: BorderSide(color: QubitQuestColors.border)),
      ),
      // The bar's content shares the workspace's maximum width and left
      // edge (M11D.1), so Check sits under the work, not in a far corner.
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
              maxWidth: LaboratoryComposerWorkspace.maxContentWidth + 40),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (details.isNotEmpty) ...[
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxDetails),
                    child: SingleChildScrollView(
                      key: const ValueKey('web-exercise-feedback-scroll'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < details.length; i++) ...[
                            if (i > 0) const SizedBox(height: 8),
                            details[i],
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // The action bar (M11B prototype 6): hints on the left, the
                // explicit Check on the right, and the reminder that nothing is
                // checked until the learner asks.
                LayoutBuilder(builder: (context, constraints) {
                  final hint = _visibleHints < hints.length
                      ? OutlinedButton.icon(
                          key: const ValueKey('web-lesson-hint'),
                          onPressed: _solved
                              ? null
                              : () => setState(() => _visibleHints++),
                          icon: const Icon(Icons.lightbulb_outline, size: 18),
                          label: Text(
                            _visibleHints == 0
                                ? 'Hint${hints.length > 1 ? ' 1 of ${hints.length}' : ''}'
                                : 'Next hint (${_visibleHints + 1} of ${hints.length})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      : hints.isNotEmpty
                          ? Text('All ${hints.length} hints shown',
                              key: const ValueKey('web-lesson-hints-exhausted'),
                              style: QqType.meta)
                          : const SizedBox.shrink();
                  final check = FilledButton.icon(
                    key: const ValueKey('web-lesson-check'),
                    onPressed: _solved || _saving ? null : _check,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      textStyle: QqType.control.copyWith(fontSize: 15),
                    ),
                    icon: Icon(_solved ? Icons.check_circle : Icons.check,
                        size: 18),
                    label: Text(_solved ? 'Completed' : 'Check Circuit',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  );
                  final reminder = constraints.maxWidth >= 640 && !_solved;
                  return Row(
                    children: [
                      Expanded(
                        child:
                            Align(alignment: Alignment.centerLeft, child: hint),
                      ),
                      const SizedBox(width: 8),
                      // The trailing group keeps its natural width (up to 70%
                      // of the bar), so Check sits at the right edge.
                      ConstrainedBox(
                        constraints:
                            BoxConstraints(maxWidth: constraints.maxWidth * .7),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (reminder) ...[
                              const Flexible(
                                child: Text('Nothing is checked until you ask',
                                    key: ValueKey('web-lesson-check-reminder'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: QqType.meta),
                              ),
                              const SizedBox(width: 16),
                            ],
                            Flexible(child: check),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ComposerSessionWorkspace(
        key: ObjectKey(_session),
        slot: _slot,
        layout: _layout,
        shortcutsEnabled: widget.shortcutsEnabled,
        contextLabel: widget.contextLabel,
        workspaceKey: const ValueKey('web-exercise-workspace'),
        clearedStatus: 'Starting circuit restored.',
        onOpenNotebookEntry: widget.onOpenNotebookEntry,
        markFixedGates: true,
        header: widget.header,
        footer: _footer(context),
        learning: !debugClassicExerciseLayout,
        learningIntro: widget.scrollingHeader,
        learningPaletteLabel:
            widget.isMastery ? 'Available' : 'Available in this lesson',
      );
}
