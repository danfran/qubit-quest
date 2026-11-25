# Qubit Quest v2.6: measurement and results specification (M4)

Status: implemented in M4 (2026-11-25). This is the tracked contract for how Qubit Quest calculates and presents quantum states, probabilities and measurement outcomes. It complements `docs/qubit_ordering.md`.

## 1. Terminology

The interface uses these five terms and never interchanges them.

| Term | Meaning | Where it appears |
|---|---|---|
| **Quantum state** | The complex state vector of a unitary circuit, \|ψ⟩ = Σ αₓ\|x⟩ | State tab; the Bloch view of an unmeasured one-qubit circuit |
| **Exact probability** | A theoretical probability of a measurement outcome, calculated from the circuit (P(x) = \|αₓ\|² for a computational-basis measurement of a pure state) | State tab Probability column; Measure tab "Exact" |
| **Observed frequency** | count(x) / N over N sampled runs | Measure tab "Observed" and "Count", only after Run shots |
| **Single-run outcome** | One sampled classical result | Measure tab "Single run" |
| **Conditional state after execution** | The full register state left by one specific run, conditioned on its outcomes | Measure tab; the Bloch "After single run" view of a one-qubit circuit |

For a circuit with M operations, the State tab shows the **state before measurement** (`|ψ_pre⟩`), and only when it is well defined. A multi-shot histogram is never described as a quantum state. An unexecuted measured circuit is never shown as a known post-measurement state.

## 2. Supported execution configurations

| Circuit | Experiment run by Run once / Run shots | Outcome label |
|---|---|---|
| No M operations | **Final-state sampling:** each shot measures every qubit of the ideal final state in the Z basis (`FinalStateSampler`) | Basis state `q(n−1)…q0`, shown as `\|x⟩` |
| With M operations | **Explicit measurement:** each shot executes the circuit program in order, projecting at every M (`CircuitExecutor.runShot`) | Classical bits written by measurements, highest classical bit on the left (`ClassicalReadout`) |

Classical-register rules (unchanged from M2/M3):

- Bits that no measurement writes are omitted from the label.
- When legacy circuits write one bit twice, the last write wins.
- The register width is the program's `classicalBitCount`.

## 3. Exact distribution semantics

`ExactMeasurementDistribution` (in `lib/models/measurement_distribution.dart`) describes **the same experiment** as Run once and Run shots, with identical outcome keys and order.

- **Final-state sampling:** P(x) = |αₓ|² for every basis state, from the same state vector the sampler uses.
- **Explicit measurement:** `CircuitExecutor.exactDistribution` follows both outcomes of every measurement, weighted by its Born probability, using the shots' own gate application and projection code. No random draws are made.
  - Register labels are projected onto the measured bits and summed.
  - Branching is capped at 4,096 branches; beyond that the distribution is unavailable with a reason.
- **Partial measurement:** measuring a subset of qubits marginalises over the rest automatically. P(q = b) is the sum of |αₓ|² over every x whose bit q equals b. Example: the Bell state with only q0 measured gives the outcomes `0` and `1` at 50% each. It never gives two-qubit labels.
- **Measurement ordering:** the enumeration follows program order, so operations after a measurement are handled exactly:
  - **On other qubits:** these commute with the measurement and agree with the terminal pre-measurement state, which is tested.
  - **On the same qubit:** legacy circuits only. The pre-measurement state is undefined there, but the exact distribution still exists.
- **Availability:** the distribution is unavailable only when the circuit cannot be simulated (a simulation error, an invalid program or the branch budget). Valid observed results are still shown, and no other distribution is substituted.
- **Caching:** `ComposerSession.exactDistribution` caches the distribution per circuit revision.
- **Equivalence with the executor:** the exact distribution agrees with 10,000 executor samples within 5σ on an interleaved three-qubit circuit (test).

## 4. Conditional state after execution

`MeasuredCircuitRunner.runOnce` now keeps `SingleShotOutcome.conditionalState`. This is the final register state from **the same** `runShot` call that produced the displayed outcome. Each measurement projects P|ψ⟩/√p, and every later operation is applied.

- **Partial measurement of an entangled register:** gives a valid conditional pure state of the whole register. For example, Bell with q0 measured gives |00⟩ or |11⟩. GHZ followed by H on q0, then measuring q0, gives (|000⟩ + |110⟩)/√2 or (|001⟩ − |111⟩)/√2; the unmeasured qubits stay entangled.
- **Final-state sampling:** has no explicit measurement, so no conditional state is shown.
- **Run shots:** never shown as a state. The single run and the shot experiment are labelled as separate executions.
- **Reduced subsystems:** density matrices remain out of scope; no reduced state is shown.
- **Persistence:** the circuit, its initial state and its pre-measurement state are never modified, and nothing is persisted.

**D7 decision:** conditional post-measurement states are **implemented for Run once**, using the executor's existing per-shot state. There is no rerun and no new simulation path. The M1 restriction on partial measurement of entangled states is withdrawn. Remaining follow-ups: reduced single-qubit Bloch vectors and density-matrix views (beyond v2.6).

## 5. Bloch view

- **Unmeasured one-qubit circuit:** the ideal state, unchanged.
- **Measured one-qubit circuit:** "Before measurement" by default. After a Run once, a selector offers "After single run" with that run's conditional state, labelled with its outcome.
- **Multi-qubit circuits:** the Bloch view remains unavailable. No reduced Bloch vector is drawn for entangled subsystems.

## 6. Probability formatting policy

`formatProbability` (in `lib/utils/probability_format.dart`) is used for exact probabilities and observed frequencies in the Measure tab and the desktop State tab:

- **Exact representations:** percentages with up to three decimals keep their digits: 50%, 12.5%, 3.125%, 9.375%.
- **Other values:** two decimals, e.g. 42.68%, 7.32%, 85.36%, 33.33%.
- **Small values:** a non-zero value never reads 0%; below 0.01% it reads `<0.01%`.
- **Near certainty:** a value below certainty never reads 100%; above 99.99% it reads `>99.99%`.
- **Floating-point noise:** values within 1e‑12 of 0 or 1 are treated as exact.
- **No adjustment:** values are never rounded to force a sum of 100%. The total is computed from the unrounded values and shown as "Total exact probability".

Symbolic amplitudes use the existing recognition rule (`QQFraction`, tolerance 1e‑11), now also covering 1/√8 and 1/√32. The State tab therefore shows 1/√32 and 3.125% for five Hadamards. The copied state expression uses the same formatter: symbolic where recognised, otherwise four significant decimals, as before.

Other hosts (lessons, native) keep their existing percentage format until M6a.

## 7. Measure tab and histogram semantics

**Order of sections:**

1. measurement setup;
2. Run once;
3. Run shots with its shot count;
4. the latest single run;
5. the measurement distribution;
6. the conditional state after execution;
7. a short explanation.

**Distribution rows:**

- **Which rows:** the union of outcomes with non-zero exact probability and every observed outcome. "All" lists every outcome the readout can produce, with zeros. An observed outcome is never hidden; if its exact probability is zero it is flagged as a likely implementation problem.
- **Columns:** Exact, then Observed and Count. The Observed and Count columns appear only after Run shots, so there are no artificial zero observations before sampling.
- **Bars:** each row has one linear 0–100% bar. The exact probability is a cyan outline ending in a marker; the observed frequency is a filled purple bar. The legend names both, so colour is not the only cue.
- **Shot labelling:** "N SHOTS" names the experiment shown. Editing the shot count never relabels an old result; a note says the configured count differs.
- **Long lists:** above 8 rows the list scrolls in a bounded region, so a new result is always revealed (the W4.2 contract).
- **Setup line:** names the mode and every mapping (`Measures q0 → c2, q2 → c0`). When some qubits are unmeasured, it notes that outcomes are classical-register values, not full basis states.

## 8. Results lifecycle (unchanged from M2, now verified for M4)

**Results are cleared on:** every committed definition change, including:

- gate insert, remove and move;
- angle changes;
- measurement placement, move and classical-bit change;
- clear or reset;
- undo and redo.

**Results are kept on purely presentational changes:**

- selection and palette preview;
- inspector and results tabs, maths expansion and expanded mode;
- circuit scale, panel resize and collapse;
- navigation collapse and responsive tier.

**Stale runs:** a run started before an edit is discarded (results revision).

**No side effects:** sampling never mutates the circuit, creates history or triggers autosave. Each run is a fresh experiment on the current circuit. Sampling is never automatic or continuous.

## 9. Known limitations

- Reduced states of subsystems (density matrices) and multi-qubit reduced Bloch vectors are not shown.
- The exact distribution is unavailable beyond 4,096 measurement branches. This is unreachable with 5 qubits and terminal measurements; it can only occur in pathological legacy circuits.
- Lesson and native hosts do not yet use the exact comparison or the new formatter (M6a for lessons).
