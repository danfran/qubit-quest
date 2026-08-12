# Qubit and computational-basis ordering

This document is the authoritative convention for Qubit Quest circuit code and
level authoring.

## Qubit numbering and circuit wires

- Qubits are numbered `Q0`, `Q1`, … from the top circuit wire downward.
- `Q0` is the least-significant qubit.
- A gate API row index is the qubit number: row `0` means `Q0`.

## Ket and binary-string notation

An `n`-qubit computational-basis ket is written in descending qubit order:

```text
|Q(n-1) ... Q2 Q1 Q0⟩
```

Consequently, the leftmost bit belongs to the highest-numbered qubit and the
rightmost bit belongs to `Q0`.

For two qubits:

| Ket | Q1 (bottom wire) | Q0 (top wire) | State-vector index |
| --- | ---: | ---: | ---: |
| `|00⟩` | 0 | 0 | 0 |
| `|01⟩` | 0 | 1 | 1 |
| `|10⟩` | 1 | 0 | 2 |
| `|11⟩` | 1 | 1 | 3 |

`ComposerLevel.fromBinaryString` parses its string as an ordinary base-2
integer. Thus `"10"` selects vector index 2 and means `Q1=1, Q0=0`.

Circuit input labels reverse binary-string characters before assigning them to
top-to-bottom wires. For `"10"`, the top `Q0` wire displays `|0⟩` and the
bottom `Q1` wire displays `|1⟩`.

## State-vector indexing

The amplitude at state-vector index `i` multiplies the ket obtained from the
`n`-bit binary representation of `i`:

```text
index = sum(bit(Qk) * 2^k)
```

For three qubits, index 5 is binary `101`, hence `|Q2 Q1 Q0⟩ = |101⟩`.
Generated Current State labels and authored Target State basis labels use this
same notation.

## Tensor-product ordering

System operators use:

```text
Q(n-1) ⊗ ... ⊗ Q1 ⊗ Q0
```

`Q0` is therefore the rightmost tensor factor. This is the little-endian qubit
indexing convention used by `QuantumMatrix`, while displayed binary numbers
retain their normal most-significant-bit-first spelling.

Examples on `|00⟩`:

- `X(Q0)` produces `|01⟩`.
- `X(Q1)` produces `|10⟩`.
- `H(Q0)` produces `(|00⟩ + |01⟩)/sqrt(2)`.

## Controlled gates

Control and target numbers always name circuit qubits, not character positions
inside the displayed ket.

- `CNOT(Q0 -> Q1)` flips the left ket bit when the right ket bit is 1:
  `|01⟩ -> |11⟩`.
- `CNOT(Q1 -> Q0)` flips the right ket bit when the left ket bit is 1:
  `|10⟩ -> |11⟩`.
- `CZ(Q0, Q1)` changes the sign of `|11⟩` and leaves the other basis states
  unchanged. Control/target ordering is visually meaningful but the CZ unitary
  is symmetric.
- `CCNOT(controls Q0,Q2; target Q1)` maps `|101⟩ -> |111⟩`.

## Authoring rules

1. Write basis kets as `|Q(n-1)...Q0⟩`.
2. When explaining a bit value, name both the qubit and its ket position where
   ambiguity is possible (for example, “Q0 is the rightmost bit”).
3. Canonical solution metadata uses logical qubit numbers, never string offsets
   or screen coordinates.
4. Target vectors use binary-index order `|00...0⟩` through `|11...1⟩`.
5. Do not reverse controls merely to make a target pass. Reconcile prose,
   initial ket, canonical operation, and target metadata against this document.

