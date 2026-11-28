# Qubit Quest: experience design principles

Established in v2.6 M11C from the approved M11B direction. These are permanent principles; every later section redesign (M11D onwards) is reviewed against them.

## 1. Purpose-driven workspaces

Each section has one primary purpose, and its layout is chosen for that purpose, not inherited from another section.

| Section | Primary purpose |
|---|---|
| Journey | Learn and complete guided activities |
| Mastery | Independently solve quantum reasoning problems |
| Notebook | Understand and investigate concepts |
| Composer | Construct and analyse quantum circuits |
| Bloch Explorer | Visually investigate single-qubit state evolution |

The question to ask of any element is: *does it serve this section's purpose here and now?* If not, it belongs elsewhere or behind a disclosure.

## 2. Information hierarchy

Every piece of information is one of three kinds, and its placement follows from its kind:

- **Primary**: immediately relevant to the current task. Always visible, given the most space, never in a narrow sidebar.
  - In the Composer: the circuit, the current state and its probabilities.
- **Contextual**: relevant to the current selection or interaction. Appears when the selection exists and disappears with it.
  - In the Composer: the gate inspector, which exists only while a gate, measurement or palette preview is selected.
- **Advanced**: available when the learner deliberately asks for more detail. Closed by default, with an inline summary saying what is inside.
  - In the Composer: the inspector's *Mathematics* and *Learn more* sections, and the measurement panel's *More about this experiment*.

Information is not placed in a sidebar merely because it is *derived*. Results derived from the circuit are primary in the Composer and sit centrally under it.

## 3. Reuse functionality, not necessarily the entire interface

- All sections share one simulation, one gate catalogue, one circuit-editing session (`ComposerSession` with its `ComposerPolicy`), one validation path and the same visualisation widgets.
- Sections may *compose* those widgets differently. The laboratory Composer and the classic lesson workspace present the same session through the same commands.
- No section introduces its own quantum behaviour, gate definitions or validation.

## 4. Visual structure

- **Layers are separated by tone, not by borders.** The surface ladder (`QubitQuestSurfaces`):
  - navigation is charcoal;
  - content is navy;
  - wells (circuit, maths, charts) sit darker than their surroundings;
  - the contextual inspector sits lighter.
- **Panels are for peers.** Cards are used for peer items in a grid. Content inside a panel is divided by spacing and rules, never by nested cards.
- **One primary action per screen.**
- **Mathematics is never uppercased.** Labels containing symbols use `QqPanelLabel(preserveCase: true)`.
- **Existing gate colours and branding are kept.**
- **Responsive behaviour follows one set of tiers** (`QubitQuestTier`): the viewport decides the shell, and host width decides each workspace. Layouts rearrange; they are never scaled down.

## 5. Scientific honesty in presentation

- Every value shown is derived from the actual simulation state. There are no illustrative or hard-coded results, and no circuit-specific explanations that are not backed by tested rules.
- Exact symbolic values and rounded decimals are distinguished, and rounding affects the display only.
- Exact probabilities and sampled frequencies are never conflated. Sampled results come only from sampling, and each shot prepares and runs the circuit again.
- Basis order (|q(n−1) … q0⟩), the measurement basis and phase information are preserved and stated.

## 6. Typography and scientific components (M11C.1)

- **Web text is set in Inter** (bundled; the "QQ Math Symbols" subset supplies ⟨ ⟩) on the `QqType` scale. Ordinary content uses regular and medium weights; semibold is reserved for headings and the values that matter most. Numbers that line up use tabular figures. The native app keeps its own typography.
- **Scientific information follows one order:** primary result (expression, outcome) → supporting numbers (tables, metadata) → controls → explanation → advanced detail (closed disclosures).
- **Tables are built from one column specification** (`QqDataTable`), so headings sit over their data. Show a second representation only when it adds information (a decimal beside 1/√2, not beside 0.3062).
- **Each component owns its quantity:** the state component shows amplitudes, the probability component shows probabilities, and the Bloch summary shows geometry. They do not repeat each other.
- **Probability scales are fixed at 0–100%.** Any zoom is chosen by the learner and labelled.
- **A recognised state is an equation, never a replacement:** it is shown beside the full vector, with its global phase.

## 7. Learning surfaces (M11D)

- **Location is always visible.** The Journey curriculum or Mastery list stays beside the activity (or as a rail or strip when narrow); opening an activity never feels like leaving the section.
- **The ask is distinct from the explanation.** Every activity shows its identity, its question, and a labelled Task callout; longer context is a disclosure.
- **Validation is stated, never implied.** Targets show what Check actually compares (exact state, state up to global phase, or the whole operator on every input). Matching probabilities is never presented as sufficient, and an example input is labelled as one.
- **Nothing is checked until the learner asks.** Selection is not feedback; correctness appears only after Check.
- **Shared functionality, distinct presentation.** Sandbox, Journey and Mastery compose the same session, canvas, inspector and scientific components in layouts suited to their purpose.
- **Typography adoption.** The Notebook and Bloch Explorer redesigns adopt the `QqType` roles (page and section titles, body at reading width, panel headings and `QqDataTable` for experiments, `meta`, `math`); `WebLearningTextStyles` then moves onto `QqType`.


## 8. Consolidation (M11G)

- **One modern Composer, several hosts.** The Sandbox, Notebook experiments, Journey lessons and Mastery challenges compose the same laboratory (or learning) workspace; each host adds only its own header, policy and session. The classic three-column web layout is no longer reachable in the product (it remains a test seam until its suites move).
- **Experiments say where they come from and that they are isolated.** Breadcrumb to the originating article, title, what the experiment demonstrates, a way back that restores the article's reading mode and scroll, and an "Isolated experiment" marker. Running, editing, resetting or leaving never touches the Sandbox, progress or the Bloch laboratory.
- **Approximation is written as approximation.** An expression with any rounded coefficient is joined with ≈; a coefficient is written exactly (1/√2, 3/8) only when it equals that value to floating-point precision; a recognised state is "=" only when exact, otherwise "≈". Zero (within simulator noise) draws no probability sliver.
- **Experiments before derivations.** Where a panel holds both, the experiment (basis, controls, exact and observed outcomes) comes before the detailed mathematics, which stays one disclosure away.
- **Exact versus observed looks the same everywhere.** Exact probability: cyan outline; observed frequency: filled purple; the same legend (`MeasurementComparisonLegend`) in the Composer and the Bloch Explorer.
- **Motion is labelled.** When the sphere is drawing a path, the numbers show a completed, recorded state, and the panel says which one (applied step, replayed step, paused replay, historical state).
- **Phones keep the experiment immediate.** Controls with nothing to act on collapse to their preferences; the gate palette stays directly under the sphere and never moves when steps appear; short landscape windows use the height for the whole sphere beside the controls.
