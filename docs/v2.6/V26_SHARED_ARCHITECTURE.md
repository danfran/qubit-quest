# Qubit Quest v2.6: shared Composer architecture

Labels: **[Code]** means verified in source. **[Proposal]** means a design decision that needs approval.

## 1. Current layering [Code]

> Historical (M1 audit). The web hosts below were consolidated in M2 and replaced by one shared workspace in M6a; see §12.

```text
Domain / simulation     QuantumCircuit (grid model, edit outcomes, ordering transactions)
                        CircuitProgram · CircuitExecutor · QuantumMeasurementResult
                        MeasuredCircuitRunner · FinalStateSampler · PreMeasurementState
                        GateEducationalCatalog · ComposerSelectedGateCapabilities
Persistence             SandboxWorkspacePersistence (schema 2, per qubit count, staging/recovery)
                        CircuitSaveQueue · CampaignProgressController (qq_progress_v3 A/B records)
Reusable widgets        ComposerCircuitCanvas · ComposerGatePalette · QubitQuestGateTile
                        MeasurementGlyph · ComposerSelectionToolbar · MeasuredCircuitRunPanel
                        QuantumInspectorViews · QuantumStateInspectorContent · StateVectorDisplay
                        BlochSpherePanel · GateInspectorDialog · RotationGateDialog
Layout                  WebComposerWorkbench → QuantumWorkspaceLayout (web only)
Hosts (state + glue)    _ComposerWorkspace (web_app.dart, ~1060 lines of host logic)
                        WebComposerLesson (web_learning_workspace.dart, ~480 lines)
                        QuantumComposer (quantum_composer.dart, 2844 lines)
```

The model layer is in good shape. The duplication sits in the **host** layer: each host owns its own copy of the editing glue.

## 2. Duplication matrix [Code]

| Capability | Web Sandbox `_ComposerWorkspace` | Web lesson `WebComposerLesson` | Native `QuantumComposer` | Verdict |
|---|---|---|---|---|
| Circuit model | `QuantumCircuit` | `QuantumCircuit` | `QuantumCircuit` | Shared |
| Canvas | `ComposerCircuitCanvas`, host selection, measurement callbacks | `ComposerCircuitCanvas`, host selection, no measurement | `ComposerCircuitCanvas`, legacy canvas-local measurement path | Shared widget, 2 modes |
| Gate drop → insert dispatch | `_handleDrop` (765–818) | `_drop` (1473–1521) | `_handleGateDrop` (388–520) and controller insert (330–370) | **Duplicated ×3** |
| Gate palette | `ComposerGatePalette` with draggable M | `ComposerGatePalette` with rotation slider beside it | `ComposerGatePalette` with tap-to-place M | Shared widget, 3 configs |
| Rotation parameter | `RotationGateDialog` on drop; Edit angle | Palette slider (16 steps) before drag; no edit | `RotationGateDialog`; Edit angle | **Divergent semantics** |
| Controlled placement | `showControlledGatePlacementDialog` | `showControlledGatePlacementDialog` | Two/Three-qubit target selection dialogs | **2 implementations** |
| Selected-gate panel | `ComposerSelectionToolbar` + capabilities | None (canvas delete only) | Header action buttons + capabilities | **3 behaviours** |
| Gate inspection | `GateInspectorDialog.forGate` | `GateInspectorDialog.forGate` (palette only) | `GateInspectorDialog` | Shared |
| Measurement execution | `MeasuredCircuitRunPanel` with 2 engines | None | `UnexecutedMeasuredCircuit` placeholder | Web Sandbox only |
| State vector | `QuantumStateInspectorContent` → `StateVectorDisplay` | Same | `StateVectorDisplay` directly | Mostly shared |
| Probabilities (exact) | Inside `StateVectorDisplay` | Same | Same | Shared |
| Bloch | Inspector tab (`QuantumInspectorViews`) | Inspector tab | Not in Composer | Shared on web |
| Persistence | `SandboxWorkspacePersistence` via `programs.queue(n)` | None (in memory, keep-alive) | `SandboxWorkspacePersistence` via `programs` | Shared store |
| Undo/redo | None | None | None | Missing. Pattern exists in `BlochExplorerModel`. |
| Results lifecycle | `_resultsRevision`, `_resetResults` | n/a | n/a | Host-local |
| Status messaging | `_status` and SnackBar | `_feedback` | SnackBars and banners | **Duplicated ×3** |

The lesson host also contains a second, older **stacked layout** in its `build()` method (`desktopWorkspace == false`). This is an internal duplicate of its own workbench layout.

## 3. Host mode differences (must be preserved)

| Constraint | Sandbox | Notebook example | Journey exercise | Mastery Challenge |
|---|---|---|---|---|
| Qubit count | User chooses 1–5 | Fixed by example | Fixed by level | Fixed by level |
| Gate set | All 12 + M | Example's gates, no M | `level.availableGates` | `level.availableGates` |
| Pre-inserted gates | No | Example circuit | `preInsertedGates`, some fixed (`isDeletable == false`) | Same |
| Initial state | `|0…0⟩`, or a binary state | Example's | `initialQubitsState` | Same |
| Target state shown | No | No | Yes (`solutionFinalVector`) | Yes |
| Check / completion | None | None | `level.evaluateCircuit` → `completeLesson` | Same → `completeMasteryChallenge` |
| Hints | No | No | `level.hints` | Same |
| Persistence | Autosave per qubit count | None | None (resets per lesson) | None |
| Measurement | Allowed | Disallowed today | Not offered | Not offered |
| Reset vs Clear | Clear | Clear (back to example) | Reset (back to level start) | Reset |

Proposal: a challenge may reveal its target state but must never reveal its solution.

## 4. Unified architecture (proposed in M1; as built in §7)

```text
ComposerSession (ChangeNotifier, pure Dart, no BuildContext)
  ├─ circuit: QuantumCircuit
  ├─ mode: ComposerMode (sandbox | notebookExample | journeyExercise | masteryChallenge)
  ├─ policy: ComposerPolicy  ← derived from mode + level
  │    allowedGates, allowMeasurement, allowQubitChange, persistence, showTarget,
  │    canCheck, rotationEntry (dialog | inspector), fixed-gate rules
  ├─ selection: GateId?
  ├─ history: EditHistory (undo/redo of encoded snapshots)  [M3]
  ├─ results: RunResults (single, shots, error, revision)
  ├─ status: ComposerMessage stream (transient feedback, one channel)
  └─ commands: drop(intent) · insertMeasurement · move · replace · editAngle
               · duplicate · delete · clear/reset · runOnce · runShots · check
ComposerPlacementFlow (UI adapter)
  └─ asks for missing parameters: controlled targets, rotation angle (one implementation)
Functional widgets (unchanged API where possible)
  GatePalette (vertical-categorised and horizontal-strip presentations)
  CircuitCanvas · GateInspectorPanel (new, non-modal) · ResultsPanel
Layouts (platform composition only)
  DesktopComposerWorkspace (3 columns + inspector)   — web ≥ 1200
  CompactComposerWorkspace (2 columns / tabs)        — web 760–1199, tablet
  MobileComposer (existing QuantumComposer layouts, migrated later)
```

Principles:

1. **One command path.** All three hosts call `session.drop(intent)`, which replaces the three `_handleDrop` copies. Hosts keep only mode-specific behaviour: Check, hints, save status and navigation.
2. **Policy, not branches.** `widget.example == null` checks (about 20 in `_ComposerWorkspace`) become `policy.allowMeasurement`, `policy.persists` and similar flags.
3. **One rotation flow (D3 resolved).** Editing semantics are unified in M2. One command path and one placement flow handle both angle sources:
   - prompting on placement (Sandbox, Notebook);
   - the palette preset (lessons; preset angles stay locked by `ComposerPolicy.allowsAngleEditing`).

   The lesson slider stays visible until M3. M3 makes configuration **inspector-first**: place with a default or a preset, select, then edit in the persistent inspector.
4. **One controlled-placement flow.** Use the web dialog everywhere. Native would migrate in a later milestone, not v2.6 M2.
5. **Session is platform-neutral.** Mobile can adopt `ComposerSession` without the desktop layout. Native migration is optional in v2.6 and recommended as a follow-up.
6. **Persistence unchanged.** Schema 2 and `SandboxWorkspacePersistence` stay as they are. Workspace layout preferences would use a separate small key (`qq_web_workspace_layout_v1`) only if approved.

## 5. Undo/redo design (implemented in M2)

M1 proposed history entries made of `SandboxProgramSnapshot` encodings. M2 checked that idea against every mode and **rejected it**:

| Requirement | `SandboxProgramSnapshot` | `CircuitEditSnapshot` (chosen) |
|---|---|---|
| Circuit dimensions and initial state | Restores a new circuit with a *Sandbox* level | Same circuit object; the level is never replaced |
| Lesson gate set, target state, pre-insertion rules | Lost (`restoreCircuit` builds a Sandbox `ComposerLevel`) | Kept (level untouched) |
| Notebook and lesson gate types | Decode only accepts `sandboxGateTypes` | Any gate type |
| Fixed-gate identity and protection | `isDeletable` kept, but `GateId`s change on a new object | Exact cells, same `GateId`s |
| Rotation parameters, control/target roles | Yes | Yes (cells copied verbatim) |
| Measurement ordering and classical bits | Yes | Yes (grid cells plus the reserved classical width) |
| Listener ownership (canvas, host) | Breaks: a new circuit object | Kept: the same object notifies once |

**As built:**

- `QuantumCircuit.captureEditSnapshot()` / `restoreEditSnapshot()` copy the grid (immutable `PlacedQuantumGate` cells), the reserved classical width and the ID allocator. The allocator only moves forward, so a removed gate's ID is never reused.
- The snapshot is in memory only. The persisted schema is unchanged.
- `EditHistory<T>` follows the Bloch Explorer pattern: a list plus a cursor, with the redo branch dropped on a new record. The limit is 100 undo steps, held per session and never persisted.
- History records only when the committed definition differs from the current entry. Rejected, cancelled and no-op commands, selection changes and measurement runs never record.
- Restore bookkeeping:
  - re-simulate when the circuit is unmeasured;
  - bump `revision`;
  - clear results;
  - autosave (Sandbox only);
  - drop the selection if its ID no longer exists.
- Restoring never records history: the restore sets the history cursor itself, and the session ignores its own circuit notifications while it applies.

## 7. M2 as implemented

```text
lib/models/composer_policy.dart      ComposerMode, ComposerPolicy.forMode(mode, level)
lib/models/composer_session.dart     ComposerSession (ChangeNotifier), GatePlacementRequest,
                                     controlCountFor, ComposerFeedback
lib/models/edit_history.dart         EditHistory<T>
lib/models/quantum_circuit.dart      + captureEditSnapshot / restoreEditSnapshot, CircuitEditSnapshot
lib/widgets/composer_placement_flow.dart
                                     ComposerPlacementFlow (angle and controls choosers, injectable)
```

- **Session commands:** `insertGate`, `moveGate`, `replaceGate`, `duplicateGate`, `editRotationAngle`, `deleteOperation`, `insertMeasurement`, `moveMeasurement`, `setClassicalBit`, `clear` (Clear or Reset by policy), `select`, `undo`, `redo`, `run`, `clearResults`.
- Every command calls the existing `…WithOutcome` model API. The session never re-implements validation.
- **One commit pipeline.** When the model reports `changed` *and* the definition differs, the session:
  1. simulates if unitary;
  2. bumps `revision`;
  3. clears results;
  4. records history;
  5. autosaves once (Sandbox);
  6. re-resolves the selection;
  7. notifies once.

  Some edits report `changed` but settle back to the same slot (gravity compaction). Those leave the circuit and every piece of bookkeeping untouched.
- **Direct circuit edits are adopted.** The session listens to its circuit. A notification that changes the definition outside a command (tests, legacy callers) goes through the same pipeline. Simulation-only notifications are ignored.
- **Policy.** One immutable value per mode, with no class hierarchy:
  - `allowsMeasurement`, `persistsToSandbox`, `permittedQubitCounts`, `showsTargetState`, `offersCheck` / `offersHints`;
  - `clearAction` (clear or reset), `angleEntry` (prompt on placement or palette preset);
  - `allowsAngleEditing(type)`: lesson-authored preset angles stay fixed;
  - `allowsGateType(type)`.

  Fixed gates and replacement availability stay enforced by the model.
- **Controls are a list** (`GatePlacementRequest.controls`). `insertGate` dispatches 0/1/2 controls to the existing single/double/triple insertions. Higher counts return `unsupported` until M7 (MCX).
- **Placement flow:**
  - It gathers parameters only (`drop`, `editAngle`, `replace`) and then issues exactly one command.
  - Cancelling at any step returns `cancelled` with no change.
  - After every await it re-checks `context.mounted` and `session.isDisposed`, and hosts additionally check that the session they started with is still active.
  - The default choosers are today's `RotationGateDialog` and the web `showControlledGatePlacementDialog`. M3 can inject inspector-first choosers.
- **Hosts:**
  - `_ComposerWorkspace` owns two slots (Sandbox, active Notebook example), each with its own session, status line and state filter.
  - `WebComposerLesson` owns one session in `journeyExercise` or `masteryChallenge` mode. *(M6a: replaced by `WebComposerExercise` on the shared workspace; §12.)*
  - Hosts keep navigation, dialogs, wording, hints, Check and completion.
- **Native:** `QuantumComposer` is unchanged. It still uses the shared model, canvas and palette, and the new model additions are purely additive. The session has no Flutter-widget or web dependency, so native can adopt it later.

## 6. Mobile compatibility

- Mobile keeps its own layout composition (portrait stack, landscape split). It must not get a compressed three-column layout.
- Phase 1 (v2.6): share `ComposerSession` commands and `ComposerPlacementFlow` on web only. Native stays on `QuantumComposer` so the release does not regress mobile.
- Phase 2 (v2.7 candidate): native adopts the session and the `ResultsPanel` (as a bottom sheet or tab) and drops `UnexecutedMeasuredCircuit` and tap-to-place M.

## 8. M3 desktop workspace (as built)

```text
_ComposerWorkspace (web_app.dart)       owns sessions (Sandbox + Notebook slots), status wording, dialogs
 └─ DesktopComposerWorkspace            tiers, resizing, collapse, focus mode, undo/redo shortcuts
     ├─ ComposerWorkspaceToolbar        title/context, qubit menu, Undo/Redo, Clear/Reset, save status, layout controls
     ├─ ComposerGatePalettePanel        categories from policy.availableGates (+ M when policy allows); rail mode
     ├─ canvas region (host)            ComposerCircuitCanvas unchanged, vertical scroll, one-line summary/status
     ├─ GateInspectorPanel              reads session selection/capabilities; actions → host → session commands
     │    └─ RotationAngleEditor        local draft; one session.editRotationAngle per gesture
     └─ ComposerResultsPanel            existing QuantumInspectorViews (State / Bloch / Measure)
WorkspaceLayoutController (shell)       presentation-only preferences, qq_web_workspace_layout_v1
ResizeHandle                            cumulative-offset drag strip; preview on drag, commit on release
```

The invariants from M2 still hold.

- **No direct mutation.** No new widget mutates the circuit. The inspector and palette call host callbacks, and the host calls `ComposerSession` commands or `ComposerPlacementFlow`.
- **No second history.** Undo and redo (toolbar and shortcuts) call `session.undo()` and `session.redo()`.
- **Presentation state stays outside the session.** Panel sizes, collapsed panels, the results tab, the medium-tier view and the palette preview never touch the session, so they create no history, autosave or revision changes.
- **Changing tier never rebuilds the session.** The medium tier keeps the circuit and Results views in an `IndexedStack`, and the narrow tier uses a non-lazy `Column`, so the canvas, results and drafts stay mounted.
- **Shared widgets changed only additively:**
  - `QuantumInspectorViews` gains `compactTabs` and `fitTabsToWidth`, both off by default;
  - `MeasurementGlyph` gains `gradient`;
  - `ComposerPolicy` gains `defaultOnPlacement` and `defaultRotationAngle`.

  Journey, Mastery and native layouts are unchanged.

## 9. M3.1 additions (as built)

```text
GateEducationalCatalog ──► gate_educational_sections.dart ──► GateInspectorPanel (tabs)
                                                         └──► GateInspectorDialog (other hosts)
ComposerCircuitCanvas(scale) ──► _ScaledCircuitViewport: one Transform.scale; logical geometry inside
WorkspaceLayoutPreferences.circuitScale (additive, v1)
ComposerPlacementFlow.replace(type:) + replacementCandidates()   (inspector replace menu)
StateVectorDisplay(structuredLayout, stateLabel)                  (desktop State tab)
```

- **Still no direct mutation.** Scale, tabs, expanded mode and copy are presentation only. Replacement goes through `ComposerPlacementFlow.replace` → `session.replaceGate` (one command).
- **One geometry.** `CircuitLayoutMetrics` stays the single geometry; scaling is a transform around it, so there is no scaled copy of the geometry, painter or hit-testing.
- **Shared additions are opt-in and default to the previous behaviour:** `QuantumCircuitPainter.showQubitLabels` / `wireColor`, `ComposerCircuitCanvas.scale` / `pinnedQubitLabels` / `wireColor`, `StateVectorDisplay.structuredLayout` / `stateLabel`, `QuantumStateInspectorContent.structuredLayout` / `stateLabel`, `GateEducationalMatrix.minimumScale`.
- **Shared bug fixes (all hosts):** `NativeMathText` translated `\mathrm{…}` into a literal `$1` and accepted commands it could not render (`\cdot`). It now maps `\mathrm` correctly, translates `\cdot`, and sends anything else it cannot translate to `LatexText`.

## 10. M4 additions (as built)

```text
CircuitExecutor
  ├─ runShot / runShots            sampling (unchanged behaviour; shared _outcomeMasses/_project)
  └─ exactDistribution             exact branching over measurement outcomes, same code path
MeasuredCircuitRunner.runOnce ─► SingleShotOutcome.conditionalState (same execution)
ExactMeasurementDistribution     finalState(|α|²) | explicit(executor) | unavailable(reason)
MeasurementComparison            union of possible and observed outcomes; filter; unexpected flag
ComposerSession.exactDistribution  cached per revision; results lifecycle unchanged
formatProbability                single display policy for probabilities and frequencies
MeasuredCircuitRunPanel(exact:)  presentation only; no scientific calculation beyond count / shots
```

- **One execution model.** Exact predictions come from the executor's own projection code, so they cannot drift from the sampled experiment. Widgets never compute probabilities, never run experiments, and never keep results outside the session.
- **Reusable by M6a.** Journey and Mastery hosts can pass `ExactMeasurementDistribution` and `MeasurementComparison` to the same panel without duplicating logic.
- **Additive changes:** `SingleShotOutcome.conditionalState`, `QuantumInspectorViews.blochHeader`, `ComposerResultsPanel.blochHeader`, `GateEducationalVisualView.height` (default 92), `GateEducationalMathList.large`, `mathDefinitionHeading`, and `StateVectorDisplay`'s structured-only changes. Native and lesson presentation is unchanged.


## 11. M5 additions (as built)

```text
main()  ─ reads PlatformDispatcher.defaultRouteName before any Navigator exists
QubitQuestWebApp(startupRoute) ─► QubitQuestWebShell
  ├─ parseWebRoute(fragment) → (destination, chapterIndex?)     pure, tested
  ├─ _reportRoute()  post-frame, SystemNavigator.routeInformationUpdated(replace: true)
  └─ IndexedStack (unchanged: every destination stays mounted)
       └─ WebJourneyWorkspace(initialChapterIndex, onChapterShown)
            ├─ JourneyCurriculum.of(progressState)   read-only statuses, progress, actions
            ├─ WebJourneyOverview                     presentation only
            │    └─ JourneyChapterIllustration         ComposerLevel circuits, Composer painter
            └─ _openLesson(id) ─ re-checks ProgressionRules before any lesson host opens
```

- **No new state stores.** The Journey derives everything from `CampaignProgressState`. The selected chapter and narrow-layout step are widget state. The address carries only the destination and chapter number. Storage formats are unchanged.
- **Composer sessions are untouched.** Routing changes the `IndexedStack` index only. Sessions, history and panels survive every destination change. Results followed the v2.5.1 rule (discarded when the Composer became inactive). *(M6a: results now belong to the retained session and survive destination changes; §12.8.)*
- **Transient status (M4 polish).** `_ComposerWorkspaceState._info` shows informational messages (measurement added, moved, reassigned or removed; Undone; Redone; restore notices) for 6 s. Rejections and errors stay until the next action.
- **Results panel (M4 polish).** The conditional state is grouped under the single run as a collapsible section. Secondary explanation moved behind "More about this experiment". The histogram shows 8–16 rows before scrolling, depending on window height. These are presentation-only changes.
- **M6a seam.** M6a replaces the lesson host behind `_openLesson`. Overview, curriculum model and routes need no change.

## 12. M6a: one workspace, several educational contexts (as built)

### 12.1 Architecture

```text
ComposerSessionWorkspace (widgets/composer_workspace/)   the M3 desktop workspace for ONE session
  ├─ header?  (educational context, host-supplied)
  ├─ DesktopComposerWorkspace: toolbar · palette · canvas · inspector · results
  └─ footer?  (educational actions, host-supplied; always visible)

Sandbox / Notebook   _ComposerWorkspace (web_app.dart)       slot manager: two sessions, qubit chooser
Journey lesson       _ChapterWorkspace → WebLessonWorkspace → WebComposerExercise
Mastery challenge    WebMasteryWorkspace → WebLessonWorkspace → WebComposerExercise
Concept checks       WebLessonWorkspace (reading page; no Composer is created)
Mastery library      WebMasteryBrowser (web_mastery_browser.dart)
```

- **One renderer.** Every circuit context shows the same palette, canvas, gate inspector (Overview, Mathematics, Learn), state view, Bloch view and measurement panel. Contexts differ only through the session's `ComposerPolicy` and the host's optional header and footer.
- **Educational hosts own orchestration only:** the exercise session, hint sequencing, the explicit Check and completion. Circuit mutation, simulation, undo/redo, restrictions and results stay in `ComposerSession` and `QuantumCircuit`.
- **No new engine, editor, palette, inspector, renderer or history.**

### 12.2 Exercise inventory (from the definitions, 2026-11-25)

| Context | Type | Count | Evaluator |
|---|---|---|---|
| Journey (66) | `ComposerLevel` | 49 | `finalState` 38 (exact amplitudes), `unitary` 11 (every input) |
| | `ConceptCheckLevel` | 17 | answer index |
| Mastery (42) | `ComposerLevel` | 11 | `physicalState` 5 (up to global phase), `unitary` 6 |
| | `ConceptCheckLevel` / `McqLevel` | 30 / 1 | answer index |

**Other observations:**

- **Fixed (authored) gates** appear in Journey 2, 19, 20, 32 and 63, and in Mastery 2, 13, 25, 28 and 35.
- **Rotations:** no current exercise has a free rotation. S and T are presets.
- **Hidden targets:** every circuit exercise reveals its target, so none hides it.
- **Unused level types:** `FillTheGateLevel`, `CircuitReadingLevel` and `MeasurementLabLevel` keep their web hosts but are not used by the current Journey or Mastery.
- **Counts are read from the data, never hard-coded** (`test/v26_m6a_educational_workspace_test.dart`).

### 12.3 Context capabilities (`ComposerPolicy`)

| | Sandbox | Notebook example | Journey / Mastery exercise |
|---|---|---|---|
| Palette | all gates | example's gates | level's gates only |
| Qubit count | 1–5 (chooser) | fixed | fixed |
| Place M | yes | no | no |
| Run once / shots (`runsExperiments`, new) | yes | yes | **no** (existing contract) |
| Target shown (`showsTargetState`; `revealTarget`, new) | — | if authored | if authored **and** revealed |
| Check / hints | no | no | yes |
| Clear / Reset | Clear | Reset example | Reset (restores authored gates) |
| Autosave | Sandbox store | never | never |

- **Information restrictions are independent of editing rules.** `revealTarget: false` removes the target from the state view, the expression and the Bloch overlay, without changing what can be edited (tested).

### 12.4 Restriction enforcement

Enforced at the command boundary, never only in the UI:

| Rule | Where |
|---|---|
| Gate outside the palette | `ComposerSession.insertGate` (policy); `replaceSingleGateWithOutcome` and `planLogicalGateDuplication` (model: replacement and duplication only to available types) |
| Fixed gates (`isDeletable == false`) | Model: move, replace, duplicate, delete and parameter edits return `protected`. Reset re-creates them. Undo/redo restore snapshots that contain them. |
| Measurement | `insertMeasurement` checks `allowsMeasurement` |
| Authored angles | `editRotationAngle` checks `allowsAngleEditing` |
| Review lock (new) | `ComposerSession.readOnly` rejects every command, plus undo, redo and clear, after a successful Check |

**Presentation:**

- **Lock badges:** fixed gates carry a small lock badge (`markFixedGates`) that leaves the gate identity visible.
- **Inspection without editing:** the inspector shows "Part of this activity's setup. It can be inspected but not changed." and offers no edit actions.
- **Drag attempts are explained:** dragging a fixed gate gives "Not changed: this gate is part of the activity's setup and cannot be moved or removed." (new `onFixedGateDragAttempted`).
- **Verified across all mutation paths** for every fixed-gate exercise, and Reset/undo/redo preserve them (data-driven test).

### 12.5 Explicit Check contract

- **Only `WebComposerExerciseState._check` completes an exercise.** It runs the level's own evaluator; there are no listeners or auto-checks. The native host is also manual-only, which was verified.
- **Reaching the target while editing** updates live results only: no feedback, no success panel, no progress write (tested).
- **A failed Check:**
  - names what the evaluator compares: exact state (with a global-phase note when that is the only difference), state up to global phase, or behaviour on every input;
  - keeps the circuit and history;
  - is retired by the next edit.
- **A successful Check:**
  - calls `onCompleted` once and locks the circuit for review;
  - shows the existing completion content with Next, Back and Notebook.
- **Idempotent completion:** `completeLesson` and `completeMasteryChallenge` are set-based and idempotent; reviewing a completed exercise never resets it.

### 12.6 Evaluation compatibility

The evaluators are unchanged (`ComposerLevel.evaluateCircuit`):

- **finalState:** relative and global phase sensitive;
- **physicalState:** global phase ignored;
- **unitary:** every input, with alternates.

**Tests:**

- Every exercise's canonical solution replays through the shared session commands and passes; every starting circuit fails.
- |+⟩ vs |−⟩ (same Z probabilities) fails until Z is added.
- −|1⟩ fails `finalState` but passes `physicalState`.
- The shown input matching is not enough in `unitary` mode.

### 12.7 Hints and solutions

- **Hints:** progressive inline hints in the footer (Hint, then "Next hint (k of n)"), never automatic and never modal.
- **Solutions:** no solution is revealed on failure. Concept checks keep their existing hint card.

### 12.8 Measurement results belong to the session

- **Ownership:** results (single run, conditional state, shot counts, run error) were already session-scoped and revision-tagged since M2/M4.
- **What M6a removed:** the host's deactivation rule (`didUpdateWidget` → `clearResults` when the Composer was not the visible destination).
- **Kept** across destination changes (Journey, an opened lesson, Notebook, Mastery, Bloch Explorer), selection, panel resize and collapse, scale, tabs and explanations. They are the same objects, so nothing is re-run.
- **Invalidated** (`_definitionChanged`) by insert, delete, move, replace, duplicate, angle, classical-bit and measurement-move changes, and by clear/reset, undo and redo. A move that settles back into its slot is not a change and keeps them (tested per mutation).
- **Not persisted** across a full reload (out of scope for v2.6).

### 12.9 Session lifecycle

| Context | Created | Retained | Navigation away / back | Reset | Completion | Disposed | Reload |
|---|---|---|---|---|---|---|---|
| Sandbox | choosing a size | while the shell lives | kept (circuit, history, results) | Clear (undoable) | — | size change, app exit | circuit restored from storage; results not |
| Notebook example | opening an example | until another example | kept | Reset example | — | example change | not restored |
| Journey lesson | opening the lesson | while the lesson is open | leaving the lesson disposes it | Reset (undoable) | review lock | back to Journey, other lesson | not restored (no unfinished attempts) |
| Mastery challenge | Start | while browsing the library (`IndexedStack`) | kept while browsing; another Start replaces it | Reset | review lock | another challenge | not restored |

- **Exercise sessions never autosave** (`saveQueue == null`) and never share a session with the Sandbox (tested).

### 12.10 Mastery library

- **Library state:** `WebMasteryWorkspace` owns the selection (presentation only; it defaults to the first incomplete challenge), the open activity, the query and the list scroll. Returning restores all of them.
- **`MasteryLibraryQuery`:**
  - search over title, number, interaction type, difficulty and concept tags;
  - completion filter;
  - type, difficulty and concept filters, built only from authored metadata.
- **Details:** task statement, interaction type, difficulty, format (circuit with qubit count, or question) and concept tags, with Start / Continue / Review. Never options, hints or explanations (tested).
- **Order and access:** no required order; every challenge is always open.

### 12.11 Responsive behaviour

- **Exercises** use the shared tiers (wide, compact, medium with the Circuit/Results switch, narrow stacked).
- **Header and footer:** the context header is capped at half the viewport and stacks its trailing navigation under the breadcrumb below 640 px. The footer always shows Hint and Check.
- **Inspector height:** the inspector's animated height is capped at the available height (fixes a transient overflow when space shrinks suddenly).
- **Bloch camera:** now kept in `QuantumInspectorSelection`, so it survives tier changes.

### 12.12 Previous and new educational hosts

| Previous (M2–M5) | M6a |
|---|---|
| `WebComposerLesson` + `WebComposerWorkbench` + `QuantumWorkspaceLayout` (separate layout, palette widget, dialog gate inspector, inspector card) | `WebComposerExercise` on `ComposerSessionWorkspace` (the Sandbox's workspace) |
| Lesson title and task repeated in the page body; mystery text always visible | Compact context header: breadcrumb, title, objective, expandable context |
| Check inside the scrolled page | Check in a fixed footer |
| Hints appended under the canvas | Inline progressive hints in the footer |
| Success disabled the canvas (`IgnorePointer`) | Success locks the session (command-level) |
| Mastery card grid; tapping started a challenge | Master–detail library; selecting shows details, Start opens |

**Removed:**

- `widgets/web_composer_workbench.dart`;
- `WebComposerLesson`;
- the lesson-only `_SuccessPanel`, `_ChapterHeader`, `_CompactActivityContext` and `_LessonList`/`_LessonItem`.

**Retained:**

- `WebCircuitWorkbenchMetrics` in `circuit_canvas_metrics.dart`: unused by the web hosts now, but tested; remove in M8 cleanup.
- `QuantumWorkspaceLayout`: still used by other screens.
- Dedicated non-circuit hosts (`_WebChoiceLesson`, `_WebFillGateLesson`, `_WebCircuitReadingLesson`, `_WebMeasurementLesson`). They need no editable circuit; the circuit-reading host draws a read-only circuit with the shared painter.

### 12.13 Native boundaries

- **No web-only dependencies in shared code:** the session's review lock, the policy fields and the painter badge (off by default) are platform-neutral.
- **Unchanged native workflow:** `QuantumComposer` and its manual Check are not modified.
- **Shared wording corrections:** the lesson wording corrections in `qq_levels.dart` also apply to the native app (scientific improvements only).
- **Compilation:** `flutter analyze lib` reports no errors or warnings.

