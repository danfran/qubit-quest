# Qubit Quest v2.6 M11B: workspace prototypes

**File:** `docs/v2.6/mockups/m11b_prototypes.html`. The file is static and dependency-free, and no route, application state or build includes it. Open it directly with `?s=<id>`; with no query it shows the index.

**Renders:** `reports/screenshots/v26_m11b/<id>-<W>x<H>.png`, produced in headless Chrome. The current application is in `…/before/`.

**Content:** all content is real v2.6 content. Every amplitude, probability and count shown was computed for the circuit drawn; the measurement counts are a plausible 1,000-shot sample.

**Legend for "Function" columns:**
- **Existing** — the feature exists today and only its placement changes.
- **UI** — new presentation over existing data or behaviour.
- **Approval** — new behaviour; listed in `M11B_REVIEW.md` §4.

## Renders produced

| # | Prototype (`?s=`) | Sizes rendered |
|---|---|---|
| 1 | `composer-simple` | 1920×1080 · 1440×900 · 1280×800 · 1024×768 · 800×700 · 390×844 |
| 2 | `composer-complex` | 2560×1080 · 1920×1080 · 1440×900 |
| 3 | `composer-measure` | 1440×900 |
| 4 | `composer-selected` | 1440×900 · 1024×768 · 390×844 |
| 5 | `journey-chapter` | 2560×1080 · 1440×900 |
| 6 | `journey-lesson` | 1920×1080 · 1440×900 · 1280×800 · 1024×768 · 800×700 · 390×844 |
| 7 | `notebook-centred` | 2560×1080 · 1920×1080 · 1440×900 · 390×844 |
| 8 | `notebook-spread` | 1920×1080 · 1440×900 |
| 9 | `mastery-question` | 1920×1080 · 1440×900 · 390×844 |
| 10 | `mastery-circuit` | 1440×900 · 390×844 |
| 11 | `bloch` | 1920×1080 · 1440×900 · 1024×768 · 390×844 |

## 1. Composer, one-qubit circuit (`composer-simple`)

**Circuit:** H on q0.

**Layout:**
- Compact header.
- Horizontal palette. Multi-qubit gates are dimmed, with the line "Multi-qubit gates need 2+ qubits".
- A 1-row circuit well, about 90 px tall where today it fills the centre.
- The analysis workspace:
  - **Current state** (1/√2)|0⟩ + (1/√2)|1⟩, with its amplitude table;
  - **Probabilities** 50 / 50 (Z basis);
  - **Bloch sphere**, with the vector on +x and "Open in Bloch Explorer".
- The inspector is a 44 px rail.

| Element | Function |
|---|---|
| Palette categories, dimmed unavailable gates | Existing (M9) |
| State, amplitudes, probabilities, Bloch (one qubit) | Existing (`QuantumInspectorViews`); moved below the circuit |
| "Equal amplitudes: the Hadamard turned \|0⟩ into \|+⟩" | UI: a one-line plain reading; needs authored or rule-based text (Review D3) |
| Open in Bloch Explorer | Existing exploration hand-off (M8) |
| **Analysis / Focus circuit** | UI (replaces the panel toggles) |

**Responsive behaviour:**
- 3 → 2 → 1 analysis columns.
- The nav collapses to a rail below 1440 px and to a top bar below 900 px.
- On a phone the palette scrolls horizontally.

## 2. Composer, five-qubit circuit (`composer-complex`)

**Circuit:** the Lesson 14.5 oracle in the Sandbox:
- H on q0–q3;
- X then H on q4;
- X on q0 and q2;
- MCX(q0–q3 → q4);
- X on q0 and q2.

**Layout:**
- The circuit height follows the register (5 × 44 px).
- **State:** the closed form |−⟩ ⊗ (1/4)(… − |1010⟩ …), plus a **2 × 16 amplitude sign map**. The map highlights x = 1010 and explains that the uniform minus on q4 = 1 is the auxiliary. The full table is in a disclosure.
- **Probabilities:** a 32-bar uniform chart with the sentence "The phase mark changes no probability".
- **Ultrawide (2560):** the analysis is capped at 1760 px, so charts do not stretch into bands.

| Element | Function |
|---|---|
| Closed-form expression | Existing formatter for ≤ 8 terms; for 32 terms the closed form is authored only in lessons. In the Sandbox, show the existing truncated expression and the map (Review D3) |
| Amplitude sign map | UI over the existing state vector |
| 32-bar chart | UI over existing probabilities |

## 3. Composer measurement experiment (`composer-measure`)

**Circuit:** H, CX(q0→q1), then M on q0 and q1.

**Layout:**
- **Measure** tab: an *Experiment* panel with what is measured, the shot selector (100 / 1000 / 10000), **Run 1000 shots**, Run once, and notes in a disclosure.
- *Outcomes* panel:
  - a legend (outline = exact, fill = observed) and the qubit order q1 q0;
  - bars and a counts table: 507 / 493 / 0 / 0;
  - the basis-named statement and the classical-source caveat.

| Element | Function |
|---|---|
| Run once / run shots / shot count / exact vs observed / outcome order | Existing (M4, W2–W4) |
| Counts table | Existing data; table presentation is UI |
| "Agreed in every shot…" sentence | UI; must be generated from the counts, never hard-coded |

## 4. Selected multi-qubit gate (`composer-selected`)

**Circuit:** H on q0–q2, then MCX(q0,q1,q2 → q3), selected.

**Inspector sections** (top to bottom):
- **Header:** MCX tile, name, "Controls q0, q1, q2 → target q3 · column 2", close.
- **Actions:** Edit controls · Duplicate · Delete.
- **What it does.**
- **Rule** (maths well): t ↦ t ⊕ (c₁c₂c₃), plus "Here: |0111⟩ ↔ |1111⟩".
- **In this circuit:** "one joint state, not a decision".
- **Mathematics** (collapsed): "16 × 16 permutation".
- **Learn more** (collapsed).
- **Related:** Notebook articles, Lesson 14.3.

The analysis stays visible to the left of the inspector. Below 1280 px the inspector overlays; on a phone it is a bottom sheet.

| Element | Function |
|---|---|
| Header, actions, What it does, Rule, Mathematics, Learn, Related | Existing (`GateInspectorPanel` tabs Overview / Mathematics / Learn, `GateEducationalInfo`, M6b links) rearranged as sections |
| "Here: …" applied to the actual controls | UI computed from the placed gate |
| "In this circuit" sentence | Approval (D3): context-sensitive explanation. It could be limited to the existing state-transformation text |

**Inspector control consistency:**
- One close control, always top-right.
- The expand-mode button ("Give the inspector more room") is **removed**; depth goes to the Notebook via Learn and Related.
- Collapse is replaced by close (deselect).

## 5. Journey chapter overview (`journey-chapter`)

**Section navigation:** the curriculum (13 done, 14 current).

**Chapter page** (centred, ≤ 880 px):
- "Chapter 14 · In progress · Your current chapter";
- the title and the chapter question;
- the primary action **Continue · 14.3 Conditions in Superposition**, with "2 of 5 lessons completed";
- the lesson list (Review / Continue / Locked);
- What you will learn;
- Builds on: Ch 8, Ch 9, Notebook · Controlled-Y.

| Element | Function |
|---|---|
| Curriculum, chapter intro, objectives, lesson states, Continue destination | Existing (M5 `WebJourneyOverview`, `continueJourneyDestination`) |
| "Builds on" chips | Approval (D4): needs authored prerequisite links per chapter; the content does not exist yet |

## 6. Journey active lesson (`journey-lesson`)

**Lesson:** 14.1, after the learner has added CX.

**Section navigation:** the curriculum, with Chapter 14's lessons expanded and 14.1 highlighted. Below 1024 px a **context strip** replaces it: "Ch 14 Conditional Quantum Logic ▮▮▮▯▯ Viewing 14.1 of 5".

**Lesson header:** breadcrumb, *Completed · review*, the question, the Task callout, and a collapsed More context.

**Exercise:**
- the palette with only H, S and CX;
- the circuit with locked fixed gates and a drop hint;
- **Your circuit now**: (1/√2)|00⟩ + (i/√2)|01⟩, with bars and a dashed target outline on |01⟩;
- **Target**: |01⟩, plus the validation note.

**Action bar:** Hint 1 of 2, "Nothing is checked until you ask", **Check circuit**.

| Element | Function |
|---|---|
| Lesson palette restriction, fixed gates, target, hints, explicit Check, completion | Existing (`ComposerMode.journeyExercise`, `ComposerPolicy`) |
| Dashed target outline on the learner's bars | UI over the existing target vector |
| Context strip, expanded chapter in the curriculum | UI over existing progress data |
| In-place completion (instead of the panel overlaying the circuit) | UI; same content as today's completion panel |

## 7. Composer layout controls review

[Code] Today the toolbar offers:
- the panel toggles (palette, inspector, results);
- a **Circuit / Results** segmented view in the medium tier;
- **Restore default layout**;
- an inspector expand mode and an inspector collapse control.

[Proposal]

| Control today | Keep? | Under the new architecture |
|---|---|---|
| Palette toggle | No | The horizontal palette is one strip; it can collapse to a single row of categories |
| Results toggle | No | Results become the analysis workspace; **Focus circuit** hides it when building |
| Inspector toggle, collapse and expand mode | No | The inspector appears only for a selection; close = deselect |
| Circuit / Results segmented view (medium) | Yes, renamed | **Analysis / Focus circuit** at all widths |
| Restore default layout | Yes, in an overflow menu | Rarely needed once regions size themselves |
| Zoom 100 / 125 / 150 | Yes | In the circuit well, Sandbox only |

## 8. Notebook: centred (`notebook-centred`) versus spread (`notebook-spread`)

**Option A, centred:**
- index on the left;
- a reading column of at most 760 px, centred in the remaining width;
- at 1600 px and above, a 250 px sticky margin column with On this page · Where it is used · Notation;
- the maths well under the sentence it formalises;
- the experiment figure with **Run in Composer**.

**Option B, spread:**
- one book surface, up to 1,480 px;
- left page *Explanation*: title, lede, Intuition, Quantum view, Related;
- right page *Mathematics and experiment*: What changed?, formula, circuit figure, state, Run;
- the pages scroll together; there is no pagination and no fixed height;
- below 1280 px it becomes one column.

**Evaluation:**

| Criterion | A, centred | B, spread |
|---|---|---|
| Fixes the left-hugging whitespace | Yes | Yes |
| Reading order for a newcomer | Linear: intuition → change → formula → experiment | Splits the narrative; the reader must choose a page |
| Long articles (gate references with 6 examples) | Natural | Right page becomes much longer than the left, leaving empty left space |
| Wide matrices and 5-qubit circuits | Full column width (760) | Half width (≈ 600) → more horizontal scrolling |
| Immersion and "textbook" feel | Moderate | High |
| Accessibility (screen readers, zoom, narrow) | Simple | Needs careful reading order; collapses anyway |
| Implementation | Adjusts the existing article widget | New two-column article composition |

**Recommendation:** make **A the default.** B has genuine value only for *discovery articles with one formula and one experiment* on screens of 1600 px or more, where it is pleasant to keep the explanation and the experiment side by side. Offer B as an optional "Spread" view in M11D only if the review wants it; otherwise defer it. Do not make B the default.

## 9. Mastery question (`mastery-question`)

**Section navigation:** the challenge list with search, filter chips and "1 / 48 complete · showing 6"; challenge 46 is selected.

**Workbook page** (≤ 860 px):
- the header with Prediction and Integration chips and ‹ 45 · 47 ›;
- the setup callout;
- the circuit figure;
- the question;
- lettered option cards, with A selected;
- the Hints disclosure;
- an action bar with the labelling convention and **Check answer**.

All elements are Existing (M6a `WebExerciseWorkspace`, Mastery browser) except the lettered cards and the persistent list, which are UI.

## 10. Mastery circuit (`mastery-circuit`)

**Challenge:** 48.
- The list collapses to a numbered rail (43–48), so the five-qubit circuit gets the width.
- The task callout.
- The palette with X and MCX.
- The locked buggy oracle and a drop hint.
- **Your circuit now** |11110⟩ against **Target for this input** |10110⟩, with "Check tests the whole operator on all 32 inputs".
- **Check circuit.**

All elements are Existing, apart from the collapsed rail (UI).

## 11. Bloch Explorer (`bloch`)

**State:** |0⟩ →H→ |+⟩ →S→ |+i⟩, previewing Rx(π/2) (result |0⟩, which is exact).

**Act panel:** Prepare | Gates. Rx is selected and violet-outlined. The *Previewing Rx(θ)* card shows:
- angle chips π/4 · π/2 · π · custom;
- "Rotates the vector by π/2 about the x axis";
- "Result: |0⟩";
- **Apply Rx(π/2)** and Cancel;
- an About-the-gate disclosure.

**Stage:**
- the sphere, with the current vector at +y;
- a **dashed violet arc** to the preview point at |0⟩;
- the faint path so far;
- a legend: current · preview, not applied · path;
- Drag vector and Reset view.

**Timeline:** `Start |0⟩ → H·|+⟩ → S·|+i⟩ ⇢ Rx(π/2)·preview`, with the transport ⏮ · ◀ Step · **▶ Play steps** · Step ▶ · Speed · Undo · Reset · ☑ Animate when applying.

**Read panel:**
- always open: the state (1/√2)|0⟩ + (i/√2)|1⟩ = |+i⟩ and the Z probabilities 50/50;
- disclosures, with inline summaries: Amplitudes (open), Bloch coordinates "x 0 · y 1 · z 0", Angles "θ π/2 · φ π/2", Phase "relative π/2", Measure in a basis;
- the single-qubit boundary note.

### Playback finding (brief §7) [Code]

**Native app** (`BlochExplorerScreen`, `bloch_explorer_panels.dart`):
- a transport with **Undo, Redo, Replay and Reset**, plus an **Instant** checkbox;
- **Replay** re-animates the recorded sequence.

**Web Bloch Explorer** (`web_bloch_workspace.dart`, M8):
- Undo, Redo and Reset;
- an **Animate** filter chip (animate each Apply);
- a selectable evolution list, with a "return to current" banner for inspecting a past step;
- **no sequence playback**.

The play capability therefore existed on native, was not carried into the web workspace in M8, and is *not* represented by Animate: Animate only controls how one Apply is shown.

### Recommended playback model

| Interaction | Meaning | Control | Changes state? |
|---|---|---|---|
| Preview | Show where the chosen gate would take the state | Selecting a gate; angle chips | No (dashed) |
| Apply | Commit the previewed gate as a new step | **Apply** in the preview card | Yes |
| Animate when applying | How Apply is shown (rotation along the arc, or instant) | Checkbox; replaces web Animate and native Instant | No |
| Inspect a step | View a past state; the current state is kept | Select a timeline chip; banner "Viewing step 2 of 3 · Return to current" | No |
| Play steps | Animate the recorded sequence from Start to the current state | **▶ Play steps** (pause while playing), Step ◀ ▶, Speed | No |

Play is disabled with fewer than one applied step. Previews are never part of playback. Playback reuses the existing animation path (`_motion` / evolution model), so there is no new simulation.

## 12. Responsive matrix (rendered)

| Width × height | Composer (simple) | Journey lesson |
|---|---|---|
| 1920×1080 | Nav 232; 3-column analysis; inspector rail | Curriculum + lesson; comparison side by side |
| 1440×900 | Nav 232; 3-column analysis | Same |
| 1280×800 | Nav rail 76; 2-column analysis | Curriculum 228 |
| 1024×768 | Rail; 2 columns; Bloch wraps to a second row | Context strip replaces the curriculum; comparison stacks |
| 800×700 | Top bar; 1 column | Context strip; action bar pinned |
| 390×844 | Top bar; palette scrolls; inspector as bottom sheet | Question, task, palette, circuit, comparison; action bar pinned |

## 13. Defects found and fixed in the prototypes themselves

- **Uppercased labels changed maths:** θ became Θ. The mathematics rule in the visual design doc §5 now forbids maths inside uppercased labels.
- **The margin column was squeezed at 1440 px.** It is now shown only from 1600 px.
- **Panels stacked badly at narrow widths:** flex shrink caused overlap on phones in the lesson and Bloch prototypes. Children are now non-shrinking, and the order on phones is sphere first.
- **Ultrawide charts stretched into bands.** The analysis is now capped at 1760 px.
