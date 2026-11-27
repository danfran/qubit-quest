# Qubit Quest v2.6 M11B: information hierarchy

Every piece of information the application shows today is assigned to one of four tiers. **Nothing is removed**; tiers decide position, prominence and when an item appears.

| Tier | Question it answers | Visibility | Treatment |
|---|---|---|---|
| **T1 Task** | What am I supposed to do? | Always visible, top of the primary region | Largest type (the question), task callout with a cyan rule, one primary action |
| **T2 Result** | What happened as a result of my action? | Always visible, adjacent to the action | Analysis panels, current vs target, feedback in the action bar |
| **T3 Explanation** | Why did that happen? | One action away, placed next to what it explains | "More context", hints, completion explanation, inspector "What it does" |
| **T4 Advanced** | What is the full mathematics? | Two actions away, or in the Notebook | Matrices, full amplitude tables, Bloch coordinates, phase analysis, experiment notes |

**Orientation.** "Where am I?" and "where can I find more?" are answered by the shell, not by content:
- position comes from the section navigation or the context strip, plus the breadcrumb;
- further information comes from the inspector "Related" links and the Notebook margin column.

## 1. Per-screen allocation

### 1.1 Composer (Sandbox)

| Item (exists today) | Today | Tier | Proposed place |
|---|---|---|---|
| Gate palette | Left column, vertical, 208 px | T1 | Horizontal strip under the header |
| Circuit | Fills the centre regardless of size | T1 | Circuit well, height = qubits × row |
| State expression | Results column (340 px) | T2 | Analysis › State › Current state (headline) |
| Amplitude table | Results column | T2 (≤ 8 rows) / T4 (more) | Under the expression; for > 8 terms, a sign/magnitude map with the full table in a disclosure |
| Probabilities | Results column | T2 | Analysis panel beside the state |
| Bloch view (1 qubit only) | Results tab | T2 | Third analysis panel, shown only when `supportsBloch`, with a one-line reason otherwise |
| Measure setup, run and histogram | Results tab, compressed | T2 | Analysis › Measure, laid out as an experiment |
| "More about this experiment" | Results tab | T3 | Disclosure in the experiment panel |
| Gate inspector: identity and actions | Bottom panel | T2 (when selected) | Right inspector header and action row |
| Inspector Overview / Mathematics / Learn tabs | Tabs | T3 / T4 / T3 | Stacked sections: What it does (open) → Rule (open) → In this circuit (open) → Mathematics (closed) → Learn more (closed) → Related |
| Qubits / Depth / Gates / Measurements counters | Inspector footer | T3 | One meta line under the circuit |
| Layout toggles (5 icons) | Toolbar | — | Replaced by **Analysis / Focus circuit** (see prototypes §7) |

### 1.2 Journey lesson

| Item | Tier | Place |
|---|---|---|
| Conceptual question | T1 | Lesson header, largest type |
| Task | T1 | Task callout |
| Allowed gates | T1 | Palette limited to the lesson's gates; no category headers when ≤ 6 gates |
| Fixed-gate lock explanation | T1 | Meta line under the circuit |
| Current state and probabilities | T2 | "Your circuit now" |
| Target | T2 | "Target", plus a dashed outline on the learner's bars |
| Validation note ("checks the whole operator…") | T3 | One line under the target |
| More context (concept intro) | T3 | Collapsed under the task |
| Hints | T3 | Hint button; reveals one hint at a time |
| Feedback after Check | T2 | Action bar, with a coloured stripe |
| Completion explanation, discovery, next mystery | T3 → T2 after completion | In place below the comparison, followed by Next lesson |
| Gate inspector | T3 | Appears only when the learner selects a gate |
| Measure tab, zoom, layout toggles | T4 | Not shown in lessons unless the lesson places M gates (existing `ComposerPolicy.allowsMeasurement`) |

### 1.3 Notebook article

| Item | Tier | Place |
|---|---|---|
| Title, one-line summary | T1 | Article head |
| Intuition | T2 | First section |
| What changed? and Quantum view | T3 | Following sections |
| Formula | T3 | Maths well (violet rule), directly after the sentence it formalises |
| Circuit example | T3 | Figure, with **Run in Composer** |
| Related concepts, where used | T3 | Article end (≤ 1599 px) or margin column (≥ 1600 px) |
| Notation reminders | T4 | Margin column, linking to the notation guide |

### 1.4 Mastery question

| Item | Tier | Place |
|---|---|---|
| Title, type and level chips | T1 | Workbook head |
| Setup | T1 | Setup callout |
| Circuit figure | T1 | Inset figure |
| Question | T1 | Large type above the options |
| Options | T1 | Lettered cards |
| Hints | T3 | Disclosure |
| Labelling convention | T3 | Action bar left |
| Explanation after Check | T2 | In place under the options |

### 1.5 Bloch Explorer

| Item | Tier | Place |
|---|---|---|
| Sphere with the current vector | T1/T2 | Centre stage |
| Gate grid, or Prepare | T1 | Act panel |
| Preview card (angle, result, Apply/Cancel) | T1 | Act panel, violet, mirrored by the dashed arc on the sphere |
| State expression and Z probabilities | T2 | Read panel, always open |
| Amplitudes (phasor), Bloch coordinates, θ/φ, global and relative phase | T4 | Read disclosures, each header showing a one-line summary (e.g. "x 0 · y 1 · z 0") |
| Measure in a basis | T3 | Read disclosure (an experiment, as in the Composer) |
| Evolution history, transport | T2 | Timeline under the sphere |
| Single-qubit boundary statement | T3 | Read panel footer (kept verbatim) |

## 2. Disclosure rules

1. **Disclosures are labelled with their content**, never "Details" or "More". Where useful, the header shows a summary ("Angles · θ π/2 · φ π/2"), so an expert can read the value without expanding.
2. **Disclosure state is remembered** per learner per section. Opening "Mathematics" once keeps it open in the inspector. (In-memory now; persistence would need approval, Review D5.)
3. **An explanation sits beside what it explains.** The inspector explains the selected gate, not the circuit; the experiment notes sit under the experiment, not in a global footer.
4. **Advanced content is never the first thing in a region.** Matrices and coordinates follow the plain-language statement they formalise.
5. **No information is lost at narrow widths.** Regions stack in tier order: T1 → T2 → T3 → T4.

## 3. The five orientation questions, per screen

| Screen | Where am I? | What do I do? | What am I looking at? | What happened? | Where is more? |
|---|---|---|---|---|---|
| Composer | Global nav + header "Composer · Sandbox · n qubits" | Palette → circuit | Circuit well; analysis tab title | Analysis updates live; save status | Inspector Related; "Open in Bloch Explorer"; Notebook |
| Journey lesson | Curriculum (expanded chapter) or context strip; breadcrumb | Task callout; Check in the action bar | "Your circuit now" vs "Target" | Comparison; feedback stripe; in-place completion | More context; hints; inspector; Notebook discovery |
| Notebook | Index highlight; breadcrumb; "Discovery 5 of 5 · from Lesson 14.5" | Read; Run in Composer | Section headings; "On this page" | Experiment opens in place, with Back to article | Related; Where used |
| Mastery | List highlight or numbered rail; "Challenge 46 of 48" | Choose an option or build; Check | Setup, figure, question | Feedback and explanation in place | Hints; related Notebook articles |
| Bloch | Global nav; header | Pick a gate → preview → Apply | Sphere legend (current / preview / path) | Timeline gains a step; Read updates | Read disclosures; "About the gate" |
