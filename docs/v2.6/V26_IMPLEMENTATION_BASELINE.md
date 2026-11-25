# Qubit Quest v2.6: implementation baseline

Milestone M1 audit, 2026-11-24. *(Historical record. M6a replaced `WebComposerLesson` with the shared workspace; see `V26_SHARED_ARCHITECTURE.md` §12.)* **M2 update (same day):**

- Both web Composer hosts now run on `ComposerSession`.
- Undo/redo exists as a session capability.
- Notebook examples are isolated from the Sandbox.
- `measurement_results_view.dart` and the W4.1 grow mode were removed.

See `V26_SHARED_ARCHITECTURE.md` §7 and `V26_ROADMAP.md`. The rest of this document describes the M1 state. Everything here was read from the source at `HEAD` (`dbc76ce`, 2026-11-14, clean working tree). Labels:

- **[Code]**: verified in source, with a file reference.
- **[Test]**: verified by running a test during this audit.
- **[Report]**: taken from an earlier phase report and not re-checked.

## 1. Version and build

| Item | Value | Source |
|---|---|---|
| `pubspec.yaml` version | `2.5.1+36` | [Code] |
| Web version label | `Web v2.5.1 · Build 36` (rendered from `PackageInfo`) | [Code] `web_app.dart` `_WebNavigation` |
| Last release candidate | `ccd4ed1 candidate 2.5.1` (2026-10-25) | git |
| v2.6 work since then | `0a0e8ae` (W2: measurement draggable), `dbc76ce` (W3–W4.3: measurement ordering, execution, results, unified Inspector, selection toolbar) | git |

The version was **not** bumped for the v2.6 work. On a deployed build, 2.5.1+36 and v2.6-in-progress show the same label.

`/reports` was added to `.gitignore` in `dbc76ce`. The phase reports W1–W4.3 and 4B.1 exist only locally. This file and the rest of `docs/v2.6/` are tracked.

## 2. Platform entry points

| Platform | Root | Composer host | Source |
|---|---|---|---|
| Web | `QubitQuestWebApp` → `QubitQuestWebShell` (sidebar plus `IndexedStack` of 5 destinations) | `_ComposerWorkspace` (Sandbox and Notebook example), `WebComposerLesson` (Journey and Mastery) | [Code] `main.dart`, `web_app.dart` |
| Android/iOS | `MyApp` → `HomePage` | `QuantumComposer` (Sandbox, campaign, Mastery) | [Code] `main.dart`, `home_page.dart`, `quantum_composer.dart` |

Web destinations (`WebDestination`): `journey`, `notebook`, `mastery`, `composer`, `bloch`.

## 3. Content inventory

| Item | Count | Source |
|---|---|---|
| Journey chapters | 13 (chapters 1–12 have 5 lessons each, chapter 13 has 6) | [Code] `qq_levels.dart` categories |
| Journey lessons | 66 (`ProgressionRules.guidedDiscoveryLevelCount`) | [Code] |
| Mastery Challenges (v2) | 42 (`mastery2Catalogue`) | [Code] |
| Notebook entries | 68 discovery titles | [Code] `notebook_entries.dart` |
| Executable Notebook examples | 15 | [Code] `executable_notebook_catalog.dart` |
| Supported gates | H, X, Y, Z, S, T, Rx, Ry, Rz, CNOT, CZ, CCX, plus the M measurement cell | [Code] `selected_gate_type.dart`, `sandboxGatePaletteTypes` |
| Max qubits | 5 (Sandbox selectors 1–5) | [Code] |

## 4. Completed v2.6 functionality

| Feature | Platform | Status | Evidence |
|---|---|---|---|
| Web Sandbox opens on JS (session-ID fix) and shows open errors | Web | Implemented and verified | [Report] W1, [Code] `_openSandbox` |
| M as a draggable palette tile with meter glyph | Web | Implemented and verified | [Code] `ComposerGatePalette.measurementDraggable`, `MeasurementGlyph` |
| Measurements as per-qubit grid cells, insert-before, terminal-per-qubit policy, ordering transactions | Model (all) | Implemented and verified | [Test] `web_measurement_ordering_test` passes |
| Measurement move and classical-bit editing | Web | Implemented and verified | [Code] `_moveMeasurement`, `_updateSelectedClassicalBit` |
| Run once / Run shots, 1–10,000 shots with presets | Web Sandbox | Implemented and verified | [Test] `web_unified_inspector_test`, `measured_circuit_runner_test` |
| Two engines behind one Measure tab (final-state sampling, executed program) | Web Sandbox | Implemented and verified | [Code] `_runMeasuredCircuit` |
| Histogram of observed counts | Web Sandbox | Implemented and verified | [Code] `MeasuredCircuitRunPanel` |
| Pre-measurement state in State and Bloch | Web Sandbox | Implemented and verified | [Code] `PreMeasurementState` |
| Independent Circuit and Inspector cards | Web Sandbox | Implemented and verified | [Code] `independentCards: true` |
| Unified selection toolbar (gates and measurements) | Web Sandbox | Implemented and verified | [Test] `web_selection_toolbar_test` |
| Notebook example opens in Composer (and Bloch Explorer for 1 qubit) | Web | Implemented | [Code] `_openNotebookExampleInComposer`, `_openNotebookExampleInBloch` |

Test run during this audit: `web_unified_inspector_test`, `web_selection_toolbar_test`, `measured_circuit_runner_test` and `web_measurement_ordering_test` gave **61 / 61 pass** on the VM. No other suites were run.

## 5. Partially implemented

| Feature | What exists | What is missing |
|---|---|---|
| Measurement on native | Tap-to-place M (`onMeasurementTap`, `measurementPlacement`) on the new grid model | Drag, host selection, run panel. Native still shows `UnexecutedMeasuredCircuit` (`quantum_composer.dart:2559`). |
| Measurement in Journey and Mastery | Model supports it | `WebComposerLesson` has no M tile, no run panel and no Measure tab |
| Exact vs observed probabilities | Exact: State tab (`StateVectorDisplay`). Observed: Measure tab histogram. | They are on different tabs and the histogram shows no theoretical bar. Its note says frequencies "approximate the circuit's measurement probabilities" but does not show them. |
| Selected-gate panel | Toolbar in web Sandbox | Web lessons have none. Native uses its own header actions. Education is still only in the modal `GateInspectorDialog`. |
| Notebook executable examples | 15 examples, read-only Composer and a Measure tab | Notebook mode can't add measurements (`measurementDraggable: widget.example == null`). Opening one replaces whatever Sandbox circuit was showing. |
| Unused leftovers | `measurement_results_view.dart` is unreferenced. W4.1 grow mode in `quantum_workspace_layout.dart` is inert. | Removal is deferred to M2 (not removed here). |

## 6. Not implemented

- Composer undo/redo. None exists anywhere in the Composer. Bloch Explorer has its own history with undo/redo (`BlochExplorerModel`, `BlochPlaybackControls`).
- Explicit Save/Load of named circuits. The Sandbox autosaves one schema-2 program per qubit count, and there is no named-circuit library.
- Resizable or collapsible panels, and any persisted workspace layout preference.
- Canvas zoom. Gate geometry is static constants in `CircuitLayoutMetrics` (30 px gates, 40 px pitch).
- Post-measurement state display, mid-circuit reset and classical control (out of scope by design in W3).
- Reduced single-qubit Bloch vectors in multi-qubit circuits (needs density matrices).
- Links to videos from Notebook or Journey.
- Gates beyond the 12 listed. No CY, SWAP, S†, T† or P(φ).

## 7. Known defects and risks (code-supported)

| ID | Finding | Location |
|---|---|---|
| B1 | Journey header back button calls `Navigator.maybePop()`. On web the map is a root destination inside the shell, so the button is a no-op affordance. | `learning_map_screen.dart` `_LearningHeaderNavigation` |
| B2 | Mastery nav lock path is dead: `masteryUnlocked: true` is hard-coded, and `ProgressionRules.masteryChallengesUnlocked` returns `true`. The Learning Map's Mastery node is still drawn locked until the Journey is complete. Resolved in `V26_ROADMAP.md` §5 (D10). | `web_app.dart`, `progression_rules.dart` |
| B3 | Rotation-angle semantics differ between hosts. Sandbox and native ask for the angle in a dialog on drop and allow Edit angle afterwards. Web lessons set one palette-wide angle with a 16-step slider before dragging, and offer no edit after placement. | `web_learning_workspace.dart:1614`, `web_app.dart:768` |
| B4 | Controlled-gate placement has two implementations: web `showControlledGatePlacementDialog`, and native `TwoQubitsGateTargetQubitSelectionDialog` / `ThreeQubitsGateTargetQubitsSelectionDialog`. | screens |
| B5 | At a 1024 px tablet-landscape window, the content area is about 785 px (1024 − 238 sidebar − 1). The Sandbox (960 breakpoint) and chapter header (960) stack, while lesson workbenches (760) stay side by side. Breakpoints in use: 700, 720, 760, 880, 900, 960, 1000. | shell and workspaces |
| B6 | The Notebook index is a modal dialog on wide layouts (`showContents: wide` → `_showContents` → `showDialog`). Desktop topic navigation therefore needs a dialog. | `web_notebook_workspace.dart` |
| B7 | `_status` is used as an event log ("Restored N operation(s)", rejection reasons, save state) under the selection toolbar. A SnackBar repeats rejection text. | `web_app.dart` |
| B8 | 221 raw `Color(0x…)` literals across `lib/` (home_page 38, learning_flow_widgets 25). `QubitQuestDialog` keeps a parallel palette. Web uses Material 3 and mobile Material 2. | theme audit |
| B9 | Measure runs are synchronous on the web main thread (no isolates on web). They are bounded by the executor budget of 10M operations. | [Report] W4 |

## 8. Duplication summary

See `V26_SHARED_ARCHITECTURE.md` §2 for the full matrix. In short:

- **Shared:** `QuantumCircuit`, `ComposerCircuitCanvas`, `ComposerGatePalette`, `GateInspectorDialog` and `SandboxWorkspacePersistence`.
- **Duplicated** three times (one per host): drop/insert dispatch, selection behaviour, controlled and rotation placement flows, and execution and results.
