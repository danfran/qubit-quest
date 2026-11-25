# Qubit Quest v2.6: web UX assessment

Each finding is tied to source. **[Code]** means it was observed in source. **[Proposal]** means a recommendation. The running app was not inspected by eye during M1, so everything visual is inferred from layout code and should be confirmed in a browser.

## 1. Design language

### Current state [Code]

- `QubitQuestColors`, `Typography`, `Spacing`, `Radii`, `Borders` and `InteractionStates` exist (`theme/qubit_quest_visuals.dart`) and are good foundations.
- Adoption is partial:
  - 221 raw `Color(0x…)` literals remain.
  - `QubitQuestDialog` defines a parallel palette that the Learning Map uses throughout.
  - `BoxShadow` appears in 10 files, including the map header and every unlocked map card (a glow tinted with the accent).
- Web uses Material 3 (`QubitQuestTheme.web`, seeded from cyan). Mobile uses Material 2. Buttons, chips and inputs therefore look different across platforms.
- Page headings are inconsistent:

| Destination | Heading(s) shown |
|---|---|
| Composer, before opening | "Composer" / "Build, move, and inspect quantum gates." |
| Composer, after opening | "Sandbox Composer" / "Experiment freely with a live quantum circuit." |
| Journey | App bar wordmark, then "Learning Map" / "Concept graph and chapter progress" / "MAP" pill, then "Quantum Learning Journey" plus a paragraph |
| Mastery | "Back to Journey" button, then "Mastery Challenges" |
| Notebook | Search header, no page title |

### Proposed rules [Proposal]

1. **One page header pattern:** title (`QubitQuestTypography.title`) and an optional one-line subtitle, left-aligned, with page actions on the right. No eyebrow pills and no icon badges.
2. **Surfaces:**
   - The panel is the only elevation level (`surface` + `borderSoft`).
   - Wells use `surfaceInset`.
   - No shadows except dialogs (`QubitQuestBorders.topLevelShadow`, already reserved for that).
   - No accent-tinted borders on resting cards.
3. **Colour meaning:**
   - Cyan: interaction and selection.
   - Purple: educational emphasis.
   - Green: completed or correct.
   - Amber: warning.
   - Red: error or destructive.
   - Gate colours belong only to gates.
4. **Status:** one status mechanism per screen. Prefer inline state ("Saved", a completed tick) over chips and badges. Do not label resting states ("Incomplete").
5. **Width by destination:**

| Destination | Width |
|---|---|
| Composer, Bloch | Full width |
| Notebook reading | 720–760 px measure |
| Journey detail | 1100 px max |
| Mastery list | 1100 px max |

6. **Breakpoints:** consolidate to 760 / 1200 for workspace layouts, and keep 900 for the shell sidebar.

## 2. Learning Journey

### Problems [Code]

| # | Problem | Source |
|---|---|---|
| J1 | Cards alternate left and right (`chapterNumber.isOdd`, `widthFactor 0.74`), with arrow connectors between *every* consecutive pair. The order is already obvious from the numbers. | `_LearningMapNode`, `LearningMapConnectorPainter` |
| J2 | Six concept-link chips use ASCII labels ("2 -> 4", "12 -> Mastery") with no interaction. They are in the header, before any chapter. | `_LearningHeaderConceptLinks` |
| J3 | Every chapter card has an orb, title, identity text, status pill, chevron or lock, an accent border and a shadow. That is 5 indicators for 3 states. | `_LearningMapNode` |
| J4 | Overlapping terms ("Journey" nav, "Learning Map", "Concept graph", "MAP", "Quantum Learning Journey") and a no-op back button. | `LearningHeaderSystem` |
| J5 | Max width 980 px, with cards at 74% of that. On a 1440 px window that leaves roughly 900 px of empty canvas. | `LearningMapScreen` |
| J6 | Choosing a chapter replaces the map with the chapter workspace. There is no overview of objectives or progress before entering. | `WebJourneyWorkspace._openChapter` |

### Proposal

A master–detail layout.

**Left: chapter list, 320 px**
- 13 rows plus a Mastery row.
- Each row has a number, the title and one state glyph: ✓ completed, ● current, padlock locked.
- Lesson progress appears as `3/5` for the current chapter only.

**Right: selected-chapter panel**
- Title and chapter identity (existing `chapterIdentity` text).
- A "You will learn" list from the existing chapter metadata (`categoryIntro`, `phasePurpose`, Notebook discovery titles).
- Lesson list with state.
- Primary action: **Continue lesson N** / **Review** / *Locked: complete Chapter N−1*.
- **Builds on** row: the existing `conceptLinks` rendered as links (for example "Builds on Ch. 2 Hidden Change: hidden phase supports interference").
- Overall progress: one thin bar plus "34 of 66 lessons" in the list header.

**Also proposed**
- An optional "Concept map" view is kept behind a toggle. It shows the concept graph only: the six real links, not the sequential arrows.
- Clicking a list row only *selects* the chapter. Continue opens the existing `_ChapterWorkspace`, so the lesson flow is unchanged.

**Invariants**
- The rules stay exactly as they are: `ProgressionRules.isJourneyLessonUnlocked`, `CampaignProgressPolicy.chapterProgress` and `completedLessonIds`. Mastery *access* is always unlocked. Only the map's Mastery node is *drawn* locked until the Journey is complete (see `V26_ROADMAP.md` §5, D10). M5 decides whether that presentation should change.
- This is a visual change only. Existing tests (`learning_map_connector_test`, `campaign_progress_test`, `progress_identity_contract_test`) protect the model. The connector test is expected to be retired with the connector.

### M5 outcome [As built]

The web Journey is now the master–detail `WebJourneyOverview` (spec: `V26_LEARNING_JOURNEY_DESIGN.md`). Against the problems above:

| # | Outcome |
|---|---|
| J1 | No zigzag or sequential connectors on the web. The curriculum is a plain ordered list. |
| J2 | Concept links moved into the chapter detail as "Builds on" and "Prepares you for" links. |
| J3 | One status glyph per row (✓, ▶ current, ○ open, lock). Selection is a raised row with a cyan edge, never a second badge. |
| J4 | One heading, "Learning Journey". The no-op back button is gone. Lesson hosts keep a "Journey / Chapter N" breadcrumb back to the overview. |
| J5 | The layout follows the workspace width (300 / 268 / 236 px list; detail text ≤ 760 px). Below 720 px it becomes list → chapter → lesson. |
| J6 | Selecting a chapter shows its introduction, illustration, outcomes, lessons and progress. Start / Continue · Lesson N.M / Review opens the lesson directly. |

**Differences from the proposal:**

- Mastery is a header button, not a 14th list row: it is a separate destination, not a chapter.
- The list is 300 px, not 320 px.
- The optional concept-map toggle is not built.
- "What you will learn" uses each lesson's `keyInsight`, the existing learning outcome per lesson.
- `learning_map_connector_test` is kept: the native app still uses `LearningMapScreen`.

**Invariant check:** progression rules and stored progress are unchanged. Mastery's map node now matches its always-open access (D10).

## 3. Notebook [Code → Proposal]

- **N1:** On wide layouts the index is a modal ("Contents" → `showDialog`), and the reader is capped at 860 px. Proposal: a persistent left index (280 px) on desktop, collapsible, with the reader at about a 740 px measure.
- **N2:** 15 executable examples already open in Composer and Bloch. Proposal:
  - Keep "Open in Composer" as the single primary action on each example.
  - When opened, show a banner in the Composer: "Notebook example: *title* · Back to Notebook".
  - Opening must not overwrite the Sandbox circuit. Today the example *replaces* the Sandbox view in the same Composer state (`example` prop), and the Sandbox restores when Composer is selected from the nav. Confirm the user understands this, or open examples as a separate Composer mode tab.
- **N3:** Video links (proposal):
  - Add an optional `videoUrl` field per Notebook entry and per Journey chapter.
  - Show a "Watch the visualisation" link that opens externally (`url_launcher` already exists).
  - No embedded player and no dependency on the Videos repository.
- **N4:** Maths notation uses `LatexText` and `NativeMathText`. Keep the notation identical to the Videos project (`|q2 q1 q0⟩` little-endian ordering per `docs/qubit_ordering.md`).

## 4. Mastery Challenges [Code → Proposal]

- **M1:** Overview cards show only "Challenge N", the title and "Completed/Incomplete". `MasteryChallengeDefinition.difficulty` exists but is not displayed. The top of the page has a redundant "Back to Journey" (Mastery is a top-level destination). Proposal: a list with difficulty, the concept it practises and a ✓ when complete, plus filters (All / To do / Done) and search [Exists].
- **M2:** The challenge header stacks Back, a counter, progress, the title, Previous/Next and a status line. Proposal: one compact bar with ‹ Back · Challenge 12 of 42 · ‹ › on the left and a ✓ on the right.
- **M3:** Composer challenges use `WebComposerLesson`. Its slider rotation and lack of a selection panel diverge from the Sandbox. Proposal: reuse the unified workspace in `masteryChallenge` mode. The Target goes to the Results → State tab, and Check and Hint go to the toolbar.
- **M4:** No measurement in challenges. Do not add it in v2.6 unless new measurement challenges are authored (that is content work, M7).

### M6a outcome [As built]

| # | Outcome |
|---|---|
| M1 | **Done.** A master–detail library: compact rows with number, title, type and difficulty, and one status glyph. Search covers title, number, type, difficulty and concepts. Completion, type, difficulty and concept filters use authored metadata only. There is an empty state with reset. The redundant "Back to Journey" became a quiet "Learning Journey" link. |
| M2 | **Done.** The challenge bar has Back, a breadcrumb, the title and the objective, with ‹ Challenge n of 42 › and progress on the right. |
| M3 | **Done.** Circuit challenges run in the shared workspace (`masteryChallenge` policy). The target sits in Results → State. Hint and Check sit in a fixed footer, not the toolbar, so Check stays in one consistent place. |
| M4 | **Kept.** Challenges have no measurement and no Measure view (`runsExperiments` is false). |

## 5. Bloch Explorer [Code → Proposal]

- **B1:** The sphere clamps to 470–610 px tall at ≥ 1000 px width. Gate panel, playback, history and status are three stacked cards. The maths panel sits below the fold.
- **B2:** Proposal: sphere on the left (square, `min(70vh, 640)`), and a right column with Gates, History (with undo/redo [Exists]) and **State maths pinned at the top** (moved up from below the fold).
- **B3:** Reuse: `BlochSpherePanel` is already shared with the Composer Bloch tab. No new component is needed. Phase-sweep or animated visualisations inspired by the Videos project are a later milestone.

## 6. Application shell [Code → Proposal]

| # | Finding | Proposal |
|---|---|---|
| S1 | Wordmark AppBar (56 px) plus a 238 px sidebar plus a bottom `ProgressSaveStatusView` bar together use vertical space the Composer needs. | Move the wordmark into the sidebar top, remove the AppBar on wide layouts, and show save status as an inline toast. |
| S2 | Sidebar groups are LEARN (Journey, Notebook, Mastery) and EXPLORE (Composer, Bloch). | Keep them. Add a collapse-to-rail option (64 px) for the Composer. |
| S3 | Dead lock path for Mastery. | Remove the lock code path in M5 (no behavioural change). |
| S4 | `IndexedStack` keeps every destination alive. That preserves state, but every workspace also stays in memory and keeps its listeners. | Keep it: state preservation is valuable. |
| S5 | Route transitions are instant switches with no deep links. | Optional: hash routes (`#/composer`) in M5, so the browser back button works. Needs decision D8. |

### M5 outcome [As built]

| # | Outcome |
|---|---|
| S1 | **Partly done.** The AppBar is 52 px with a 26 px wordmark (was 56 / 30). Moving the wordmark into the sidebar and removing the AppBar was not done in M5: it changes every destination's vertical rhythm and belongs with M6b's layouts. |
| S2 | Already done in M3 (collapsible rail). Unchanged. |
| S3 | **Done.** The `masteryUnlocked` parameter and the lock path are removed. |
| S4 | Kept. Composer sessions survive destination changes (circuit, selection, undo history and panels). *(M5 note: results were discarded on leaving the Composer by the v2.5.1 rule. M6a removed that rule; results now survive and only circuit changes invalidate them; see `V26_SHARED_ARCHITECTURE.md` §12.8.)* |
| S5 | **Partial (D8).** Hash routes select the destination and Journey chapter at startup, and the address mirrors the shell (history *replace*), so reload and shared links work. Back/Forward is deferred to a Router migration. The startup route is read in `main()` before the startup splash's `Navigator` replaces the address. |

**Shell tokens:** the shell divider and navigation-selected colours are now `QubitQuestColors.shellDivider` and `navigationSelected`.
