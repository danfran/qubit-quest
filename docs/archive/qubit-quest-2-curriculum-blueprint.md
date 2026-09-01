# Qubit Quest 2.0 – Vision & Curriculum Blueprint

## Vision

Qubit Quest 2.0 is not a gate-learning game.

Qubit Quest 2.0 is an interactive journey that teaches quantum intuition through discovery, experimentation, and puzzles.

The goal is not for players to memorize gate names.

The goal is for players to understand:

* Superposition
* Phase
* Interference
* Entanglement
* Quantum information flow
* Uncomputation
* Phase kickback
* Oracle thinking
* Variational quantum circuits
* The intuition behind Grover and QAOA

without requiring advanced mathematics.

---

# Design Principles

## Principle 1 – Ideas Over Gates

Every level must teach a quantum idea.

Bad objective:

"Use a Hadamard gate."

Good objective:

"Discover that a qubit can exist in multiple possibilities simultaneously."

---

## Principle 2 – Discovery Before Explanation

Players should experience a concept before reading about it.

A puzzle should create curiosity.

The explanation should satisfy that curiosity.

---

## Principle 3 – No Arbitrary State Transformations

Levels should not exist solely to transform one state into another.

Each level must answer:

"What quantum intuition does this level build?"

If no answer exists, the level should be redesigned or removed.

---

## Principle 4 – Concepts Are Unavoidable

The intended concept must be required to solve the puzzle.

Players should not be able to bypass a Toffoli lesson using a simpler gate sequence.

---

## Principle 5 – Build Toward Algorithms

Every chapter should contribute to understanding real quantum algorithms.

By the end of the game, players should understand why Grover and QAOA work at an intuitive level.

---

# Chapter 1 – Classical Logic Breaks

## Learning Goal

Introduce qubits and reversible computation.

## Key Concepts

* X Gate
* Y Gate
* Z Gate
* Reversibility
* Self-inverse operations

## Player Realization

"Quantum circuits are reversible."

## Example Levels

* Bit Flip
* Phase Flip
* Bit & Phase Flip
* Phase Sandwich

---

# Chapter 2 – Superposition

## Learning Goal

Introduce the first uniquely quantum behaviour.

## Key Concepts

* Hadamard Gate
* |+⟩ State
* |−⟩ State
* Basis Change

## Player Realization

"A qubit is not restricted to 0 or 1."

## Example Levels

* Superposition
* Minus State
* Product State

---

# Chapter 3 – Phase

## Learning Goal

Show that phase is meaningful information.

## Key Concepts

* Relative Phase
* Global Phase
* S Gate
* T Gate

## Player Realization

"Two states can look identical when measured but behave differently later."

## Example Levels

* S Gate Phase
* T Gate Phase
* Phase Construction

---

# Chapter 4 – Interference

## Learning Goal

Explain why phase matters.

## Key Concepts

* Constructive Interference
* Destructive Interference
* Basis Transformations
* HZH = X
* HXH = Z

## Player Realization

"Quantum computation works because amplitudes interfere."

## New Levels

* Interference I
* Interference II
* Phase Becomes Bit
* Basis Magic

---

# Chapter 5 – Entanglement

## Learning Goal

Introduce correlated quantum systems.

## Key Concepts

* Bell States
* Bell Decoding
* Correlation

## Player Realization

"Two qubits can become one quantum system."

## Example Levels

* Bell Φ⁺
* Bell Ψ⁺
* Bell Φ⁻
* Bell Ψ⁻
* Bell Decode

---

# Chapter 6 – Multi-Qubit Information Flow

## Learning Goal

Understand how information moves through circuits.

## Key Concepts

* CNOT
* Toffoli
* SWAP
* Fan-Out
* Long-Range CNOT
* Uncomputation

## Player Realization

"Quantum circuits manipulate information rather than simply changing states."

## Example Levels

* Toffoli AND
* SWAP
* Long-Range CNOT
* Fan-Out
* Uncompute

---

# Chapter 7 – GHZ States

## Learning Goal

Extend entanglement beyond two qubits.

## Key Concepts

* GHZ States
* Multi-Party Entanglement
* GHZ Uncomputation

## Player Realization

"Entanglement is not limited to pairs."

## New Levels

* Create GHZ
* Decode GHZ
* GHZ Phase

---

# Chapter 8 – Phase Kickback

## Learning Goal

Reveal the hidden mechanism behind many quantum algorithms.

## Key Concepts

* Controlled Phase
* Phase Kickback
* Phase as Information

## Player Realization

"Information can be encoded in phase."

## New Levels

* Kickback I
* Kickback II
* Controlled Phase

---

# Chapter 9 – Oracles & Search

## Learning Goal

Build intuition for Grover-style algorithms.

## Key Concepts

* Marking States
* Phase Marking
* Oracle Construction

## Player Realization

"A quantum computer can recognize a solution without measuring it."

## New Levels

* Mark One State
* Hidden Target
* Oracle Builder

---

# Chapter 10 – Variational Quantum Computing

## Learning Goal

Introduce modern quantum optimization.

## Key Concepts

* Rx
* Ry
* Rz
* Parameterized Circuits
* Optimization

## Player Realization

"Quantum circuits can be tuned rather than programmed."

## Example Levels

* Rotation Introduction
* Bloch Explorer
* Variational State Builder

---

# Chapter 11 – Mini Algorithms

## Learning Goal

Connect all previous concepts.

## Concepts

* Grover Intuition
* QAOA Intuition
* Variational Optimization

## Player Realization

"I understand why quantum algorithms work."

## Finale Levels

### Mini Grover

Mark a state and amplify its probability.

### Mini QAOA

Tune a small variational circuit to maximize a target probability.

### Quantum Engineer

Combine multiple concepts to solve a final challenge.

---

# Success Criteria

A player who completes Qubit Quest 2.0 should be able to answer:

1. What is superposition?
2. Why does phase matter?
3. What is interference?
4. What is entanglement?
5. What is uncomputation?
6. What is phase kickback?
7. Why can Grover search faster?
8. What is a variational circuit?
9. What is QAOA trying to do?

If they can answer these questions, Qubit Quest has achieved its educational mission.

## The Discovery Arc

> Every chapter starts with a misconception and ends with a realization.

---

# Chapter 1 — Classical Logic Breaks

### Player Believes

> A qubit is just a bit.

### Mystery

Why do we need quantum gates if classical gates already exist?

### Discoveries

* X flips a state.
* Applying X twice returns to the start.
* Operations are reversible.
* Quantum circuits remember where they came from.

### Learning Gap Filled

Most people assume computation destroys information.

### Chapter Realization

> Quantum computation is reversible.

### Emotional Moment

> "This isn't so different from classical computing... yet."

---

# Chapter 2 — Superposition

### Player Believes

> A qubit is either 0 or 1.

### Mystery

What does Hadamard actually do?

### Discoveries

* H creates |+⟩.
* H applied twice returns to the original state.
* One qubit can represent multiple possibilities.

### Learning Gap Filled

Understanding that quantum states are not classical states.

### Chapter Realization

> A qubit can exist in multiple possibilities simultaneously.

### Emotional Moment

> "Okay... this is different."

---

# Chapter 3 — Phase

### Player Believes

> If probabilities don't change, nothing changed.

### Mystery

Why do S and T gates matter?

### Discoveries

* Some gates change phase only.
* Measurement probabilities remain identical.
* Hidden information exists.

### Learning Gap Filled

Understanding relative phase.

### Chapter Realization

> Two states can look identical when measured but behave differently later.

### Emotional Moment

> "Something changed, but I can't see it."

---

# Chapter 4 — Interference

### Player Believes

> Phase is weird but useless.

### Mystery

Can hidden phase become visible?

### Discoveries

* HZH = X
* HXH = Z
* Amplitudes add and cancel.
* Probability comes from interference.

### Learning Gap Filled

Understanding why quantum algorithms work.

### Chapter Realization

> Quantum computation works because amplitudes interfere.

### Emotional Moment

> "Oh! That's why phase matters."

This is the first major revelation of the game.

---

# Chapter 5 — Entanglement

### Player Believes

> Multi-qubit systems are just bigger single-qubit systems.

### Mystery

Why are Bell states special?

### Discoveries

* Bell states cannot be separated.
* Measuring one qubit affects the joint system.
* Correlations emerge.

### Learning Gap Filled

Understanding entanglement.

### Chapter Realization

> Two qubits can become one quantum system.

### Emotional Moment

> "These qubits are linked in a way classical bits never are."

---

# Chapter 6 — Quantum Information Flow

### Player Believes

> Entanglement is the whole story.

### Mystery

How does information move through a quantum circuit?

### Discoveries

* CNOT copies classical information.
* Toffoli performs reversible logic.
* SWAP moves information.
* Uncomputation removes temporary information.

### Learning Gap Filled

Understanding circuit design.

### Chapter Realization

> Quantum circuits are information-processing machines.

### Emotional Moment

> "Now I'm building circuits, not just states."

---

# Chapter 7 — GHZ States

### Player Believes

> Entanglement only happens between pairs.

### Mystery

Can more than two qubits be entangled?

### Discoveries

* Create GHZ states.
* Decode GHZ states.
* Observe collective behavior.

### Learning Gap Filled

Understanding large-scale entanglement.

### Chapter Realization

> Entanglement can involve many qubits simultaneously.

### Emotional Moment

> "Bell states were just the beginning."

---

# Chapter 8 — Phase Kickback

### Player Believes

> Information only exists in measured bits.

### Mystery

Can information be stored somewhere else?

### Discoveries

* Controlled operations affect phase.
* Information appears without changing visible bits.
* Phase can carry meaning.

### Learning Gap Filled

Understanding phase kickback.

### Chapter Realization

> Information can be encoded in phase.

### Emotional Moment

> "Wait... the control qubit changed something without touching it."

This is the second major revelation.

---

# Chapter 9 — Oracles & Search

### Player Believes

> To find a solution you must check it.

### Mystery

Can we recognize a solution without measuring it?

### Discoveries

* Mark states using phase.
* Build simple oracles.
* Distinguish marked states.

### Learning Gap Filled

Understanding Grover intuition.

### Chapter Realization

> A quantum computer can recognize solutions before measuring them.

### Emotional Moment

> "We're searching without checking."

---

# Chapter 10 — Variational Quantum Computing

### Player Believes

> Quantum circuits are fixed programs.

### Mystery

Can a quantum circuit be tuned?

### Discoveries

* Rx, Ry, Rz create continuous changes.
* Small angle changes affect probabilities.
* Better parameters produce better outcomes.

### Learning Gap Filled

Understanding variational circuits.

### Chapter Realization

> Quantum circuits can be optimized rather than programmed.

### Emotional Moment

> "I'm steering the quantum state."

---

# Chapter 11 — Mini Algorithms

### Player Believes

> These are isolated concepts.

### Mystery

How do real algorithms use these ideas?

### Discoveries

* Grover uses interference and phase marking.
* QAOA uses parameterized circuits and optimization.
* Multiple concepts work together.

### Learning Gap Filled

Connecting theory to practice.

### Final Realization

> Superposition, phase, interference, entanglement and optimization are all pieces of the same puzzle.

### Final Emotional Moment

> "I finally understand why quantum computing is interesting."

---

Perfect. Now we move from:

```text
Vision
↓
Discovery Arc
```

to:

```text
Discovery Arc
↓
Level Plan
```

This is where Qubit Quest 2.0 starts becoming a real game design document.

---

# Qubit Quest 2.0 – Level Plan v0.1

## Chapter 1 – Classical Logic Breaks

### Discovery

Quantum computation is reversible.

| Level | Title              | Learning Objective                 |
| ----- | ------------------ | ---------------------------------- |
| 1     | Bit Flip           | X flips a qubit                    |
| 2     | Phase Flip         | Z changes sign                     |
| 3     | Bit & Phase Flip   | Combine operations                 |
| 4     | i-State            | Y introduces phase and bit changes |
| 5     | Phase Sandwich     | Gates can transform each other     |
| 6     | Undo the Change    | Reversibility                      |
| 7     | Self-Inverse       | XX = I                             |
| 8     | Reversible Circuit | Multiple operations can be undone  |

### Chapter Reveal

> Quantum computers do not erase information the way classical logic often does.

---

# Chapter 2 – Superposition

### Discovery

A qubit can represent multiple possibilities.

| Level | Title                | Learning Objective              |    |
| ----- | -------------------- | ------------------------------- | -- |
| 9     | First Superposition  | H creates                       | +⟩ |
| 10    | Back Again           | HH = I                          |    |
| 11    | Minus State          | Create                          | −⟩ |
| 12    | Product State        | Independent qubits              |    |
| 13    | Many Possibilities   | Multi-qubit superposition       |    |
| 14    | Basis Explorer       | Computational vs Hadamard basis |    |
| 15    | Superposition Puzzle | Apply concepts                  |    |

### Chapter Reveal

> A qubit is not limited to 0 or 1.

---

# Chapter 3 – Phase

### Discovery

Phase is invisible but meaningful.

| Level | Title              | Learning Objective         |
| ----- | ------------------ | -------------------------- |
| 16    | Hidden Change      | Phase affects state        |
| 17    | S Gate             | Quarter turn               |
| 18    | T Gate             | Eighth turn                |
| 19    | Relative Phase     | Compare states             |
| 20    | Global Phase       | What does not matter       |
| 21    | Phase Construction | Build a target phase       |
| 22    | Phase Detective    | Identify phase differences |

### Chapter Reveal

> States can look identical when measured but behave differently later.

---

# Chapter 4 – Interference

### Discovery

Quantum computation works through interference.

| Level | Title                           | Learning Objective          |
| ----- | ------------------------------- | --------------------------- |
| 23    | Phase Is Hidden                 | Z changes phase             |
| 24    | Phase Becomes Visible           | Basis changes reveal phase  |
| 25    | HZH = X                         | Phase flip becomes bit flip |
| 26    | HXH = Z                         | Bit flip becomes phase flip |
| 27    | Constructive Interference       | Amplitudes add              |
| 28    | Destructive Interference        | Amplitudes cancel           |
| 29    | Make 0 Impossible               | Guided interference puzzle  |
| 30    | The Engine of Quantum Computing | Interference summary        |

### Chapter Reveal

> Interference is why quantum algorithms can outperform classical ones.

---

# Chapter 5 – Entanglement

### Discovery

Two qubits can become one quantum system.

| Level | Title                | Learning Objective   |
| ----- | -------------------- | -------------------- |
| 31    | First Bell State     | Create Φ⁺            |
| 32    | Bell Variations      | Create Ψ⁺            |
| 33    | Negative Bell States | Φ⁻ and Ψ⁻            |
| 34    | Bell Detective       | Identify Bell states |
| 35    | Bell Decoder         | Reverse entanglement |
| 36    | Entanglement Puzzle  | Mixed challenge      |

### Chapter Reveal

> Entanglement creates correlations impossible in classical systems.

---

# Chapter 6 – Quantum Information Flow

### Discovery

Quantum circuits process information.

| Level | Title           | Learning Objective               |
| ----- | --------------- | -------------------------------- |
| 37    | First CNOT      | Controlled operations            |
| 38    | Long Range CNOT | Distance doesn't matter          |
| 39    | Fan-Out         | One control, many targets        |
| 40    | Toffoli Logic   | Controlled-controlled operations |
| 41    | Reversible AND  | Toffoli as logic                 |
| 42    | SWAP            | Move information                 |
| 43    | Uncompute       | Clean temporary information      |

### Chapter Reveal

> Good quantum circuits carefully move and erase information.

---

# Chapter 7 – GHZ States

### Discovery

Entanglement scales.

| Level | Title         | Learning Objective          |
| ----- | ------------- | --------------------------- |
| 44    | Create GHZ    | Three-qubit entanglement    |
| 45    | Decode GHZ    | Reverse GHZ                 |
| 46    | GHZ Phase     | Manipulate entangled phases |
| 47    | GHZ Challenge | Apply concepts              |

### Chapter Reveal

> Entanglement is not limited to pairs.

---

# Chapter 8 – Phase Kickback

### Discovery

Information can be stored in phase.

| Level | Title              | Learning Objective       |
| ----- | ------------------ | ------------------------ |
| 48    | Hidden Information | Controlled phase effects |
| 49    | Kickback I         | Observe phase transfer   |
| 50    | Kickback II        | Use phase information    |
| 51    | Controlled Phase   | CZ intuition             |
| 52    | Phase Messenger    | Solve a kickback puzzle  |

### Chapter Reveal

> Quantum algorithms often manipulate phase instead of bits.

---

# Chapter 9 – Oracles & Search

### Discovery

Solutions can be marked before measurement.

| Level | Title              | Learning Objective     |
| ----- | ------------------ | ---------------------- |
| 53    | Mark One State     | Oracle intuition       |
| 54    | Hidden Target      | Identify marked states |
| 55    | Oracle Builder     | Build a simple oracle  |
| 56    | Amplify the Winner | Search intuition       |

### Chapter Reveal

> Grover's algorithm is powered by phase marking and interference.

---

# Chapter 10 – Variational Quantum Computing

### Discovery

Quantum circuits can be tuned.

| Level | Title               | Learning Objective     |
| ----- | ------------------- | ---------------------- |
| 57    | First Rotation      | Rx                     |
| 58    | Ry Explorer         | Ry                     |
| 59    | Rz Explorer         | Rz                     |
| 60    | Steering the State  | Continuous control     |
| 61    | Variational Circuit | Parameter tuning       |
| 62    | Optimization Puzzle | Find better parameters |

### Chapter Reveal

> Modern quantum computing often means optimizing quantum circuits.

---

# Chapter 11 – Mini Algorithms

### Discovery

Everything connects.

| Level | Title            | Learning Objective   |
| ----- | ---------------- | -------------------- |
| 63    | Mini Grover      | Mark and amplify     |
| 64    | Mini Grover II   | Repeat amplification |
| 65    | Mini QAOA        | Tune a circuit       |
| 66    | Quantum Engineer | Mixed concepts       |
| 67    | Final Challenge  | Full synthesis       |

### Final Reveal

> Superposition, phase, interference, entanglement, phase kickback and optimization are not separate topics. They are the building blocks of quantum algorithms.

---

This is the first version where I can actually imagine the entire game from Level 1 to Level 67. The next refinement pass would be to go chapter by chapter and decide:

* Which existing levels map directly?
* Which need modification?
* Which are entirely new?

That's where the real migration plan from Qubit Quest 1.x to 2.0 begins.


## Level Mapping

Now we move from:

```text
Vision
↓
Discovery Arc
```

to:

```text
Discovery Arc
↓
Level Plan
```

This is where Qubit Quest 2.0 starts becoming a real game design document.

---

# Qubit Quest 2.0 – Level Plan v0.1

## Chapter 1 – Classical Logic Breaks

### Discovery

Quantum computation is reversible.

| Level | Title              | Learning Objective                 |
| ----- | ------------------ | ---------------------------------- |
| 1     | Bit Flip           | X flips a qubit                    |
| 2     | Phase Flip         | Z changes sign                     |
| 3     | Bit & Phase Flip   | Combine operations                 |
| 4     | i-State            | Y introduces phase and bit changes |
| 5     | Phase Sandwich     | Gates can transform each other     |
| 6     | Undo the Change    | Reversibility                      |
| 7     | Self-Inverse       | XX = I                             |
| 8     | Reversible Circuit | Multiple operations can be undone  |

### Chapter Reveal

> Quantum computers do not erase information the way classical logic often does.

---

# Chapter 2 – Superposition

### Discovery

A qubit can represent multiple possibilities.

| Level | Title                | Learning Objective              |    |
| ----- | -------------------- | ------------------------------- | -- |
| 9     | First Superposition  | H creates                       | +⟩ |
| 10    | Back Again           | HH = I                          |    |
| 11    | Minus State          | Create                          | −⟩ |
| 12    | Product State        | Independent qubits              |    |
| 13    | Many Possibilities   | Multi-qubit superposition       |    |
| 14    | Basis Explorer       | Computational vs Hadamard basis |    |
| 15    | Superposition Puzzle | Apply concepts                  |    |

### Chapter Reveal

> A qubit is not limited to 0 or 1.

---

# Chapter 3 – Phase

### Discovery

Phase is invisible but meaningful.

| Level | Title              | Learning Objective         |
| ----- | ------------------ | -------------------------- |
| 16    | Hidden Change      | Phase affects state        |
| 17    | S Gate             | Quarter turn               |
| 18    | T Gate             | Eighth turn                |
| 19    | Relative Phase     | Compare states             |
| 20    | Global Phase       | What does not matter       |
| 21    | Phase Construction | Build a target phase       |
| 22    | Phase Detective    | Identify phase differences |

### Chapter Reveal

> States can look identical when measured but behave differently later.

---

# Chapter 4 – Interference

### Discovery

Quantum computation works through interference.

| Level | Title                           | Learning Objective          |
| ----- | ------------------------------- | --------------------------- |
| 23    | Phase Is Hidden                 | Z changes phase             |
| 24    | Phase Becomes Visible           | Basis changes reveal phase  |
| 25    | HZH = X                         | Phase flip becomes bit flip |
| 26    | HXH = Z                         | Bit flip becomes phase flip |
| 27    | Constructive Interference       | Amplitudes add              |
| 28    | Destructive Interference        | Amplitudes cancel           |
| 29    | Make 0 Impossible               | Guided interference puzzle  |
| 30    | The Engine of Quantum Computing | Interference summary        |

### Chapter Reveal

> Interference is why quantum algorithms can outperform classical ones.

---

# Chapter 5 – Entanglement

### Discovery

Two qubits can become one quantum system.

| Level | Title                | Learning Objective   |
| ----- | -------------------- | -------------------- |
| 31    | First Bell State     | Create Φ⁺            |
| 32    | Bell Variations      | Create Ψ⁺            |
| 33    | Negative Bell States | Φ⁻ and Ψ⁻            |
| 34    | Bell Detective       | Identify Bell states |
| 35    | Bell Decoder         | Reverse entanglement |
| 36    | Entanglement Puzzle  | Mixed challenge      |

### Chapter Reveal

> Entanglement creates correlations impossible in classical systems.

---

# Chapter 6 – Quantum Information Flow

### Discovery

Quantum circuits process information.

| Level | Title           | Learning Objective               |
| ----- | --------------- | -------------------------------- |
| 37    | First CNOT      | Controlled operations            |
| 38    | Long Range CNOT | Distance doesn't matter          |
| 39    | Fan-Out         | One control, many targets        |
| 40    | Toffoli Logic   | Controlled-controlled operations |
| 41    | Reversible AND  | Toffoli as logic                 |
| 42    | SWAP            | Move information                 |
| 43    | Uncompute       | Clean temporary information      |

### Chapter Reveal

> Good quantum circuits carefully move and erase information.

---

# Chapter 7 – GHZ States

### Discovery

Entanglement scales.

| Level | Title         | Learning Objective          |
| ----- | ------------- | --------------------------- |
| 44    | Create GHZ    | Three-qubit entanglement    |
| 45    | Decode GHZ    | Reverse GHZ                 |
| 46    | GHZ Phase     | Manipulate entangled phases |
| 47    | GHZ Challenge | Apply concepts              |

### Chapter Reveal

> Entanglement is not limited to pairs.

---

# Chapter 8 – Phase Kickback

### Discovery

Information can be stored in phase.

| Level | Title              | Learning Objective       |
| ----- | ------------------ | ------------------------ |
| 48    | Hidden Information | Controlled phase effects |
| 49    | Kickback I         | Observe phase transfer   |
| 50    | Kickback II        | Use phase information    |
| 51    | Controlled Phase   | CZ intuition             |
| 52    | Phase Messenger    | Solve a kickback puzzle  |

### Chapter Reveal

> Quantum algorithms often manipulate phase instead of bits.

---

# Chapter 9 – Oracles & Search

### Discovery

Solutions can be marked before measurement.

| Level | Title              | Learning Objective     |
| ----- | ------------------ | ---------------------- |
| 53    | Mark One State     | Oracle intuition       |
| 54    | Hidden Target      | Identify marked states |
| 55    | Oracle Builder     | Build a simple oracle  |
| 56    | Amplify the Winner | Search intuition       |

### Chapter Reveal

> Grover's algorithm is powered by phase marking and interference.

---

# Chapter 10 – Variational Quantum Computing

### Discovery

Quantum circuits can be tuned.

| Level | Title               | Learning Objective     |
| ----- | ------------------- | ---------------------- |
| 57    | First Rotation      | Rx                     |
| 58    | Ry Explorer         | Ry                     |
| 59    | Rz Explorer         | Rz                     |
| 60    | Steering the State  | Continuous control     |
| 61    | Variational Circuit | Parameter tuning       |
| 62    | Optimization Puzzle | Find better parameters |

### Chapter Reveal

> Modern quantum computing often means optimizing quantum circuits.

---

# Chapter 11 – Mini Algorithms

### Discovery

Everything connects.

| Level | Title            | Learning Objective   |
| ----- | ---------------- | -------------------- |
| 63    | Mini Grover      | Mark and amplify     |
| 64    | Mini Grover II   | Repeat amplification |
| 65    | Mini QAOA        | Tune a circuit       |
| 66    | Quantum Engineer | Mixed concepts       |
| 67    | Final Challenge  | Full synthesis       |

### Final Reveal

> Superposition, phase, interference, entanglement, phase kickback and optimization are not separate topics. They are the building blocks of quantum algorithms.

---

