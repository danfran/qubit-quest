# Qubit Quest v2.6 M11B: review

Status: **M11B complete; awaiting explicit approval of the direction before M11C.** This milestone was design-only.

**Production code:** no file under `lib/` or `web/` was modified, and no test files were changed.

**Tests:** the project test suite was not run. One throwaway probe test was created and deleted, to read the first lessons' types.

**Release state:** no commit, push, publish or deploy. The version is unchanged.

## 1. Deliverables

| Deliverable | Location |
|---|---|
| Experience architecture | `docs/v2.6/M11B_EXPERIENCE_ARCHITECTURE.md` |
| Information hierarchy | `docs/v2.6/M11B_INFORMATION_HIERARCHY.md` |
| Visual design | `docs/v2.6/M11B_VISUAL_DESIGN.md` |
| Workspace prototypes (descriptions, function mapping, Notebook A/B evaluation, Bloch playback finding) | `docs/v2.6/M11B_WORKSPACE_PROTOTYPES.md` |
| Usability walkthrough | `docs/v2.6/M11B_USABILITY_WALKTHROUGH.md` |
| Implementation plan (M11C–F) | `docs/v2.6/M11B_IMPLEMENTATION_PLAN.md` |
| This review | `docs/v2.6/M11B_REVIEW.md` |
| Prototype file (11 screens, responsive, isolated) | `docs/v2.6/mockups/m11b_prototypes.html` |
| Prototype renders (34) and current-state captures (6) | `reports/screenshots/v26_m11b/` and `…/before/` (git-ignored) |

## 2. Consolidated M11 findings

**Resolution:**
- **A** — resolved by shared architecture (shell, tiers, analysis workspace, inspector v2, focused exercise, section navigator);
- **D** — needs a dedicated correction.

| # | Finding | Evidence | Resolution | Where |
|---|---|---|---|---|
| F1 | Notebook alignment and excessive whitespace | `before/notebook_article_1920x1080.png`: the article starts at the index edge, with about 520 px empty to the right | A (centred reading surface, margin column) | M11D |
| F2 | Potential book-inspired Notebook presentation | — | D (optional spread; recommendation: not the default) | M11D, if approved |
| F3 | Missing or unclear Bloch playback | [Code]: native has Replay; web has only Animate and history inspection | D (Play steps, and separated interactions) | M11E |
| F4 | Loss of navigation context when starting challenges | The list is replaced; filters and scroll are not restored | A (section navigator persists) | M11D |
| F5 | Flat visual hierarchy across sections | Near-identical black surfaces; logo bar and headers on one plane | A (surface ladder, page header band) | M11C → D |
| F6 | Loss of chapter context when starting lessons | Lesson replaces the curriculum; breadcrumb only | A (curriculum with expanded chapter, context strip) | M11D |
| F7 | Excessive Composer functionality in simple exercises | Lessons show toggles, zoom, the inspector and results tabs | A (focused exercise configuration S9) | M11C/D |
| F8 | Inconsistent Gate Inspector collapse controls | Reported in the manual review; in code, the expand and collapse buttons share the header's right edge with tabs that move inline above 820 px | A (one close control, top-right) | M11C |
| F9 | Unclear inspector expand/resize controls | The "Give the inspector more room" icon beside collapse | A (expand mode removed; depth goes to the Notebook) | M11C |
| F10 | Unstructured Gate Inspector content | Overview tab mixes description, basis states and matrix side by side | A (stacked sections with disclosures) | M11C |
| F11 | Excessive circuit workspace allocation | `before/composer_one_qubit_1920x1080.png`: ~750 px empty canvas for one gate | A (circuit well sized to the register) | M11C |
| F12 | Compressed measurement information | `before/composer_measure_tab_1920x1080.png`: experiment in a 340 px column | A (Measure as an experiment in the analysis workspace) | M11C |
| F13 | Inappropriate timing and placement of advanced information | Matrices, coordinates and phase notes visible by default (inspector, Bloch right column) | A (four tiers; T4 collapsed with inline summaries) | M11C/E |
| F14 *(new)* | Composer entry page is a single wide card with five buttons | `before/composer_entry_1920x1080.png` | D (qubit selector in the header; open straight into the Sandbox) | M11C |
| F15 *(new)* | Selecting a gate shrinks the circuit to ~140 px | `before/composer_measure_tab_1920x1080.png` | A (inspector on the right, never over the circuit) | M11C |
| F16 *(new)* | Lesson completion panel overlays the circuit | M10 screenshots 06 / 08 | A (in-place completion) | M11D |
| F17 *(new, from M10)* | Completion explanations render TeX as plain text | M10 report §14 | D (render `solutionExplanation` with `WebLearningText`) | M11D |
| F18 *(new, from prototyping)* | Uppercased labels alter mathematical symbols (θ → Θ) | Prototype pass | A (the `nocase` label rule) | M11C |

Of 18 findings, 14 are resolved by shared architecture (F1, F4–F13, F15, F16, F18) and 4 need dedicated corrections (F2, F3, F14, F17).

## 3. Scientific-correctness safeguards carried into the design

- **Bloch sphere:** shown only when `supportsBloch` (one qubit), with the existing explanation otherwise. The Bloch Explorer keeps its single-qubit boundary statement: reduced states of entangled qubits are not shown as pure states.
- **Measurement statements** always name the basis and the qubit order; Z-basis agreement is never presented as proof of entanglement.
- **Notation:** the existing formatters are kept, with no new formatter; the notation guide applies. Maths never sits in uppercase labels.
- **Generated explanatory sentences** are allowed only from tested rules (D3).

## 4. Decisions requiring approval

| ID | Decision | Recommendation |
|---|---|---|
| D1 | Adopt the five-layer shell, surface ladder and unified tiers (logo moves into the global nav; the centred top bar is removed on desktop) | Approve |
| D2 | Notebook presentation | Option A (centred) as the default. Option B only as an optional view for wide screens, or defer it |
| D3 | Context-sensitive explanatory sentences in the analysis and inspector ("Equal amplitudes…", "In this circuit…", "agreed in every shot…") | Approve, limited to rule-generated, test-covered statements; otherwise omit |
| D4 | "Builds on" prerequisite chips on chapter pages | Defer (needs new authored content; M11B forbids content changes) |
| D5 | Persist disclosure preferences across sessions | In-memory only for v2.6; revisit later |
| D6 | Remove the inspector expand mode and the panel toggles; introduce Analysis / Focus circuit | Approve |
| D7 | Bloch playback model (Preview · Apply · Animate when applying · Inspect · Play steps) and porting Replay to the web | Approve |
| D8 | Apply the shell v2 and layouts to web only; native layouts unchanged in v2.6 | Approve |

## 5. Overall recommendation

Adopt the **section-preserving, five-layer architecture**:

1. **A laboratory Composer.** The analysis lives under a circuit sized to its content, and the inspector appears only for a selection.
2. **One focused-exercise configuration of that Composer,** shared by Journey lessons and Mastery circuit challenges. Their navigation stays beside them.
3. **A centred Notebook reading surface,** with a margin column on wide screens.
4. **A Bloch instrument** that separates preview, apply, animate, inspect and play.

Implement it as M11C → M11D (with M11E in parallel once the shared tokens and disclosures exist) → M11F, in the order of `M11B_IMPLEMENTATION_PLAN.md`.

This makes the existing complexity navigable without removing any of it, and needs no change to simulation, validation, persistence or content.

## 6. Limitations of this milestone

- The prototypes are static HTML. They do not exercise real drag and drop, focus order or screen-reader behaviour; those are validated in M11C–F against the Flutter implementation.
- The usability walkthrough is a designer's cognitive walkthrough, not testing with participants (planned for M11F).
- The prototype typography uses system fallbacks for Roboto and a serif maths face, so the app's `LatexText` rendering will differ slightly.
