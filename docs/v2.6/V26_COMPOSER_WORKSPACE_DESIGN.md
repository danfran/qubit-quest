# Qubit Quest v2.6: desktop Composer workspace design

This applies the approved direction (palette left, canvas centre, inspector below, results right) to the components that already exist. Mockups: `docs/v2.6/mockups/composer_workspace_mockups.html`. **[Exists]** marks what is implemented today; **[New]** marks a proposal.

## 1. Layout

```text
┌ Toolbar ───────────────────────────────────────────────────────────────────┐
│ Sandbox · 3 qubits ▾ │ Undo Redo │ Clear │ saved ✓        │ panel toggles  │
├ Palette 208px ┬ Canvas (flex) ──────────────────────────┬ Results 360px ──┤
│ Basic         │ q0 ─H──●────────M─                       │ [State|Measure| │
│ Phase         │ q1 ────⊕──Rz────M─                       │  Bloch]         │
│ Rotations     │ q2 ───────────────                       │                 │
│ Multi-qubit   ├ Inspector (collapsible, 200–260px) ──────┤                 │
│ Measurement   │ selected gate: identity · params · matrix│                 │
└───────────────┴──────────────────────────────────────────┴─────────────────┘
```

| Region | Default | Min | Max | Collapsible |
|---|---|---|---|---|
| Palette | 208 px | 64 px (icon rail) | 280 px | Yes, to a 64 px rail |
| Canvas | Remaining space | 420 px | n/a | No |
| Inspector | 220 px tall | 44 px (header only) | 50% of height | Yes |
| Results | 360 px | 300 px | 520 px | Yes, to a 44 px rail |

Responsive tiers, measured on the workspace host width (not the viewport):

| Tier | Host width | Arrangement |
|---|---|---|
| Wide | ≥ 1200 | Three columns plus inspector |
| Medium (tablet landscape, small laptop) | 760–1199 | Palette rail (64 px), then canvas and inspector, then results as a right drawer *or* a tab row above the canvas. Proposed default: tabs **Circuit · Results**. |
| Narrow | < 760 | Stacked: toolbar, horizontal palette strip [Exists], canvas, inspector, results |

These tiers replace the current mix of 700/960 breakpoints in the Composer. The shell's 900 px sidebar breakpoint stays. A 1024 px window minus the sidebar (≈785 px) lands in **Medium**.

## 2. Gate palette

Categories come from the actual inventory [Exists]:

| Category | Gates |
|---|---|
| Basic | H, X, Y, Z |
| Phase | S, T |
| Rotations | Rx(θ), Ry(θ), Rz(θ) |
| Multi-qubit | CNOT (CX), CZ, CCX (Toffoli) |
| Measurement | M (Z basis) |

- 13 items in total, so **no search** is needed.
- Tiles reuse `QubitQuestGateTile` and the `QubitQuestGateStyle` colours [Exists], at 40 px in the vertical list with the name beside each tile.
- Categories are collapsible. The open state persists only if decision D6 is approved.
- Hover tooltip: one-line description from `GateEducationalCatalog`. Clicking (not dragging) a tile shows that gate's details in the inspector in a *preview* state, which replaces today's status-line hint. [New]
- Parameterised tiles show `θ`. Multi-qubit tiles show their control/target count.
- In lessons the palette shows only `level.availableGates`, and empty categories are hidden.
- Keyboard placement (select a tile, then a wire with Enter) is out of scope for v2.6 and noted as an accessibility gap.

## 3. Circuit canvas

- Reuses `ComposerCircuitCanvas` [Exists], which already provides wires, drag previews, valid/invalid slots, host selection, measurement layer, desktop horizontal scrolling and exact dry-run previews.
- Changes needed:
  - Remove the fixed-height stage sizing (`WebCircuitWorkbenchMetrics.mainRowHeight`) so the canvas fills its region. Keep `canvasHeight` as the drawing height and centre it vertically only when the region is taller.
  - Add vertical scrolling for future qubit counts. This is not needed at 5 qubits (≈220 px drawing height).
- **Zoom: deferred beyond v2.6 (D5).** The original assessment follows for reference. Zoom was recommended as a later option. `CircuitLayoutMetrics` is a set of static consts used by the painter, geometry, hit-testing and tests. Making it instance-based is a cross-cutting change. If zoom is approved (decision D5), make it an M3 stretch item with 3 fixed steps (100/125/150%) applied through `Transform.scale` over the hit-testing coordinate space. Do not use free zoom.
- Leave the circuit area undecorated: no glow, only one surface. The wire labels (`q0`…) stay.

## 4. Gate inspector (below the canvas)

The inspector replaces `ComposerSelectionToolbar` as the selection surface and absorbs the common parts of `GateInspectorDialog`.

| State | Content |
|---|---|
| Nothing selected | One muted line: "Select a gate to inspect it, or drag one from the palette." Plus the circuit summary: depth, gate count, measurements. |
| Single-qubit gate (H) | Tile, name, `q0 · column 2`. Short intuition (1–2 lines). Matrix (2×2, from `GateEducationalCatalog`). Effect on basis states (\|0⟩→\|+⟩, \|1⟩→\|−⟩). Actions: Replace, Duplicate, Delete, **More…** (opens the existing dialog for the full lesson). |
| Rotation (Rz) | **Inspector-first (D3, M3 target).** As above, plus an **angle editor**: numeric field in units of π, presets (π/4, π/2, π, 3π/2) and a slider. Applies with `updateGateParametersWithOutcome` [Exists] on commit, not on every slider tick, to limit autosave churn. The matrix updates live from θ. |
| Controlled (CX, CCX) | Control and target rows (`control q0 → target q1`). Changing them is **not** offered in v2.6, because move semantics are complex. Use delete and re-place. |
| Measurement | Meter glyph, `q1 → c1`, classical-bit selector with used bits disabled [Exists], Delete. |
| Fixed gate (lessons) | Read-only identity and matrix, plus a "Part of the challenge setup" note. No destructive actions. |

Capabilities stay driven by `ComposerSelectedGateCapabilities` [Exists].

## 5. Results panel (right)

Three tabs: **State · Measure · Bloch**. This keeps today's set [Exists] and moves the tabs into the column.

**State tab**
- Amplitude list from `StateVectorDisplay`, with the non-zero filter [Exists].
- An exact probability bar for each basis state [New, presentation only].
- For measured circuits, the header reads **Before measurement** [Exists].
- In lessons, the target state appears below, under a divider [Exists].

**Measure tab**
- Shot field and presets, Run once, Run shots [Exists].
- The histogram shows **observed frequency** as filled bars and **exact probability** as a hollow tick on the same row [New]. The exact probability is computed from the pre-measurement or final state the State tab already shows. It is presented only when it is defined (all measurements terminal) and labelled "Exact".
- The single-run outcome sits above the histogram [Exists].
- Post-measurement state: **backlog (D7)**. Not implemented in v2.6 until the requirements in §5.1 are settled.

**Bloch tab**
- One-qubit circuits: the state, or the pre-measurement state [Exists].
- Multi-qubit circuits: the existing explanation [Exists]. Reduced Bloch vectors are deferred.

### 5.1 Post-measurement states: scientific clarification (corrects M1)

M1 said a post-measurement state could only be shown when every qubit is measured or the unmeasured qubits are unentangled. That is too restrictive.

- **Conditional pure state.** Start from a pure register |ψ⟩ and observe a projective outcome *m* on some qubits (projector Π_m). The *whole register* is then in the well-defined pure state Π_m|ψ⟩ / ‖Π_m|ψ⟩‖, even when the measured and unmeasured qubits were entangled. Example: measuring q0 = 1 on (|00⟩ + |11⟩)/√2 leaves |11⟩. This is what a single run (one known outcome) produces.
- **Reduced subsystems** of that state (for example one qubit of a still-entangled remainder) are in general mixed. They need a density matrix ρ = Tr_rest |φ⟩⟨φ|, not a state vector or a point on the Bloch sphere's surface. A reduced Bloch vector would be inside the ball.
- **Unobserved outcomes.** Averaged over outcomes that were not observed (the ensemble), the register is the mixture Σ_m p_m |φ_m⟩⟨φ_m|. That is not one pure state in general.
- **Executor capabilities to check before implementing:**
  - Does `CircuitExecutor.runShot` expose the collapsed state vector after each shot, or only the classical register?
  - Is renormalisation exposed?
  - Is there any density-matrix path? None exists today.
- **Mid-circuit measurements** (terminal per qubit, W3 rules) mean later unitaries act on other qubits after a collapse. A post-measurement view must say *which point* of the circuit it shows.

**Requirement for M4 or later:** inspect the executor, then decide among:

- (a) the conditional state for the last single run only, clearly labelled with its outcome;
- (b) reduced density matrices;
- (c) not shown.

Nothing here is implemented in M2.

Terminology on screen is fixed as:

- "Exact probability" — Born rule, from the state.
- "Observed frequency" — counts divided by shots.
- "Outcome" — a single run.
- "Before measurement" / "After measurement".

## 6. Toolbar

| Control | Scope | Status |
|---|---|---|
| Mode/title + qubit count (Sandbox: menu 1–5, which replaces "Change") | Global | Exists as "Change" |
| Undo / Redo (Ctrl/Cmd+Z, Shift+Ctrl/Cmd+Z) | Global | Approved (D2). `ComposerSession.undo/redo` exists since M2; the toolbar arrives in M3. |
| Clear (Sandbox, Notebook) / Reset (lessons) | Global | Exists |
| Save state indicator ("Saved in this browser") | Global, Sandbox only | Exists (`CircuitSaveStatusView`) |
| Check circuit, Hint | Global, lessons only | Exists |
| Panel toggles (palette, inspector, results), Reset layout | Global | New |
| Run once / Run shots | **Results panel only** (not in the toolbar, to avoid duplicates) | Exists |

The "Save/Load" from the approved sketch maps to the existing autosave indicator. The named circuit library is **deferred** (D2).

## 7. Resizing and collapsing

- Implement with a small `ResizableSplit` widget: a `Row` with a 6 px `MouseRegion(cursor: resizeColumn)` and `GestureDetector` drag handle, clamped to the min/max values above. Double-click resets the split.
- No docking framework and no new dependency.
- Collapsed and width state is held in an in-memory `WorkspaceLayoutState`. **Persisting it is approved for M3 (D6):** `AppStorage` (shared_preferences), key `qq_web_workspace_layout_v1`, one JSON object, read defensively and falling back to the defaults.

## 8. Accessibility and quality bars

- Text contrast: `textMuted #95A4BC` on `surface #111827` is about 7:1, which is fine. `textMuted` at alpha 0.58 on locked map cards falls below 4.5:1 and must not be reused.
- Visible focus rings use `borderFocus`.
- Every gate tile and canvas cell keeps its semantics label [Exists].

## 9. As built in M3 (supersedes §1–§7 where they differ; §10 supersedes §9 where M3.1 changed it)

The M3 implementation follows the approved screenshot direction:

- palette on the left;
- the circuit in the centre;
- the inspector below the circuit;
- results on the right;
- a compact toolbar on top.

Code lives in `lib/widgets/composer_workspace/`. Screenshots of the real app are in `reports/screenshots/v26_m3/` (git-ignored).

### 9.1 Tiers (measured on the workspace's own width)

| Tier | Rule | Arrangement |
|---|---|---|
| Wide | Canvas ≥ 440 px at the preferred panel widths | Palette (196) · canvas · results (340), inspector below the canvas |
| Compact | Canvas would drop below 440 px | Side panels shrink towards 156 / 280 px. Minimum three-column width is **908 px**. |
| Medium | 640–907 px | Palette rail (56 px) and a **Circuit / Results** switch in the toolbar. Both views stay mounted. |
| Narrow | < 640 px | Stacked toolbar, horizontal palette strip, canvas, inspector and results in one scrolling page |

Real browser widths (sidebar 238 px plus a 1 px divider):

| Browser | Navigation | Workspace | Tier |
|---|---|---|---|
| 1920 / 1600 / 1440 | expanded | 1681 / 1361 / 1201 | wide |
| 1280 | expanded | 1041 | wide |
| 1024 | expanded | 785 | medium |
| 1024 | collapsed (64 px rail) | 959 | compact |
| 800 | drawer | 800 | medium |
| 600 | drawer | 600 | narrow |

Preferred widths are honoured exactly while the canvas keeps 440 px, so a resize drag always tracks the pointer. Shrinking applies only below that.

### 9.2 Inspector

States:

- **Nothing selected:** one line plus circuit facts. The inspector collapses to 112 px while idle.
- **Palette preview:** a gate type, never placed. Shows category, intuition, transformations, matrix and More details.
- **Placed gate:** position, role and actions.
- **Rotation editor.**
- **Controlled gate:** control and target chips, built from a list of controls.
- **Measurement:** classical bit and Delete.
- **Fixed gate:** read-only note.

Actions come from `ComposerSelectedGateCapabilities` (narrowed by the policy), in the order More details · Replace · Duplicate · Delete. Buttons are at least 40 px tall.

Mathematics:

- matrices use `LatexText` with em sizing;
- the rotation matrix is computed with `QuantumMatrix.rx/ry/rz` and shown as text so it can update on every slider tick.

### 9.3 Rotation workflow (D3)

- **Sandbox:** a dropped rotation gets `ComposerPolicy.defaultRotationAngle` (π/2) through `ComposerAngleEntry.defaultOnPlacement` and is selected.
- **Notebook examples:** still prompt on placement.
- **Lessons:** keep their palette preset.

The editor keeps a local draft and commits **once per gesture**: on slider release, on choosing a preset, or on Enter or blur with a valid value. Escape or an invalid value discards the draft. Typed input accepts radians and π notation (`parseAngleExpression`) at full precision with no range reduction, matching the previous dialog.

### 9.4 Results, toolbar and shortcuts

- **Results:** the existing State / Bloch / Measure views, unchanged, in their own scrolling column. The tab choice is workspace state, not session state. Run controls appear only in Measure.
- **Toolbar:**
  - title and context (Sandbox, or "Notebook example · title");
  - a qubit menu that keeps the `web-composer-qubits-N` keys and per-qubit-count storage;
  - Undo, Redo and Clear/Reset;
  - one-line save status with inline Retry;
  - panel toggles, focus mode and reset layout.

  Its leading group scrolls rather than overflow.
- **Shortcuts:** ⌘/Ctrl+Z undoes; ⌘/Ctrl+Shift+Z and Ctrl+Y redo. They are handled once per key press by the visible workspace only, and ignored while a text field has focus or a dialog or menu is open.

### 9.5 Layout preferences (D6)

`WorkspaceLayoutController` stores widths, inspector height, collapsed panels and the navigation-rail choice in `qq_web_workspace_layout_v1`:

- **Previews** happen on each drag tick and are not stored.
- **Commits** happen on drag end, toggles and reset.
- **Reading is defensive:** malformed, out-of-range and future-version records fall back or clamp.
- **Reset layout** keeps the navigation choice.

No circuit state is stored in this record.

### 9.6 Deviations from the approved screenshot

| Screenshot | M3 | Reason |
|---|---|---|
| Large gate tiles on the canvas | 30 px gates at 40 px pitch (unchanged) | Canvas zoom is deferred (D5) and `CircuitLayoutMetrics` is shared. Wide canvases look sparse. |
| "Run circuit" in the header | Run once and Run shots only in Results → Measure | Avoids duplicate run controls, as the brief requires |
| Save icon | Autosave status text or icon | There is no named-circuit library (D2) |
| Predicted-probability histogram beside the observed one | Existing State and Measure views | Exact-versus-observed comparison is M4 |

## 10. M3.1 workspace refinement (as built)

M3.1 refines the M3 workspace after practical use. The architecture is unchanged: every circuit change is still a `ComposerSession` command, and all M3.1 controls are presentation only.

### 10.1 State presentation (State tab)

`StateVectorDisplay` gains an opt-in `structuredLayout` (the desktop Composer turns it on; every other host keeps the single-line expression):

- **Wrapped expression.** Each term `+ (amplitude)|ket⟩` is one unbreakable unit in a `Wrap`, so lines break only between whole terms; a ket or coefficient is never split. It uses `formatQuantumStateTerms` unchanged (signs, real/imaginary parts, exact fractions such as `1/√2` or `3/8 − 1/8i`, the `|q(n−1)…q0⟩` ordering and the 1e‑9 display threshold).
- **Non-zero count.** "8 of 32 amplitudes non-zero".
- **Collapse.** Above 8 terms the expression shows the first 8 and an explicit "+ … N more terms" line, with "Show all N terms" / "Show fewer terms". The display is never silently truncated.
- **Copy.** A copy button puts `formatQuantumStateExpression` on the clipboard: the complete expression, independent of what the panel shows. Format: `|ψ⟩ = (c₀)|b₀⟩ + (c₁)|b₁⟩ + …` with every non-zero term in basis order, unit coefficients written as the bare ket and `0` for the zero state. For a measured circuit the label is `|ψ_pre⟩`, because the copied text loses the "Before measurement" caption.
- **Structured rows.** Basis · Amplitude · Probability. The amplitude is `formatQuantumAmplitude` (the same coefficient formatter as the expression), and the probability bar and percentage are the existing ones. In a narrow panel the bar is dropped when it would be thinner than 36 px; the percentage stays.
- **Scrolling.** One vertical scroll region (the results column); there are no nested scroll regions.
- **Scientific behaviour is unchanged.** Amplitudes, probabilities, tolerances, global phase and the pre-measurement distinction are the existing ones; the "Before measurement" caption stays.

### 10.2 Circuit scale (revised D5)

Supported scales: **100%, 125%, 150%** in the circuit header. **125% is the default**: at 1280–1920 px the 100% geometry (30 px gates, 40 px rows) leaves most of the canvas empty; 125% gives 37.5 px gates and keeps a five-qubit circuit about 260 px tall, so the inspector keeps room at 800 px viewport height. 100% remains for dense circuits and small viewports.

Implementation: a **transformed coordinate space**, not scaled widgets.

- `ComposerCircuitCanvas.scale` wraps the canvas body in one `Transform.scale` (top-left) with an `OverflowBox` that lays it out at `constraints / scale`.
- Everything inside (painter, `CircuitGeometry`, hit-testing, drop destinations, measurement layers, scroll extents, selection outlines, valid/invalid placement indicators) stays in the shared logical `CircuitLayoutMetrics` coordinates. Pointer positions map through the transform via `globalToLocal`, so placement agrees with what is drawn by construction.
- Only overlay drag feedback lives outside the transform and is scaled explicitly: palette feedback is `paletteFeedbackSize(scale)` (34 px at 100%, as before), and measurement-move feedback is `gateSize × scale`.
- Wheel scrolling divides the screen delta by the scale.
- At scale 1.0 the canvas returns its child unwrapped, so native, Journey and Mastery hosts render exactly as before.

### 10.3 Qubit labels and wires

The desktop host sets `pinnedQubitLabels`: a 44 px logical gutter beside the scrolling circuit shows each wire's identifier (`q0`, muted) above its initial state (`|0⟩`, 14 px), aligned on the wire centre in the same scaled coordinate space. Labels stay visible while the circuit scrolls horizontally and scale with the circuit. `QuantumCircuitPainter.showQubitLabels` (default true) and `wireColor` (default white) are additive. The desktop wires use a softened colour; the alternating lanes and empty-slot guidance are unchanged (guides appear only while dragging).

### 10.4 Vertical space

- The circuit region is content-sized: the drawing takes `drawingHeight × scale + 20` and the one-line summary footer sits directly under the last wire.
- With a subject selected, the inspector takes the remaining height (but never less than the learner's preferred height, capped at 60% of the column), so no dead band opens between the circuit and the inspector. Dense or scaled circuits that need more room keep at least 260 px and scroll beyond that.
- With nothing selected the inspector stays compact (112 px).
- The inspector height eases over 160 ms on selection changes and follows the pointer exactly while resizing.
- **Expanded inspector mode** (inspector header button) gives the inspector everything except a 190 px strip of circuit, which stays visible and scrollable. It is transient (not persisted) and returns with the same button.

### 10.5 Integrated educational inspector

```text
GateEducationalCatalog (data)
          │
gate_educational_sections.dart (shared presentation)
     ┌────┴───────────────┐
GateInspectorPanel     GateInspectorDialog (native, Bloch Explorer, lessons)
```

- Sections: **Overview** (identity, relationship, position, actions, intuition, basis transformations and the matrix side by side; the rotation editor for rotations), **Mathematics** (definition, state action, properties, identities; for rotations also the numeric matrix at the current θ from `QuantumMatrix`), **Learn** (the shared illustration, intuition / what changes / common use, related concepts linking to the Notebook, and the controlled-gate Bloch note).
- Tabs are presentation only and persist across selections; content is keyed by subject and tab, so nothing from a previous gate remains. Measurements have no tabs.
- More details is removed from the desktop inspector. `GateInspectorDialog` remains for the other hosts and now composes the same shared sections.
- Maths layout: explanation and configuration on the left (at most 460 px), maths directly beside it, stacked below 560 px. Wide definitions in the Overview shrink to 80% at most and then scroll; the Mathematics section shows them at full size with horizontal scrolling.
- The qubits are named once (the relationship line); the detail line carries the position only.

### 10.6 Remaining dialogs

| Interaction | M3.1 | Reason |
|---|---|---|
| Educational gate inspection | Integrated (no dialog) | Persistent inspector |
| Gate replacement | Anchored menu in the inspector (`MenuAnchor`), valid types only; clicking outside cancels | Uses `ComposerPlacementFlow.replace(type:)`, the same single session command |
| Rotation angle for a replacement or Notebook-example drop | Existing angle dialog | Notebook examples keep their prompt (unchanged policy) |
| Controlled-gate role choice | Existing dialog | Ambiguous control/target choice; inline editor is future work |
| Destructive confirmations | Unchanged | No new confirmations for undoable edits |
| Narrow (stacked) tier palette inspection | Previews in the integrated inspector | The inspector is present below the canvas |

### 10.7 Visual refinements

- One authoritative footer summary: "5 qubits · 11 operations · 1 measurement". Successful edits add no status text; rejections, restores, undo/redo and measurement messages still appear.
- Footer summary keeps priority over status text.
- Inspector header: tabs inline from 820 px, else on their own row; expanded-mode and collapse buttons with tooltips.
- Inline basis transformations at 15 px; identities at the secondary maths size in the inspector.
- The structured State filter label is 11.5 px.

### 10.8 Preferences

`qq_web_workspace_layout_v1` gains an additive `circuitScale` field (still version 1). Records without it get 125%; non-numeric values fall back to 125%; other values snap to the nearest supported step. Reset layout restores 125%. Scale changes commit once and never touch the session (no revision, history, result invalidation or circuit autosave).

### 10.9 Notes for M6a (Journey and Mastery migration)

- `structuredLayout`, `scale`, `pinnedQubitLabels` and the tabbed inspector are opt-in; lesson hosts can adopt them without new APIs.
- Lessons pass a `ComposerPolicy` with fixed gates; the inspector already shows read-only gates with their educational sections.
- Lesson canvases are usually shorter than the Sandbox; the content-sized canvas and inspector fill apply unchanged.

## 11. M4 measurement and results (as built)

The scientific contract, terminology and formatting policy are in `V26_MEASUREMENT_RESULTS.md`. Workspace-level design:

- **State tab:**
  - probabilities use the adaptive policy (3.125%, 42.68%);
  - the percentage column is 60 px and bars are 7 px;
  - the count line adds the total probability computed from the unrounded state, with a warning if the state is not normalised;
  - 1/√8 and 1/√32 are recognised exactly;
  - the amplitude column sizes to the panel (60–118 px).
- **Measure tab:**
  - order: setup, Run once, Run shots and shot count, single run, measurement distribution, conditional state after execution, explanation;
  - the distribution is a vertical list of rows (outcome; Exact / Observed / Count; one linear 0–100% bar with an exact outline and marker and an observed fill);
  - a legend names both encodings;
  - a "Possible or observed / All" filter appears when it hides something;
  - lists longer than 8 rows scroll in a bounded region.
- **Bloch view:** a one-qubit measured circuit gets a "Before measurement / After single run" selector after a Run once.
- **Inspector refinements:**
  - a compact gate identity above Mathematics and Learn;
  - maths sizes 19/21 px, state action and identities 16.5 px, and inline basis states 16.5 px in the desktop inspector only;
  - definition headings from content (Matrix / State transformation / Definition);
  - the Learn illustration at half the column width, 120–180 px tall (the dialog keeps 92 px).

## 12. Educational contexts (M6a, as built)

The workspace is now one widget, `ComposerSessionWorkspace`, used by the Sandbox, Notebook examples, Journey lessons and Mastery challenges. Architecture and contracts: `V26_SHARED_ARCHITECTURE.md` §12.

**Layout additions for exercises:**

- **Context header above the toolbar:**
  - breadcrumb, title and objective, with "More context" for concept intro, evidence and mystery text;
  - essential Mastery evidence starts open;
  - capped at half the viewport, and scrolls beyond that.
- **Action footer below the workspace:** Hint, then progressive inline hints, Check feedback, the completion panel and Check. It is always visible, so Check never scrolls away.
- **Toolbar context label:** "Lesson 3.3" or "Challenge 13". The qubit selector is hidden. Reset restores the authored circuit.

**Presentation rules:**

- **Fixed gates:** a lock badge on the tile corner; the inspector is read-only for them; drag attempts are explained in the status line.
- **Target:** purple in State (`showsTargetState`). Cyan remains current or theoretical data. In Measure, the cyan outline is exact probability and the purple fill is observed frequency, as in M4. Exercises have no Measure view.
- **Completed exercises:** the circuit stays visible and inspectable under a review lock; Check reads "Completed".

**Fixes that apply to every context:**

- the Bloch camera survives tier changes;
- the animating inspector never exceeds the available height.
