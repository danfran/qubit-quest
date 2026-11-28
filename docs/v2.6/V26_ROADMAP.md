# Qubit Quest v2.6: The Quantum Learning Workspace (roadmap)

Status: **approved after the M1 review. M2, M3, M3.1, M4, M5, M6a and M6b approved; M7 provisionally approved; M8 accepted. M9 accepted. M10 implemented (2026-11-26), awaiting the developer's end-to-end review. Remaining: M11 release.** This file is the tracked record of v2.6 decisions and commitments; `/reports` is git-ignored.

## 1. Resolved M1 decisions

| # | Decision | Resolution | Milestone |
|---|---|---|---|
| D1 | Milestone order | Approved, with the corrections in §2 | — |
| D2 | Undo/redo; named circuit library | Undo/redo approved. Session capability in M2, toolbar in M3. Named circuit library **deferred**. | M2, M3 |
| D3 | Rotation configuration | Unified editing semantics approved. **Inspector-first** configuration is the M3 target. M2 consolidates the logic and keeps today's visible workflows. | M2, M3 |
| D4 | Exact-probability overlay | **Implemented in M4:** exact-versus-observed comparison of the same experiment (see `V26_MEASUREMENT_RESULTS.md`) | M4 |
| D5 | Canvas zoom | **Revised in M3.1:** a limited circuit scale (100 / 125 / 150%, default 125%) in the desktop Composer, implemented as one transform around the shared geometry. Continuous zoom, pinch and infinite canvas remain out of scope. | M3.1 |
| D6 | Persist workspace layout | Approved | M3 |
| D7 | Post-measurement state | **Resolved in M4:** the conditional state after execution is shown for Run once, from the executor's own per-shot state (partial measurement of entangled registers included). Multi-shot results are never shown as a state. Reduced subsystem states (density matrices) remain out of scope. | M4 |
| D8 | Browser routing (hash routes) | **Partly implemented in M5:** destination and Journey-chapter hash routes (`#/composer`, `#/journey/chapter-3`, …); the address mirrors the shell with a history *replace*, so reload and shared links restore the place. Back/Forward between destinations and lesson-level URLs are deferred: they need a Router migration (see `V26_LEARNING_JOURNEY_DESIGN.md` §12). | M5 (partial) |
| D9 | New gates and content | Confirmed commitments in §3 | M7 |
| D10 | Mastery availability | **Resolved in M5:** Mastery is open at all times, and every surface now says so. The native map's Mastery node is drawn available; the dead web sidebar lock is removed; the web Journey links to Mastery from its header. Challenge unlocking and completion are unchanged (§5). | M5 |
| D11 | Notebook session isolation | Approved. **Implemented in M2.** | M2 |
| D12 | Responsive breakpoints (760 / 1200 workspaces, 900 shell) | Approved as a starting point. M3 derives tiers from the workspace's own width instead: narrow < 640, medium < 908, compact or wide above (see `V26_COMPOSER_WORKSPACE_DESIGN.md` §9.1). The shell keeps 900. | M3, M5 |

## 2. Milestones

| Milestone | Scope | Status |
|---|---|---|
| M1 | Architecture audit and workspace design | Done |
| M2 | Shared Composer foundation: `ComposerSession`, `ComposerPolicy`, `ComposerPlacementFlow`, undo/redo capability, results lifecycle, Notebook session isolation, both web hosts migrated | Done (approved) |
| M3 | Desktop Composer workspace: palette / canvas / inspector / results, toolbar with Undo/Redo, inspector-first rotation editing, resizable and collapsible panels, persisted layout (D6), tiers from the workspace's own width (D12 revised: 640 / 908 px), collapsible app navigation | Done (reviewed) |
| M3.1 | Workspace refinement: scalable state presentation (wrapped expression, collapse, copy, amplitude rows), circuit scale (D5 revised), pinned qubit labels, content-sized canvas and inspector fill, integrated educational inspector (Overview / Mathematics / Learn) replacing the desktop modal, inline replacement menu, footer and typography refinements | Done (approved) |
| M4 | Measurement and results: exact distributions of the actual experiment (final-state and explicit measurement, marginalisation, classical mapping, ordering), exact-vs-observed comparison (D4), adaptive probability precision, conditional state after execution and one-qubit pre/post Bloch (D7), terminology; inspector identity, maths size, definition headings, Learn illustration size | **Approved** |
| M5 | Web shell and Learning Journey: header pattern, master–detail Journey, Mastery map-lock resolution (D10), optional hash routes (D8); M4 polish (conditional-state grouping, "More about" disclosure, transient status, adaptive histogram height) | **Approved.** M4 polish item A (pinned Results tabs) deferred to M8 |
| M6a | Unified educational workspace: Journey circuit lessons and Mastery circuit challenges in the shared desktop Composer workspace (`ComposerSessionWorkspace`), explicit Check contract, fixed-operation enforcement and marking, target-visibility capability, Mastery library (master–detail, search, metadata filters), session-owned measurement results (survive destination changes), M5 preview and wording corrections | **Approved** (visually approved; see `V26_SHARED_ARCHITECTURE.md` §12) |
| M6b | Notebook as an interactive knowledge base: persistent categorised index, articles composed from existing content (discoveries, gate reference, notation), search with empty states, `#/notebook/<id>` routes, **executable examples as isolated in-Notebook Composer experiments** (authored circuit, full palette, inspector, measurement and shots, Reset example, return to the article), Notebook ↔ Journey/Mastery links, video-reference metadata (no UI) | **Approved** (see `V26_SHARED_ARCHITECTURE.md` §13). The Bloch Explorer desktop layout from the original M6b scope was not in the M6b brief: moved to M8 |
| M7 | **CY and multi-controlled X (MCX)** as first-class operations: one controlled-operation kernel, one insertion routine and one footprint rule for CX/CZ/CY/CCX/MCX; additive persistence; palette, renderer, MCX chooser, inspector; always-available Notebook gate articles with 12 executable examples | **Provisionally approved** (see `V26_SHARED_ARCHITECTURE.md` §14). The §3.3 chapter and challenges move to M10 |
| M8 | **Bloch Explorer: interactive single-qubit state laboratory**: state preparation (canonical and θ/φ), gate preview and commit with full-angle Bloch rotations (H about (X+Z)/√2), complex-amplitude plane, coordinates and phase, history with inspection/undo/redo, X/Y/Z measurement with exact, single-run and shots results, phase comparisons, isolated Notebook and Composer explorations, responsive workspace. Simulator matrices are authoritative for every state | **Accepted** (see `V26_SHARED_ARCHITECTURE.md` §15). Reduced/mixed states documented as a boundary (not implemented) |
| M9 | Consolidation: shared notation (`V26_NOTATION_GUIDE.md`), dark transient messages, full-circuit visibility with the inspector, unavailable-gate palette state, measured-restore comparison fix, experiment-description clarity, Bloch inspection/narrow/phase-wording refinements, two scientific wording corrections | **Accepted** (see `reports/V26_M9_CONSOLIDATION.md`) |
| M10 | Educational expansion: Chapter 14 *Conditional Quantum Logic* (lessons 14.1–14.5, Journey IDs 67–71), Mastery 43–48, five Notebook discoveries with nine executable examples, CY/MCX article links; native MCX placement through the shared chooser. Totals 14 chapters · 71 lessons · 48 challenges | **Implemented, in review** (see `V26_SHARED_ARCHITECTURE.md` §17 and `reports/V26_M10_CONTENT_EXPANSION.md`) |
| M11B | Experience architecture, information hierarchy and visual design: five-layer shell, analysis-below Composer, focused exercise configuration, centred Notebook, Bloch playback model; 11 isolated HTML prototypes (`docs/v2.6/mockups/m11b_prototypes.html`); plan for M11C–M11F | **Direction approved** (M11C onwards) |
| M11C | Shared experience foundations (surface ladder, tiers, panel/disclosure/maths-well primitives, shell v2 with the brand in the navigation) and the laboratory Composer: horizontal palette, content-sized circuit, central State/Measure analysis, contextual inspector, Analysis/Focus circuit modes, direct entry into the Sandbox | **Implemented, awaiting manual review** (see `reports/V26_M11C_COMPOSER_REDESIGN.md`) |
| M11C.1 | Scientific component design: bundled Inter web type scale (`QqType`), shared scientific primitives (data table, metadata, probability bar, toggle, fact list), rebuilt Current State (stacked-fraction expression, recognised states with global phase, aligned amplitude table, collapsed precision note), adaptive Probabilities, overlay-free Bloch summary, aligned Measure outcomes, inspector hierarchy | **Implemented, awaiting manual review** (see `reports/V26_M11C1_SCIENTIFIC_COMPONENTS.md`) |
| M11D | Journey and Mastery redesign: persistent curriculum (expanded chapter, rail, narrow chapter strip), centred chapter page, shared lesson/challenge header with Task callout, learning layout for circuit activities ("Your circuit now" vs target with the actual validation scope), persistent Mastery list pane / numbered rail, lettered answer cards with explicit Check Answer; Composer follow-ups (measured amplitude columns, \|+⟩⊗ⁿ compact form, Bloch pole labels, one palette order) | **Implemented, awaiting manual review** (see `reports/V26_M11D_JOURNEY_MASTERY.md`) |
| M11D.1 | Journey and Mastery refinement: circuits take their natural height with page scrolling (no capped well), compact scrolling headers on narrow screens, target typeset like the current state, Now/Target columns, left-aligned wide workspaces, sticky Check Answer and compact hints for questions, two-line navigation titles with reveal | **Implemented, awaiting visual review** (see `reports/V26_M11D1_FINAL_UI_REFINEMENT.md`) |
| M11E | Notebook reading, mathematics and exploration: one ordered block model rendered as Article (centred 720 px column, contextual margin with On this page / Where it is used / notation) or Spread (explanation left, mathematics and experiments right; falls back where it does not fit, preference kept); index in three groups (notation, gates, discoveries) with reveal; maths under the sentence it formalises; gate pages as Overview / Behaviour / Mathematics / Experiments / Related; experiment figures at natural size with the typeset state and Run in Composer; advanced-note examples shown on the web; ket glyph fixed in circuit painters; Composer multi-qubit Bloch note corrected | **Implemented, awaiting visual review** (see `reports/V26_M11E_NOTEBOOK_REFINEMENT.md`) |
| M11 | Release verification: full regression, Chrome platform, release web build, persistence, Android/iOS regression, **Pixel Tablet Challenge assessment**, bump to 2.6.0 | Last |

Ordering notes:

- M5 can run alongside M3/M4.
- M6a needs the M3 workspace.
- Native `QuantumComposer` migration to `ComposerSession` is a separate effort, recommended for v2.7.

## 3. Confirmed v2.6 commitments (M7)

These were agreed before M1 but not recorded in the repository. M1 therefore classed them as proposals. They are now commitments.

### 3.1 Controlled-Y (CY)

- One control and one target. The correct controlled Pauli-Y unitary, including its complex phases: |1⟩⟨1| ⊗ Y, with Y = [[0, −i], [i, 0]].
- A consistent matrix, gate representation (tile, painter), placement (the existing one-control flow), inspection and educational information.

### 3.2 Generalised Toffoli / multi-controlled X (MCX)

- A configurable number of controls and one target, within the current 5-qubit limit: 2, 3 and 4 controls where the circuit has enough qubits.
- Reuse the existing CCX implementation. Existing CNOT and CCX circuits stay backward-compatible, including persisted schema-2 programs (`control`, `secondControl`) and educational exercises.
- Use a generalised representation (a list of controls), not separate CCCX or CCCCX special cases.
- M2 readiness:
  - `GatePlacementRequest.controls` is already a list.
  - `ComposerSession.insertGate` dispatches by control count. Counts above 2 currently return `unsupported`.
  - `ComposerPlacementFlow`'s controls chooser returns a list.
- M7 extends:
  - the model insertion and footprint (today `controlQubitIndex` and `control2QubitIndex`);
  - the schema-2 encoding (additive, keeping `control`/`secondControl` for CNOT and CCX);
  - the matrix builder;
  - the painter;
  - the controls chooser.

### 3.3 Educational content

- One new Learning Journey chapter.
- About 5–8 new Mastery Challenges.
- Matching Notebook discoveries.
- Relevant executable Notebook examples.
- The scientific content is planned at the start of M7.

### 3.4 Optional, not committed

SWAP, S†, T† and other gates remain future proposals.

## 4. Tracked responsive issues

| Issue | Platform | Where it is handled |
|---|---|---|
| Web tablet-landscape breakpoint mismatch (about 785 px content at 1024 px: Sandbox stacks, lessons don't) | Web | M3 (tiers), M6a (Challenge screen) |
| **Challenge screen has excessive unused vertical space in landscape**, observed on a Pixel Tablet running Android 14 | Native | **Must stay tracked.** Assess in M8 and report whether a focused native fix is appropriate. Not dropped because the release is web-first. |

## 5. Mastery availability (D10 findings, M2)

Effective behaviour today:

- **Access is always unlocked on both platforms.**
  - `ProgressionRules.masteryChallengesUnlocked` returns `true` (since commit `7df40d9 New challenges`, 2026-08-29). `campaign_progress_test` asserts `true` for a fresh install.
  - Web: the sidebar passes `masteryUnlocked: true`, so the nav lock icon (`web-nav-mastery-lock`) is unreachable.
  - Native: `home_page.dart` treats every Mastery-phase item as unlocked (`isUnlocked = category.isMasteryPhase || …`).
- **The only lock is presentational, in `LearningMapScreen`.** Both the web Journey and the native map use this screen. Its Mastery node is drawn locked until every Journey lesson is complete, and tapping it then does nothing (`activity_identity_routing_test` checks that it opens Mastery once the Journey is complete).

So M1 did not record a platform difference. It recorded two surfaces that disagree:

- **M1 baseline B2** ("always unlocked") describes access.
- **M1's Journey invariant** ("requires all 66 lessons") describes the map node's drawing.

Behaviour is unchanged in M2. Deciding whether the map node should match the always-on access, and removing the dead nav-lock path, belongs to M5.

**M5 resolution:** the map node now matches access. `LearningMapScreen` draws Mastery as available and opens it from a fresh install (`web_journey_overview_test`, "native map"). The web sidebar's `masteryUnlocked` parameter and `web-nav-mastery-lock` path are removed. The web Journey no longer uses `LearningMapScreen`; it links to Mastery from its header and from chapter 12's connections.

## 6. Reconciled backlog (after M2)

| Item | Status |
|---|---|
| Composer host consolidation (web) | **Implemented in M2.** Both web hosts use `ComposerSession` and `ComposerPlacementFlow`. |
| Undo/redo | **Session capability implemented in M2.** UI in M3. |
| Notebook session isolation | **Implemented in M2** |
| Measurement placement, artwork, Run once/shots, configurable shots, single-qubit Bloch | Implemented and verified (pre-M2). Orchestration moved into the session in M2. |
| Exact vs observed results | **Implemented in M4** |
| Independent results panel, gate inspector, palette categories | **Implemented in M3** |
| Integrated educational inspector, scalable state presentation | **Implemented in M3.1** |
| Challenge usability (web) | **Implemented in M6a** (shared workspace, Mastery library) |
| Native measurement execution UI, native session adoption | Deferred (v2.7) |
| Canvas zoom | **Limited circuit scale implemented in M3.1** (D5 revised) |
| Named circuit library | Deferred (D2) |
| Post-measurement state | **Implemented in M4 for Run once (D7)**; reduced subsystem states remain future work |
| CY, MCX, Notebook gate articles and examples | **Implemented in M7** (§14) |
| New Journey chapter, 5–8 Mastery challenges, matching discoveries (§3.3) | Deferred: out of scope in the M7 brief; to be scheduled |
| MCX on native | Not offered (no native multi-control interaction); CY uses the native CX flow |
| Pixel Tablet Challenge layout (native) | Tracked, M8 assessment |
| Inspector default height and circuit visibility on smaller screens | **Improved in M6a:** the shared workspace's content-aware allocation now serves exercises; the animating inspector is capped to the available height, and exercise headers are capped at half the viewport. Further tuning tracked for M8 |
| Composer measurement results across destinations | **Fixed in M6a:** results belong to the retained session; only circuit changes invalidate them (`V26_SHARED_ARCHITECTURE.md` §12.8) |
| Consistent navigation and header controls | **Implemented in M5** (shell header 52 px, shell tokens, single Journey heading) |
| Notebook knowledge base, executable examples | **Implemented in M6b** (`V26_SHARED_ARCHITECTURE.md` §13) |
| Bloch Explorer desktop layout (maths above the fold, sphere sizing) | **Implemented in M8** (three-panel laboratory, sphere as the principal element) |
| Reduced density matrices / mixed single-qubit states | Not implemented (no existing support; M8 boundary documented in the Explorer and the Composer Bloch tab) |
| Notebook video references (UI) | Architecture only in M6b (`NotebookVideoReference`, empty registry); UI deferred |
| Mastery ↔ Notebook concept links | M6b links only through palette gates; Mastery definitions have no authored discovery references (content gap) |
| Pinned Results tabs while the results scroll | Deferred from M5 to M9; not done in M9, proposed for after v2.6 (restructures the results scroll and reveal contract) |
| Back/Forward browser history, lesson-level URLs | Deferred (needs a Router migration; D8 partial) |
| Consistent palette ordering across responsive presentations | Tracked, M8 (or earlier if addressed naturally) |
| Exact comparison and adaptive precision in lesson hosts | Not used by any current exercise: existing exercises have no sampled runs (`ComposerPolicy.runsExperiments` is false). Available through the shared panel when a future exercise enables it |
| Sandbox entry screen (wide card with five qubit buttons) | Tracked for M8 or later: a compact chooser beside a recently used size would use the space better (not redesigned in M6a) |
| Target panel amplitudes | Tracked: the target panel shows probabilities and the authored expression; showing target amplitudes would make relative phase visible without the expression |

## 7. Files expected per milestone

**Review material (from M11E, permanent):** every visual milestone also delivers its report, the original screenshots and logically grouped contact sheets (`tools/contact_sheet.sh`), as set out in `docs/VISUAL_MILESTONE_REPORTING.md`. Contact sheets supplement the screenshots and stay git-ignored under `reports/`.

| Milestone | New | Changed | Removed |
|---|---|---|---|
| M2 (done) | `models/composer_session.dart`, `models/composer_policy.dart`, `models/edit_history.dart`, `widgets/composer_placement_flow.dart`, tests | `web_app.dart`, `web_learning_workspace.dart`, `quantum_circuit.dart` (edit snapshots), `composer_gate_capabilities.dart`, `quantum_workspace_layout.dart` | `widgets/measurement_results_view.dart`, W4.1 grow mode |
| M3 | `widgets/desktop_composer_workspace.dart`, `gate_inspector_panel.dart`, `composer_results_panel.dart`, `resizable_split.dart`, `composer_toolbar.dart` | `composer_gate_palette.dart`, `web_composer_workbench.dart`, both web hosts | Probably `composer_selection_toolbar.dart` once it is absorbed |
| M3.1 | `widgets/gate_educational_sections.dart`, `composer_workspace/circuit_scale_control.dart` | `gate_inspector_panel.dart`, `gate_inspector_dialog.dart`, `composer_circuit_canvas.dart`, `quantum_circuit_painter.dart`, `state_vector_display.dart`, `native_math_text.dart`, `composer_placement_flow.dart`, `workspace_layout_state.dart`, `web_app.dart` | — |
| M4 | `models/measurement_distribution.dart`, `utils/probability_format.dart`, `docs/v2.6/V26_MEASUREMENT_RESULTS.md` | `circuit_executor.dart` (exact branching, shared projection), `measured_circuit_runner.dart` (conditional state), `composer_session.dart`, `measured_circuit_run_panel.dart`, `state_vector_display.dart`, `qq_fraction.dart`, `quantum_inspector_views.dart`, `composer_results_panel.dart`, `gate_inspector_panel.dart`, `gate_educational_sections.dart`, `gate_educational_visual.dart`, `web_app.dart` | — |
| M5 | `screens/web_journey_overview.dart`, `models/journey_curriculum.dart`, `widgets/journey_chapter_illustration.dart`, `docs/v2.6/V26_LEARNING_JOURNEY_DESIGN.md` | `web_app.dart` (shell, routes, transient status), `main.dart` (startup route), `web_learning_workspace.dart`, `learning_map_screen.dart`, `theme/qubit_quest_visuals.dart`, `measured_circuit_run_panel.dart` | Web use of the zigzag map, dead Mastery nav lock |
| M6a | `widgets/composer_workspace/composer_session_workspace.dart`, `screens/web_exercise_workspace.dart`, `screens/web_mastery_browser.dart`, `test/v26_m6a_educational_workspace_test.dart` | `web_app.dart` (Sandbox host now a slot manager; results kept on leaving), `web_learning_workspace.dart` (exercise routing, chapter header, Mastery destination), `composer_session.dart` (review lock), `composer_policy.dart` (`revealTarget`, `runsExperiments`), `quantum_circuit_painter.dart` and `composer_circuit_canvas.dart` (fixed-gate badge and drag feedback), `desktop_composer_workspace.dart` (inspector height cap), `composer_results_panel.dart` (optional Measure view), `quantum_inspector_views.dart` (camera kept in the selection), `journey_chapter_illustration.dart`, `qq_levels.dart` (wording) | `widgets/web_composer_workbench.dart`, `WebComposerLesson`, the lesson-only `_SuccessPanel`, `_ChapterHeader`, `_LessonList` |
| M6b | `models/notebook_knowledge_base.dart`, `test/v26_m6b_notebook_test.dart` | `web_notebook_workspace.dart` (rewritten: index + article + experiment), `web_app.dart` (`#/notebook/<id>`, cross-destination requests; Composer destination is Sandbox-only), `web_learning_workspace.dart` and `web_mastery_browser.dart` (lesson/challenge requests, gate reference links), `executable_notebook_example.dart` (`createExperimentLevel`), `executable_notebook_catalog.dart` (3 examples), `notebook_entries.dart` (example attachments), `composer_policy.dart` (`notebookExample` runs experiments), `gate_inspector_panel.dart` (public preview footprint) | Composer-destination Notebook example path (`_openNotebookExampleInComposer`, the `example` slot) and the Contents dialog |
| M7 (planned) | Per gate and per content item | `selected_gate_type.dart`, `quantum_circuit.dart`, `placed_quantum_gate.dart`, `logical_gate_footprint.dart`, `circuit_program.dart`, `sandbox_program_snapshot.dart` (additive), `quantum_matrix.dart`, `quantum_circuit_painter.dart`, `gate_educational_info.dart`, `gate_visual_style.dart`, `controlled_gate_placement_dialog.dart`, catalogues | — |
| M7 (actual) | `gate_reference_examples.dart`, `multi_controlled_gate_placement_dialog.dart`, `test/v26_m7_controlled_gates_test.dart` | `quantum_matrix.dart` (one kernel), `quantum_circuit.dart` (one insertion routine, reset fix), `placed_quantum_gate.dart`, `logical_gate_footprint.dart` (one topology rule), `circuit_program.dart`, `circuit_executor.dart`, `measured_circuit_runner.dart`, both Sandbox schemas (additive `controls`/`controlQubits`), `composer_session.dart`, `composer_placement_flow.dart`, `controlled_gate_placement_dialog.dart`, `quantum_circuit_painter.dart` (one renderer), palette/tiles/styles, `gate_inspector_panel.dart`, `gate_educational_*`, `gate_educational_info.dart` (CY, MCX, `keyIdeas`), canonical step model, Notebook knowledge base and article, `quantum_composer.dart` (native CY; no MCX) | The kron-sum `buildTwoQubitsGateOperator` and per-gate `ccnot` builder; duplicated double/triple insertion bodies; duplicated CX and CCX painter branches |
| M8 | `bloch_lab.dart`, `web_bloch_workspace.dart`, `complex_amplitude_plane.dart`, `test/v26_m8_bloch_lab_test.dart` | `bloch_explorer_model.dart` (applyGate via simulator matrices, exact amplitudes, `BlochRotation`), `bloch_sphere_panel.dart` (optional overlays), `web_app.dart` (standalone lab + isolated explorations; old `_BlochWorkspace` removed), `composer_session_workspace.dart` (Explore in Bloch), `quantum_inspector_views.dart` (multi-qubit boundary text), `gate_reference_examples.dart` (T example), `notebook_knowledge_base.dart` | `_BlochWorkspace` (web) and its shortest-path replay |

## 8. Risks and dependencies

| Risk | Impact | Mitigation |
|---|---|---|
| M3 re-layout breaks key- and rect-coupled layout tests | Medium | Keep keys, and rewrite layout tests deliberately |
| MCX changes the footprint model used by move, duplicate and validation | High (M7) | Add the list-of-controls representation behind the existing CNOT/CCX encodings. Run parity suites before and after. |
| Native/web divergence grows | Medium | Native session adoption in v2.7 |
| Pixel Tablet issue forgotten | Low | Tracked in §4 and part of the M8 checklist |
| Version label unchanged during development | Low | Bump in M8 |
