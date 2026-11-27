# Qubit Quest v2.6 M11B: implementation plan

Scope: presentation and navigation only. Across M11C–M11F, the following stay unchanged:
- simulation, gates, measurement semantics;
- validation, persistence schemas, progression;
- content, the version number and deployment.

No new dependencies are required: the prototypes use only what Flutter already provides (layout, `LatexText`, `CustomPainter`).

## 1. Shared components (built first, used everywhere)

| ID | Component | Based on (existing) | Used by |
|---|---|---|---|
| S1 | **Surface and type tokens**: the ladder in `M11B_VISUAL_DESIGN.md` §2, role-based text styles, a `nocase` maths-safe label | `QubitQuestColors`, `QubitQuestTypography` | All |
| S2 | **Responsive tiers**: one `QubitQuestTier` resolver (viewport for the shell, host width for workspaces) | Scattered constants (640…1200) | All |
| S3 | **Shell v2**: global nav with the logo, rail and top-bar variants; page-header band; sticky action bar | `WebApp` shell (900 px breakpoint) | All |
| S4 | **Section navigator with context strip**: list or rail or strip, with expanded current group and status dots | `WebJourneyOverview`, Notebook index, `WebMasteryBrowser` list | Journey, Notebook, Mastery |
| S5 | **Disclosure row**: label, inline summary, remembered state | Existing expansion tiles | Inspector, Read panel, lesson context, articles |
| S6 | **Maths well** and figure containers | `LatexText`, `CircuitDiagram` | Inspector, Notebook, Mastery |
| S7 | **Analysis workspace**: State / Measure / (Target) tabs over a responsive panel grid | `QuantumInspectorViews`, `ComposerResultsPanel`, measurement panels | Composer, lesson, challenge |
| S8 | **Contextual inspector v2**: header, actions, stacked sections, Related; docked / overlay / sheet | `GateInspectorPanel`, `GateEducationalInfo` | Composer, lesson, challenge |
| S9 | **Focused exercise configuration**: a presentation derived from `ComposerMode.journeyExercise` / `masteryChallenge` and `ComposerPolicy`; hides layout controls and zoom, restricts the palette, shows Your circuit / Target | `ComposerSessionWorkspace`, `ComposerPolicy` | Journey, Mastery |

S9 is configuration of the one shared Composer session, not a second implementation.

## 2. Milestones

### M11C: Composer and contextual inspector

1. **S1, S2, S5, S6** (tokens, tiers, disclosure, maths well). Apply them to the Composer first.
2. **Composer layout v2:**
   - horizontal palette (the existing categories and the M9 unavailable state);
   - circuit well sized by qubits × row and depth;
   - analysis workspace below (S7), with the State grid and Measure laid out as an experiment;
   - Focus circuit;
   - ultrawide cap.
3. **Inspector v2 (S8):**
   - appears only for a selection;
   - close = deselect;
   - expand mode removed;
   - sections instead of tabs;
   - Mathematics collapsed by default;
   - overlay below 1280 px, sheet below 600 px.
4. **Layout controls:** replace the panel toggles with Analysis / Focus circuit; move Restore layout to an overflow menu (prototypes doc §7).
5. **Large-register state:** amplitude sign map plus a full-table disclosure for more than 8 terms.
6. **Composer entry:** fold the qubit chooser into the header ("1 qubit ▾"), so `/composer` opens straight into the Sandbox. Today a separate page holds five buttons.
7. **Tests:**
   - update the widget tests that locate toolbar toggles and the inspector expand control;
   - add tests for inspector visibility on select/deselect, the tier breakpoints, and the analysis tab order;
   - run the targeted Composer suites.

**Exit criteria:** prototypes 1–4 are reproducible in the app at 1920 / 1440 / 1280 / 1024 / 800 / 390.

### M11D: Journey, Notebook and Mastery

1. **S3, S4** (shell v2, section navigator and context strip).
2. **Journey:**
   - the chapter page centred;
   - the curriculum persists during lessons, with the current chapter expanded;
   - the lesson header hierarchy (question, Task callout, More context);
   - the focused exercise (S9) with the dashed target outline;
   - sticky action bar (Hint, feedback, Check);
   - in-place completion, then Next lesson;
   - chapter scroll restored on return.
3. **Notebook:**
   - centred reading column (Option A);
   - margin column at 1600 px and above;
   - figure and maths-well treatment;
   - scroll restored after "Back to article";
   - Option B only if approved (Review D2).
4. **Mastery:**
   - the list persists (column or numbered rail);
   - search, filters, scroll and selection preserved;
   - workbook page for question challenges, with lettered options;
   - focused exercise (S9) for circuit challenges;
   - Next / Back continuity.
5. **Tests:**
   - Journey navigation and back-context, Mastery list-state preservation, and Notebook return paths;
   - the existing progression and completion tests are re-run unchanged (semantics must not move).

### M11E: Bloch Explorer and cross-section navigation

1. **Bloch layout:** Act · Sphere · Read, with the timeline below; Read disclosures with inline summaries.
2. **Interaction separation:** Preview, Apply, Animate when applying, Inspect step, **Play steps** (port the native Replay semantics through the existing evolution and animation path), Step ◀ ▶, Speed.
3. **Cross-section links:**
   - Composer → Bloch ("Open in Bloch Explorer", existing M8 hand-off);
   - inspector → Notebook;
   - Notebook → Composer / Bloch;
   - lesson completion → Notebook discovery.

   Each target shows a consistent "Back to …" return banner.
4. **Tests:** playback controls (enabled states, previews excluded, no state mutation), and the return banners.

### M11F: responsive review, usability testing, regression and release verification

1. **Responsive pass** at 2560×1080, 1920×1080, 1440×900, 1280×800, 1024×768, 800×700, 390×844, and the Pixel Tablet.
2. **Usability sessions** with 3–5 people new to quantum computing, using the eight walkthrough scenarios. Record time-to-first-action and points of confusion.
3. **Full regression suite** (first full run since M10), Chrome platform tests, analysis, and the release web build.
4. **Native regression:** Android and iOS, including native MCX placement (from M10).
5. Persistence verification, then the version bump to 2.6.0 (the original M11 items).

## 3. Dependencies

```text
S1,S2 ──► S5,S6 ──► M11C (S7,S8, Composer v2)
                     │
S3,S4 ───────────────┼──► M11D (S9 uses S7,S8; Journey, Notebook, Mastery)
                     │
                     └──► M11E (Bloch; cross-links need S3 return banners)
                                         │
                                         ▼
                                       M11F
```

- **M11D depends on M11C**, because the focused exercise (S9) is the Composer analysis and inspector in a restricted configuration.
- **M11E** can start in parallel with M11D once S1/S2/S5 exist.

## 4. Migration risks

| Risk | Impact | Mitigation |
|---|---|---|
| Widget tests keyed to the current layout (toolbar toggles, inspector expand, results column) | Many test edits | Keep the existing `ValueKey`s on moved widgets where meaning is preserved. Update a test only where the control is deliberately removed, and list each such test in the milestone report |
| Native (Android/iOS) shares widgets with web | Unintended native changes | Apply the new shell and layout under the web entry point (`WebApp`); native screens keep their layouts until reviewed separately |
| Inspector appearing and disappearing shifts the layout | Jarring motion | Dock without reflowing the circuit (the analysis column narrows); animate the width at 150 ms; overlay below 1280 px |
| Persistent section navigation reduces exercise width | Five-qubit circuits cramped at 1280 px | Auto-collapse to a rail or context strip when the circuit's natural width exceeds the available width |
| Sticky action bar covers content on short viewports | Hidden content | Bottom padding equal to the bar height; the bar is never taller than one row on desktop |
| Generated explanatory sentences ("In this circuit…", "agreed in every shot…") could be scientifically wrong in edge cases | Misinformation | Generate only from rules covered by tests (counts, basis, register order); otherwise omit the sentence (D3) |
| Disclosure-state persistence | Would need storage | In-memory in M11C–E; persisting needs approval (D5). No schema change for in-memory state |

## 5. Decisions requiring approval before M11C

Listed in `M11B_REVIEW.md` §4 (D1–D8).
