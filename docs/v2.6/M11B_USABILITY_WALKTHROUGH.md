# Qubit Quest v2.6 M11B: usability walkthrough

**Persona:** an adult who has never encountered quantum computing. They are comfortable with web apps and know what a probability is, but not a ket, a matrix or a qubit.

**Viewport:** 1440×900.

**Method:** each scenario follows the proposed design (prototypes in `docs/v2.6/mockups/m11b_prototypes.html`). Where today's app differs materially, that is noted as **Today**.

This is a cognitive walkthrough by the designer, not a study with participants. Testing with real participants is planned in M11F.

---

## 1. Starting the first Journey lesson

- **Initially sees:**
  - the Journey page: curriculum on the left, with Chapter 1 *Information* marked current;
  - the chapter page centred, with its question, objectives and a single primary button, **Start chapter · 1.1**.
- **Primary action:** Start chapter.
- **Then visible:**
  - the curriculum stays, with Chapter 1's five lessons expanded and 1.1 highlighted;
  - the lesson header shows the question in large type and a Task callout;
  - below is the focused exercise for 1.1 *The First Qubit*, a circuit activity (as are all of Chapter 1's lessons): only the lesson's gates in a short palette, a one-row circuit, **Your circuit now / Target**, and **Check circuit** in the action bar;
  - there are no layout toggles, zoom, Measure tab or inspector until the learner selects a gate.
- **Result explained:**
  - feedback appears in the action bar;
  - on success, the completion explanation and the discovery appear in place under the exercise, followed by **Next lesson**.
- **Advanced details:** "More context" under the task; hints; the discovery links to its Notebook article.
- **Return:** click the chapter in the curriculum or the breadcrumb. The chapter page shows 1 of 5 completed and **Continue · 1.2**.
- **Today:** the lesson replaces the curriculum, and the chapter is remembered only in the breadcrumb.
- **Remaining overload risk:** medium. The very first screen is a circuit with kets (|0⟩), so the focused configuration matters most here. Today lesson 1.1 shows the full Composer chrome. Vocabulary in task text is a content issue and outside layout.

## 2. Discovering what a Hadamard gate does

- **Initially sees:** in the Composer, the palette's *Basic* group, with H first in red.
- **Primary action:** drag H onto q0.
- **Then visible:**
  - the analysis updates: "|ψ⟩ = (1/√2)|0⟩ + (1/√2)|1⟩";
  - "Equal amplitudes: the Hadamard turned |0⟩ into |+⟩";
  - probabilities 50 / 50;
  - a Bloch sphere with the arrow moved from the north pole to the equator.
- **Result explained:**
  - selecting the H opens the inspector: "What it does" (one sentence), then "Rule" (|0⟩ → |+⟩, |1⟩ → |−⟩);
  - "In this circuit" is shown where available.
- **Advanced details:** inspector › Mathematics (the matrix H, closed by default); Learn more; Related → the Notebook *Hadamard gate* article.
- **Return:** close the inspector (✕, or click empty canvas). The analysis regains the width.
- **Remaining overload risk:** medium. "|ψ⟩" and "|+⟩" appear before the learner knows kets. Mitigation: the plain sentence comes first. A newcomer should probably meet the Hadamard in the Journey (Chapter 3) before the Sandbox, and the Sandbox could link "New to this? Start the Journey".

## 3. Creating a superposition in the Composer

- **Initially sees:**
  - the Composer header with "1 qubit ▾";
  - an empty one-row circuit with a drop hint;
  - analysis showing |ψ⟩ = |0⟩ and P(0) = 100%.
- **Primary action:** place H (as above).
- **Then visible:** the state has two terms; the bars split 50 / 50.
- **Result explained:** in the State panel's sentence and the Probabilities panel: "Measuring q0 gives 0 or 1, each with probability 1/2. Run the experiment in Measure…".
- **Advanced details:** amplitude decimals (0.7071) in the table; the Bloch angles in the Bloch Explorer via "Open in Bloch Explorer".
- **Return:** undo/redo in the header; the Sandbox persists.
- **Today:** the same data sits in a 340 px column, far from the circuit, beside 750 px of empty canvas.
- **Remaining overload risk:** low.

## 4. Understanding the resulting probabilities

- **Initially sees:** the Probabilities panel (Z basis chip), with two bars at 50%.
- **Primary action:** read; optionally switch to **Measure**.
- **Then visible:** the probability sentence and the Z-basis chip.
- **Result explained:**
  - "each with probability 1/2";
  - the link to Measure ties *exact probability* to *frequency*;
  - the notation rule "equal probabilities do not mean equal states" appears where relevant, e.g. lesson 14.1, through the dashed target and the comparison.
- **Advanced details:** amplitudes versus probabilities: |amplitude|² is stated in the State panel's amplitude table (Decimal column).
- **Return:** stay on the State tab.
- **Remaining overload risk:** low to medium. "Z basis" is jargon; the chip should carry a tooltip ("the standard 0/1 measurement").

## 5. Running a measurement experiment

- **Initially sees:**
  - the **Measure** tab: an Experiment panel ("The M gates on q0 and q1, in the Z basis…");
  - shots 1000 selected;
  - **Run 1000 shots** (primary) and Run once.
- **Primary action:** Run 1000 shots.
- **Then visible:**
  - the Outcomes panel, with outlines (exact) and fills (observed);
  - a counts table, e.g. 507 / 493;
  - "Order: q1 q0".
- **Result explained:**
  - "Measured in the Z basis, q0 and q1 agreed in every shot. The small gap from 50% is finite-shot noise.";
  - the caveat that Z-basis agreement alone does not prove entanglement.
- **Advanced details:** "More about this experiment" (final-state sampling versus mid-circuit measurement, as existing W-phase notes).
- **Return:** switch back to State; the run history is kept until the circuit changes (existing behaviour).
- **Today:** the same controls and data are compressed into the results sidebar.
- **Remaining overload risk:** medium. The legend has two encodings. Mitigation: show the observed fill only after the first run, and the exact outline from the start.

## 6. Looking up the mathematical representation of a gate

- **Initially sees:** either the Notebook search, or a selected gate in the Composer.
- **Primary action:** search "Hadamard" (Notebook), or open inspector › Mathematics.
- **Then visible:**
  - the centred article: title, one-line summary, Intuition, then the matrix in a maths well with its basis order stated;
  - examples with **Run in Composer**.
- **Result explained:** each formula follows the sentence it formalises; the margin column (≥ 1600 px) shows notation reminders.
- **Advanced details:** the notation guide link; related gate articles.
- **Return:** **Back** keeps the index position and article scroll; "Back to article" from an experiment returns to the same scroll offset (to be implemented; Architecture §5).
- **Remaining overload risk:** low for the article; medium in the inspector if Mathematics is expanded by default. It must stay collapsed until the learner opens it.

## 7. Applying a rotation in the Bloch Explorer

- **Initially sees:**
  - a large sphere with the arrow at |0⟩;
  - the Act panel ("Choose a gate to preview");
  - the Read panel: state |0⟩ and P(0) = 100%;
  - an empty timeline with Start |0⟩.
- **Primary action:** choose Rx.
- **Then visible:**
  - the preview card: angle chips (π/2 preselected), "Rotates the vector by π/2 about the x axis", "Result: …";
  - a dashed violet arc and point on the sphere;
  - nothing has changed yet, and the legend says "Preview: not applied yet".
- **Second action:** **Apply Rx(π/2)**. The arrow animates along the arc (Animate when applying is on), a timeline chip appears, and Read updates.
- **Result explained:** the preview sentence, then the timeline chip label "Rx(π/2) · |state⟩".
- **Advanced details:** the Read disclosures for amplitudes (phasor), coordinates, θ/φ and phase, each with an inline summary; "About the Rx gate".
- **Return:**
  - inspect any earlier chip (banner: Return to current);
  - **▶ Play steps** replays the sequence;
  - Undo and Reset are in the transport.
- **Today:** gates apply from a preview card. There is no sequence playback on the web, and "Animate" is ambiguous (see the prototypes doc §11).
- **Remaining overload risk:** medium. The transport has eight controls. Mitigation: group them as *history* (⏮ ◀ ▶ Play, Speed) and *edit* (Undo, Reset), and disable Play until at least one step exists.

## 8. Starting and completing a Mastery Challenge

- **Initially sees:**
  - the Mastery list, searchable and filterable, showing "1 / 48 complete";
  - selecting a challenge shows its summary and **Start challenge** (as today).
- **Primary action:** Start challenge.
- **Then visible:**
  - the list stays: a column at ≥ 1280 px, otherwise a numbered rail;
  - a question challenge opens the centred workbook (setup, figure, question, lettered options);
  - a circuit challenge opens the focused exercise.
- **Result explained:** feedback in the action bar; on success, the explanation in place, then **Next challenge** and **Back to Mastery**.
- **Advanced details:** hints; related Notebook articles from the explanation.
- **Return:** the list keeps its search, filters, scroll and selection. The completion tick appears in the list without reloading.
- **Today:** starting a challenge replaces the list, and filters and scroll are reset on return (consolidated finding F4).
- **Remaining overload risk:** low for question challenges; medium for advanced circuit challenges, which is inherent in their difficulty.

---

## Remaining potential cognitive overload

1. **Kets before concepts in the Sandbox.**
   - *Cause:* the Composer shows kets immediately.
   - *Mitigation:*
     - plain sentences first;
     - a "New to this? Start the Journey" link on the empty Sandbox;
     - tooltips on "Z basis", "amplitude" and "|ψ⟩".
2. **Two encodings in measurement charts** (exact outline, observed fill).
   - *Mitigation:* reveal the observed fill only after a run; one legend line.
3. **Large registers.**
   - *Cause:* 32 amplitudes remain dense even as a map.
   - *Mitigation:* the map plus one sentence about what is unusual (a sign pattern). Lessons provide authored closed forms.
4. **The Bloch transport density.** Group the controls; disable those that are irrelevant.
5. **The inspector's maths.** Keep Mathematics collapsed by default; remember the learner's choice.
6. **Lesson task length.** Some tasks are three sentences of notation. This is a content concern for review (not changed in M11B). The layout gives the task a callout and reading width, but cannot shorten it.
