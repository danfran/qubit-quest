# Qubit Quest v2.6 — Phase 4B.1 Recovery Review

Scope: the current uncommitted Phase 4B.1 work (measurement placement/rendering) plus the schema‑2 Sandbox lifecycle it depends on. I worked from the code only: no tests, builds, analyzer or emulator were run, and no production or test files were changed.

---

## 1. Root-cause findings

### F1 — Web: the 1–5 qubit buttons fail silently (confirmed defect, regression)

**Path:** `web_app.dart` `_buildQubitChooser` → `onPressed: () => _openSandbox(qubits)` → `_openSandbox` → `loadSandboxWithRecovery(context, widget.persistence.programs, qubitCount)`.

`SandboxPersistenceStore.programs` (`sandbox_circuit_persistence.dart`) calls `SandboxWorkspacePersistence.forStorage(storage)`. That constructs `SandboxWorkspacePersistence`, which has this field initializer (`sandbox_workspace_persistence.dart`):

```dart
final String _session =
    '${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
```

- On the Dart VM (native app and `flutter test`), ints are 64-bit, so `1 << 32` is 4294967296. That is a legal `nextInt` maximum, so the code works.
- On JavaScript-compiled Web (dart2js and DDC), shifts follow 32-bit semantics, so `1 << 32` evaluates to **0**. `Random.secure().nextInt(0)` then throws `RangeError`.
- The throw happens while the arguments to `loadSandboxWithRecovery` are evaluated. That is inside `_openSandbox`'s `try/finally`, which has no `catch`. The returned `Future` errors, the `finally` resets `_opening`, and the error goes only to the browser console. No state changes, no dialog appears and `_status` is not updated, so **every click appears to do nothing**.
- `Expando` caches only after a successful construction, so the failure repeats on every click.
- The pre-4B.1 code (`widget.persistence.loadSnapshot`) never touched `programs`. That is why this is a regression and not a pre-existing problem.
- The VM test suites (`web_sandbox_measurement_test.dart`, `sandbox_lifecycle_schema2_test.dart`) cannot catch it.

**Classification:** an interaction-level symptom of a persistence-layer defect. It is not a widget state or lifecycle problem: `_opening`, `mounted`, `widget.example` and `isActive` all behave correctly.

**Secondary defect:** `_openSandbox` has no `catch`. Any exception that `loadSandboxWithRecovery` does not handle (for example from `restoreCircuit()` or `runSimulation()` after loading) is equally invisible.

The same `programs` getter backs Web `_saves` and the native `_sandboxSaves`/`home_page.dart` load. Native is unaffected. Any Web route that reaches `home_page.dart` would be affected (see §6).

### F2 — Native: `M` can't be dragged (by design in 4B.1, inconsistent with conventions)

`composer_gate_palette.dart` builds normal gates with `_draggableGate` → `Draggable<CircuitDragData>(data: CircuitDragData.palette(gate))`. `M` is a plain `OutlinedButton(onPressed: widget.onMeasurementTap)` that sits outside that path. It was never given drag data because:

- `CircuitDragData` (`circuit_editing.dart`) carries a `Gate`. Measurement isn't a `Gate`/`SelectedGateType` (it's `MeasureZOperation` in `circuit_program.dart`).
- The canvas drop pipeline (`_onDragEnter`, `_dropIntent`, `_dragPreview`, the host `_handleDrop`) is written entirely in terms of gates.

So 4B.1 added a separate modal path instead: palette tap toggles `_placingMeasurement` (`quantum_composer.dart` `_buildGatePalette`, `web_app.dart` `gatesBuilder`). The canvas then intercepts `onTapDown` in `_handleTap` and calls `_placeMeasurement` (`composer_circuit_canvas.dart`).

This also contradicts the native convention. Palette tap means "reset mode" (`onGateTap: (_) => _setInteractionMode(SelectedGateType.none)`) and the instruction text says "Drag a gate onto the circuit." Tap-to-place exists for no other palette item.

### F3 — After placement there's little to see, and what changes looks like breakage (mostly UX, partly expected)

What is actually rendered or changed after a successful placement:

| Surface | Result | Location |
|---|---|---|
| Canvas | A gate-sized purple overlay reading `M\nc<k>`, not painted by `QuantumCircuitPainter`. There is no classical wire or register and no meter glyph. It turns deep purple when selected. | `_measurementOverlays` |
| Canvas delete | `IconButton` at `Positioned(right: 8, top: 0)` inside the **scroll content** Stack. On wide or scrolled circuits it can be off-screen. | `_measurementOverlays` |
| Selection | Lives in the canvas (`_selectedMeasurement`) and is invisible to the hosts. Web's selected-gate summary, Delete action and status don't reflect it. `widget.onGateTap(null)` sets Web status to "Canvas selection cleared." right after placement. | `_placeMeasurement`, `web_app.dart` canvas `onGateTap` |
| Inspector | The state vector, target, Bloch and the Web **Measure** sampling tab are *removed* and replaced by `UnexecutedMeasuredCircuit` text. | `web_app.dart` `_buildStateViews`, `measureViewBuilder`, `allowBloch`; `quantum_composer.dart` state-panel builder |
| Native Run/simulate | Returns silently (`if (_circuit.hasMeasurements) return;`). | `quantum_composer.dart` simulate handler |
| Editing | Every move and duplicate of existing gates is rejected (`planLogicalGateMove`, `commitLogicalGateMovePlan`, `canDuplicateLogicalGate`). Inserts at or before the last measurement column are `invalid`. | `quantum_circuit.dart` |
| Status (Web) | Operation count uses `logicalGates.length`, which excludes measurements. | `_commit` |

The visible net effect of placing `M` is that features disappear and existing gates freeze. Nothing explains why. The only positive signal is a small overlay.

**Classical destination dialog** (`_placeMeasurement`):

- It shows a bare `DropdownButton` of `c0…c(n-1)` with title "Measure q*k* in Z basis". It doesn't explain what a classical bit is, and no classical register is drawn anywhere to connect the choice to.
- It appears **before** the column is validated. If the tapped column is occupied (`addMeasurement` requires the whole column to be empty), the user picks a bit, confirms, and only then gets "choose an empty circuit column." Tapping on or between existing gates almost always hits an occupied column.
- `qubitForPoint` uses `hitTolerance`. A tap between wires silently does nothing while placement mode stays armed.
- The palette `M` button has no armed or pressed state. `_placingMeasurement` is not passed to the palette, and no instruction or banner appears. The mode is never cleared by changing qubits, `_closeCircuit`, dragging a gate or the native mode reset.
- It is opened from `onTapDown`, mid-gesture, which can conflict with horizontal scrolling.

---

## 2. Confirmed defects vs UX problems vs expected limitations

**Confirmed code defects**

1. **D1** (F1): `Random.secure().nextInt(1 << 32)` throws on JS Web, so the Web Sandbox can't open. *Blocker.*
2. **D2**: Web `_openSandbox` has no `catch`, so failures are silent.
3. **D3**: Native simulate/Run is a silent no-op when the circuit has measurements.
4. **D4**: The classical-bit dialog appears before the column is validated. An occupied column is rejected only after the user confirms.
5. **D5**: Placement mode has no visible armed state and is never reset by qubit change, close or other interactions.
6. **D6**: Measurement selection is canvas-local and diverges from host selection. After placement, Web status reports "Canvas selection cleared."
7. **D7**: The delete affordance is positioned in content coordinates, so it can be off-screen.
8. **D8** (minor): the guide painter's `maxPosition` and the Web operation count ignore measurement columns.

**UX problems (not bugs)**

- `M` is tap-to-place while every gate is drag-to-place (F2).
- There is no classical register rendering and no meter glyph, so `c<k>` has no visual meaning.
- Placing `M` hides inspector features with only a dense paragraph of explanation, and gives no route back ("remove measurements to see the state").
- The Web **Measure** tab (sampling) and the `M` operation share a name but are unrelated features.
- `M` is an `OutlinedButton`, not a `QubitQuestGateTile`: different size, no density handling, no padding.

**Expected limitations of the unfinished execution UI (leave for later phases, but communicate them)**

- There is no execution or results view for measured circuits. `circuit_executor.dart` exists but isn't wired in.
- Move and duplicate are disabled in measured circuits, and nothing can be inserted before the last barrier.
- No unitary or matrix view (already reported via a SnackBar on native).

**Regression check**

- Web Sandbox open: **regressed** (D1).
- Native gate drag, drop and delete in circuits *without* measurements: no regression found in the diffs. The new guards are all conditional on `hasMeasurements`.
- `isCircuitEmpty`/Clear: correct. `maxCircuitDepth` includes the barrier, and Clear clears `_measurements`.
- Notebook-example Composer on Web: `_saves` is only touched when `example == null`, so it is unaffected.

---

## 3. Proposed interaction model (single model for native and Web)

Reuse the established gate convention: **drag from the palette, select on the canvas, edit or delete through the host's selection controls.**

1. **Palette:** `M` becomes a normal `QubitQuestGateTile`-styled item wrapped in the same `Draggable<CircuitDragData>`. Tapping it does what tapping any gate does (inspect/no-op), with a tooltip of "Measure (Z): drag onto a qubit wire". Remove the placement-mode toggle entirely.
2. **Drag data:** add a measurement variant to `CircuitDragData`, for example `CircuitDragData.measurement()` with a `kind` discriminator, rather than a new `SelectedGateType`. That keeps the quantum model, executor and schema 2 untouched.
3. **Drop target:** the hovered wire picks the qubit. The column resolves to the **first fully empty column at or after the hovered column** (not past `maxCircuitDepth()`), and the existing guide/preview shows a ghost `M` there. Where no column is valid, show no destination, as invalid gate moves do today. Measurement drops never shift existing operations, which preserves the `addMeasurement` contract.
4. **No dialog on placement:** the classical bit defaults to `c[qubit]`, widening `classicalBitCount` if needed. Placement is immediate, like a gate.
5. **Selection:** tapping a measurement selects it through the **host's** selection channel (a `onMeasurementTap(GateId)` callback, or `PlacedGateRef`-like handling), so:
   - Web: the selected-item summary shows "Measure Z: q1 → c1", with the existing Delete button and a "Classical bit" dropdown.
   - Native: the existing selection/inspector or delete mode works the same way, and the bit picker sits in the selected-item controls.
   - The dropdown includes a one-line explanation: "Stores the 0/1 outcome in classical bit c*k*."
6. **Rendering:** draw a meter glyph in the gate slot (painter or styled overlay) and a thin double-line classical register under the qubit wires labelled `c`, with a short vertical tick from each `M` to its bit. This gives the destination choice a visual meaning.
7. **Feedback:**
   - Status/SnackBar on placement: "Measurement added: q1 → c1. Results will appear when execution is available."
   - The inspector placeholder is shortened and offers "Remove all measurements" or tells the user to delete the `M` to restore the state view.
   - Native Run shows a SnackBar instead of returning silently.
   - Move/duplicate rejection explains: "Moving gates isn't available in measured circuits yet."

---

## 4. Minimal ordered repair plan

1. **Unblock Web (D1, D2).** Replace `nextInt(1 << 32)` with a JS-safe bound (for example `nextInt(0x7fffffff)`). Add a `catch` in `web_app.dart` `_openSandbox` that sets `_status` and shows a SnackBar. Add a test that `SandboxWorkspacePersistence`'s session ID uses no shift ≥ 32, or a Chrome-platform test if the CI supports one.
2. **Stop silent no-ops (D3).** Native simulate with measurements → SnackBar. Make the Web status/count include measurements (D8).
3. **Lift measurement selection to the hosts (D6, D7).** Replace the canvas-local `_selectedMeasurement` and the floating delete `IconButton` with a host callback. Wire it into the Web Delete button/summary and the native delete mode.
4. **Draggable `M` (F2).** Add the `CircuitDragData` measurement variant, render it as a palette tile, and route canvas drops of that variant to a host `onMeasurementDropped(qubit, column)` that calls `addMeasurement` with the resolved empty column and `classicalBit: qubit`. Remove `measurementPlacement`/`_placingMeasurement` and `_placeMeasurement`'s dialog (fixes D4, D5).
5. **Classical bit editing.** Add an update operation for `classicalBit` on an existing measurement in `QuantumCircuit`. This is a small model addition, not a redesign; alternatively remove and re-add with the same ID and column. Expose it in the selected-item controls on both platforms.
6. **Rendering and copy.** Meter glyph, classical register line, guide `maxPosition` including barriers, a shorter `UnexecutedMeasuredCircuit` text with a route back, and a tooltip and status text update.
7. **Tests.** Update `composer_circuit_canvas_test.dart` and `web_sandbox_measurement_test.dart` from tap-to-place to drag-to-place. Add tests for selection/delete via the host, default bit, rejected occupied column (no destination) and the qubit-chooser error path.

Steps 1–2 are independent and can ship first. Steps 3–4 should land together so there is never a period with two selection models.

---

## 5. Risks

- **Existing gates:**
  - The new drag-data variant touches every consumer of `CircuitDragData.gate`: `_onDragEnter`, `_dragPreview`, `_dropIntent`, and both hosts' `_handleDrop`, including the rotation-angle prompt.
  - A sentinel `Gate` must not leak into `insertSinglePlacedGateAt` or the move planners. Guard by `kind` before any gate-specific path.
  - Placed-gate drag (`_capturePlacedDragOrigin`) must ignore measurement overlays.
- **Measured-circuit restrictions:** move and duplicate stay disabled. Users with saved measured circuits will still find gates frozen. That is acceptable only if it is clearly explained.
- **Saved circuits:**
  - The schema-2 format does not change. Defaulting `classicalBit` to the qubit index and editing it later must respect `classicalBitCount` reservation (`_reservedClassicalBits`).
  - Removal deliberately doesn't compact. Keep that.
  - Fixing D1 changes only the staging-key suffix, so existing `sandbox_circuit_v2_stage_*` records remain readable.
  - Schema-2 saves no longer update the legacy v1 keys, so a downgraded build won't see new edits. This is pre-existing and outside 4B.1.
- **Web/native parity:**
  - Today the two hosts share the canvas but diverge in selection and delete (Web uses a summary and button, native uses a delete mode).
  - The host-callback approach must be implemented in both `quantum_composer.dart` and `web_app.dart` in the same change, or behaviour will drift again.
- **Campaign/Notebook:** `M` must stay hidden outside the Sandbox. The current gating (`_ownsSandboxWorkspace`, `widget.example == null`) must carry over to the new drag item.

---

## 6. Needs manual reproduction (not confirmable from code alone)

1. **D1 on a real Web build.** Click a qubit button and confirm a `RangeError` (`nextInt`) in the browser console. Also confirm which compiler is in use: dart2js/DDC fail, dart2wasm (64-bit ints) would not, so if the build is Wasm, F1 is not the cause and the console error is needed.
2. **Web routes into `home_page.dart`.** Check whether any Web layout (for example a narrow or mobile-width route) reaches `home_page.dart`'s sandbox open. If so, it fails the same way.
3. **Delete icon position.** Check whether the measurement delete icon is reachable on narrow screens and after horizontal scroll.
4. **Tap-down dialog vs scrolling.** Check whether opening the dialog from `onTapDown` interferes with horizontal canvas scrolling or triggers on scroll start, especially on touch.
5. **Native feedback after a rejected drop.** Check what native shows when a gate drop is rejected because it is before the measurement barrier.
6. **Palette `M` button layout.** Check how the `OutlinedButton` looks in the dense palette and on small phones (alignment, scroll-button state).
7. **Saved-circuit open on native.** Check whether a previously saved *measured* circuit opens on native and shows the overlay at the correct column after restore.
