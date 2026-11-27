# Qubit Quest v2.6 M11B: experience architecture

Status: **design proposal for review.** No production code was changed in M11B.

Companion documents:
- `M11B_INFORMATION_HIERARCHY.md`
- `M11B_VISUAL_DESIGN.md`
- `M11B_WORKSPACE_PROTOTYPES.md`
- `M11B_USABILITY_WALKTHROUGH.md`
- `M11B_IMPLEMENTATION_PLAN.md`
- `M11B_REVIEW.md`

Prototypes are in `docs/v2.6/mockups/m11b_prototypes.html` (open with `?s=<screen>`). Rendered images are in `reports/screenshots/v26_m11b/`, with the current application in `…/before/`.

Labels used in this document:
- **[Code]** marks an observation from source or from the running release build (Web v2.5.1 · Build 36).
- **[Proposal]** marks a recommendation.

## 1. The problem, stated precisely

The reviewer called the experience "bewildering". The cause is not the amount of content; it is how content is placed:

1. **Equal prominence.** The task, results, explanations and advanced mathematics are styled and positioned alike. A Journey lesson shows the full Composer chrome: five layout toggles, zoom, the inspector header and the results tabs. These carry the same weight as the task sentence.
2. **Space is allocated by region, not by content.** [Code]
   - A one-qubit Sandbox circuit gets about 750 px of empty canvas.
   - The state and probabilities are squeezed into a 340 px results column (`before/composer_one_qubit_1920x1080.png`).
   - Selecting a gate grows the inspector to fill the workspace and shrinks the circuit to about 140 px, while measurement stays in the sidebar (`before/composer_measure_tab_1920x1080.png`).
3. **Reading surfaces hug the left edge.** At 1920 px, a Notebook article starts beside the index and leaves about 520 px of empty space to its right (`before/notebook_article_1920x1080.png`). The Composer entry page is one 1,630 px card holding five buttons (`before/composer_entry_1920x1080.png`).
4. **Starting an activity changes the world.** Opening a lesson or challenge replaces the curriculum or challenge list with a full-width workspace. The learner keeps only a breadcrumb to say where they are.
5. **Surfaces are nearly indistinguishable.**
   - The background (`#00030A`), surface (`#111827`) and inset (`#030814`) tokens are separated by small luminance steps.
   - Global navigation, section navigation, page headers and workspaces therefore read as one plane, divided by hairlines.

## 2. Principles adopted [Proposal]

| Principle | Architectural rule |
|---|---|
| Information hierarchy | Every screen has exactly one **primary region**, holding what the learner acts on, and one **primary action**. Everything else is visibly subordinate in surface, size and position. |
| Progressive disclosure | Content is assigned to one of four tiers: T1 task, T2 result, T3 explanation, T4 advanced (see `M11B_INFORMATION_HIERARCHY.md`). T1 and T2 are always visible; T3 is one action away and placed next to what it explains; T4 is two actions away or in the Notebook. Nothing is removed. |
| Spatial hierarchy | Space follows content. The circuit height follows the qubit count; the analysis grows into freed space; the inspector exists only while something is selected; reading surfaces are centred and bounded. |
| Context preservation | Activities open *inside* their section. Section navigation stays visible, or collapses to a context strip, so the answers to "where am I?" and "how do I get back?" never disappear. |
| One app, both audiences | There is no beginner or expert mode. Disclosure state is remembered per learner and per section, so an expert who opens Mathematics keeps it open. |

## 3. Shell model [Proposal]

The application has five layers. Each layer has its own surface tone and a single job.

```text
┌ Global nav ┬ Section nav ───────┬ Page header (title · position · primary action) ─────┬───────────┐
│ charcoal   │ deep navy         ├ Primary workspace (navy)                                │ Inspector │
│ Journey    │ curriculum /      │   task · exercise · analysis / article / sphere         │ (only when│
│ Notebook   │ article index /   │                                                         │ something │
│ Mastery    │ challenge list    │                                                         │ selected) │
│ Composer   │ (collapsible to a ├ Action bar (sticky: Hint · feedback · Check)            │           │
│ Bloch      │ context strip)    │                                                         │           │
└────────────┴───────────────────┴─────────────────────────────────────────────────────────┴───────────┘
```

1. **Global navigation.**
   - Contents: the five destinations, the logo (moved from the centred top bar into the rail, which frees 52 px of height) and the version.
   - Width:
     - 232 px at 1440 px and above;
     - a 76 px icon rail from 900 to 1439 px;
     - a top bar with a drawer below 900 px. The existing 900 px breakpoint is kept.
2. **Section navigation.**
   - Contents: the Journey curriculum, the Notebook index or the Mastery list.
   - It stays visible while an activity is open.
   - It collapses to a 64 px numbered rail (Mastery) or to a one-line **context strip** ("Ch 14 Conditional Quantum Logic · ▮▮▮▯▯ · Viewing 14.1 of 5"). It collapses when the learner chooses, or automatically below 1024 px.
3. **Page header.**
   - Contents: a breadcrumb, the title or conceptual question, status chips and the page's primary action.
   - Workspaces such as the Composer and the Bloch Explorer use a one-line compact header.
4. **Primary workspace.**
   - Contents: the circuit and its analysis, the article, the question and options, or the sphere.
   - It has exactly one primary action.
   - Lessons and challenges pin that action in a sticky **action bar**.
5. **Contextual inspector.**
   - Contents: details of the *selected* object only.
   - With no selection it shrinks to a 44 px rail labelled "Inspector · select a gate", and its width returns to the workspace.
   - It is an overlay below 1280 px and a bottom sheet below 600 px.

## 4. Section architectures [Proposal]

| Section | Model | Primary region | Section navigation during an activity |
|---|---|---|---|
| Composer (Sandbox) | Laboratory | Circuit, with the **analysis workspace** below | none (Sandbox) |
| Journey | Guided course | Lesson: question → task → focused exercise → current vs target | Curriculum with the open chapter's lessons expanded, or a context strip |
| Notebook | Interactive textbook | Centred reading surface (default) or two-page spread (option) | Article index, with search |
| Mastery | Exercise workbook | Focused question page, or a focused circuit exercise | Filterable challenge list, or a numbered rail |
| Bloch Explorer | Instrument | Sphere, flanked by **Act** (prepare and gates) and **Read** (state); evolution timeline below | none |

### 4.1 Composer
- **Header:** the qubit selector, undo/redo, Clear, the save status, and one segmented control, **Analysis | Focus circuit**. This replaces the five panel icons (§7).
- **Palette:** a horizontal row of categories (Basic · Phase · Rotations · Multi-qubit · Measure). Unavailable gates are dimmed, with their reason in a tooltip (M9 behaviour).
- **Circuit well:** its height is the qubit count × row height. Its width grows with depth and scrolls horizontally. It never reserves empty rows.
- **Analysis workspace:**
  - Tabs: **State | Measure**, plus **Target** in lesson contexts.
  - The State tab lays out Current state, Probabilities and (one qubit only) the Bloch sphere as a responsive grid of 3, 2 or 1 columns.
  - Measure is an *experiment*: setup on the left; outcomes on the right, with exact (outline) against observed (filled) values and a counts table.
- **Inspector:** on the right, only while a gate or measurement is selected (§5 of the prototypes doc).
- **Sandbox capacity:**
  - Larger circuits get vertical room automatically, because the circuit well grows with the qubit count.
  - Long circuits scroll horizontally.
  - **Focus circuit** hides the analysis for building.

### 4.2 Journey
- **Chapter overview:**
  - The curriculum is on the left.
  - The chapter page is centred: question, **Continue** primary action, lesson list with status, objectives, and "Builds on" links.
- **Active lesson:**
  - The curriculum stays, with the current chapter's lessons expanded.
  - The lesson header holds the question (largest type), the **Task** callout, and a collapsed "More context".
  - The exercise shows *only* the gates the lesson allows, the circuit, and a **Your circuit now | Target** comparison. The target is drawn as a dashed outline on the learner's own probability bars.
  - There is no gate inspector until the learner selects a gate. There are no layout toggles and no zoom.
  - **Check circuit** stays explicit, in the sticky action bar with Hint.
  - The completion explanation appears in place, under the comparison, followed by **Next lesson**.

### 4.3 Notebook
- **Default (Option A):** a centred reading column (≤ 760 px).
  - At 1600 px and above, a right-hand **margin column** holds "On this page", "Where it is used" and notation reminders.
  - Experiments are embedded as figures with **Run in Composer**, using the existing isolated experiment session.
- **Option B (spread):** a book surface with *Explanation* on the left page and *Mathematics and experiment* on the right page.
  - The two pages scroll together; there is no pagination.
  - Below 1280 px it falls back to one column.
  - Recommendation and rationale: `M11B_WORKSPACE_PROTOTYPES.md` §8.

### 4.4 Mastery
- **Question challenges:** a centred workbook page (≤ 860 px):
  - setup callout;
  - figure;
  - question;
  - lettered option cards;
  - hints disclosure;
  - **Check answer** in the action bar.
- **Circuit challenges:** the same focused exercise as a Journey lesson. The list collapses to a numbered rail so the five-qubit circuit gets the width.
- **List state:** search text, filters, scroll position and selection persist while a challenge is open and after returning.

### 4.5 Bloch Explorer
- **Layout:** Act (left) · Sphere (centre, largest) · Read (right). The **evolution timeline** sits under the sphere.
- **Read panel:**
  - Always visible: the state and the Z-basis probabilities.
  - Disclosures: Amplitudes, Bloch coordinates, Angles and Phase (each disclosure header shows a one-line summary), and Measure.
- **Five distinct interactions** (see the prototypes doc §11):
  1. **Preview** (dashed, nothing changes);
  2. **Apply** (commits a step);
  3. **Animate when applying** (a setting);
  4. **Inspect a step** (select a historical chip; a banner offers "Return to current");
  5. **Play steps** (replays the recorded sequence from the start).

## 5. Context-preservation contract [Proposal]

| Context | Preserved across | Mechanism (existing where possible) |
|---|---|---|
| Selected chapter, expanded chapter | lesson open → back | `WebApp` already keeps `_journeyChapter`; extend it to keep the scroll offset |
| Mastery search, filters, scroll, selection | challenge open → back → next challenge | Lift the browser state out of the detail route; today the list is rebuilt |
| Notebook article and scroll offset | open experiment → "Back to article" | The existing experiment banner return path; add scroll restoration |
| Composer Sandbox circuit | any navigation | Existing Sandbox persistence (unchanged) |
| Lesson workspace state | Hint / context disclosure / inspector | Kept in the session; disclosure state remembered per learner |
| Bloch history | leave and return within a session | Existing Bloch session; unchanged |

No persistence schema changes are needed: everything above is in-memory UI state, apart from disclosure preferences. Those could use the existing preferences mechanism and need approval (Review D5).

## 6. What does not change

- Simulation, gates, validation, progression, persistence and content are unchanged.
- There is one shared Composer and session. Lesson, challenge and Notebook presentations are *configurations* of it: which regions are visible and which gates are available. They are not new implementations.
- Explicit Check is kept; completion is never automatic.

## 7. Recommendation

Adopt a **five-layer shell with section-preserving activities** and a **Composer whose analysis lives below the circuit**, with an inspector that appears only for a selection.

- Journey and Mastery reuse one *focused exercise* configuration of the shared Composer.
- The Notebook defaults to a centred reading surface, with a margin column on wide screens.
- The Bloch Explorer separates preview, apply, animate, inspect and play.

This resolves most consolidated findings through shared architecture rather than per-screen patches (see `M11B_REVIEW.md` §2).
