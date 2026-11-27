# Qubit Quest: mathematical notation and presentation guide (v2.6 M9)

These are the conventions every surface follows (Composer, Journey, Mastery, Notebook, Bloch Explorer). They are implemented in a small number of shared formatters. Reuse those formatters; do not write new ones.

| Concern | Implementation |
|---|---|
| Complex numbers (symbolic where exact) | `formatComplex` (`lib/utils/complex_formatter.dart`), `QQFraction` |
| State-vector expressions | `formatQuantumStateTerms`, `joinQuantumStateTerms`, `formatQuantumStateExpression` (`lib/utils/quantum_state_formatter.dart`) |
| Authored text → TeX | `quantumStateNotationToLatex`, `notebookMathNotationToLatex` |
| Gate angle labels | `Gate.fromIdentifier` (`lib/models/selected_gate_type.dart`) |
| Bloch Explorer decimals, angles, expressions | `blochNumber`, `blochComplex`, `blochAngle`, `blochStateExpression` (`lib/models/bloch_lab.dart`) |

## 1. Kets and register order

- **Register kets** are written |q(n−1) … q1 q0⟩: q0 is the rightmost character and the least-significant bit of the amplitude index.
- **Wire order:** on the circuit canvas, q0 is the top wire.
- **Authored initial strings** (for example `initialBinaryState`) are most significant first.
- **Classical outcomes** are written with the highest classical bit on the left, as the Measure panel states.
- **Gate matrices** use a *local* order, which must be stated wherever it could be confused with register order. For example, CY's matrix is in |control, target⟩ order. With control q0 and target q1, the register ket |q1 q0⟩ = |01⟩ is the local |10⟩.

## 2. Complex amplitudes

- **Exact values** are shown symbolically only when they are reliably exact: integers, 1/√2, 1/√3, 1/√5, 1/√8, 1/√32, and fractions with a denominator of at most 64 (`QQFraction.maxExactDenominator`).
- **Anything else** is a four-decimal value (0.7071, 0.1235). Never show an implausible fraction such as 1929/15625.
- **The imaginary unit** has an unambiguous position:
  - `i`, `0.5i`;
  - `i/√2` and `3i/4` (i in the numerator);
  - `i√2`.

  Never write `1/√2i` or `1/2i`, which could be read as 1/(√2·i).
- **Mixed complex coefficients** are parenthesised: `(1/2 + i/2)`, `(0.5000 − 0.5000i)`.
- **Global phase is kept.** Amplitudes are never silently canonicalised: −|0⟩ is shown as −|0⟩.

## 3. State expressions

- **Sign handling:** a negative term is a subtraction. Write `(1/√2)|00⟩ − (1/√2)|11⟩`, never `+ (−1/√2)|11⟩`.
- **Unit coefficients:**
  - ±1 is written without a coefficient: `|0⟩`, `−|0⟩`;
  - ±i is written bare: `i|1⟩`, `− i|1⟩`.
- **Other coefficients** are parenthesised before their ket: `(1/√2)|0⟩`, `(i/√2)|1⟩`.
- **The minus sign** is the true minus (U+2212) in displayed text. Machine-readable outputs, such as copied plain text or TeX, may use `-`.
- **Narrow screens:** expressions wrap between terms (the wrapped state layout), never inside a coefficient.

## 4. Angles

- **Rotations** use fractions of π with π in the numerator: `π/2`, `3π/4`, `−π/4`, `2π`. Never write `1/2π`, which reads as 1/(2π).
- **Bloch Explorer** angles show both forms, `π/2 (1.5708 rad)`, and a step is labelled `Rz(π/2)`.
- **Typed input** accepts radians or multiples of π: `1.5708`, `π/2`, `3pi/4`, `-2π`.

## 5. Phase language

- **Global phase** is a property of how the state vector is written, not an observable. Multiplying the whole state by e^(iγ) changes neither the Bloch point nor any measurement of that qubit. The Explorer's "global phase as written" is the phase of the first non-zero amplitude, which is a convention.
- **Relative phase** arg(β) − arg(α) is physical. It is undefined at the poles, where one amplitude is zero.
- **A rotation that fixes a Bloch point** *may* add a global phase; it does not have to.

## 6. Measurement and correlation statements

- **Name the basis.** "Measured in the Z basis, the two qubits always agree" is correct; "entangled qubits always agree" is not, because Φ⁺ anti-correlates in Y.
- **Z-basis correlations alone** do not establish entanglement: a classical correlated source can reproduce them.
- **Equal probabilities do not mean equal states:** |+⟩ and |−⟩ have the same Z statistics.
- **Exact probability versus observed frequency:** label both. Exact values are the outline; observed frequencies are the filled bar.

## 7. Matrices and identities

- **Matrices** are TeX (`LatexText`), with an explicit statement of their basis order.
- **Large multi-qubit operators** (for example MCX) are described by their rule, t ↦ t ⊕ (c₁⋯cₖ), not by a 2ⁿ × 2ⁿ matrix.
- **Products** read right to left: in (I⊗S) CX (I⊗S†), S† acts first.
