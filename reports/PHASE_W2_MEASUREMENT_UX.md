# Qubit Quest — Phase W2: Web Measurement UX

In the Web Sandbox, a measurement now behaves like a gate: you drag it from the palette, select it on the canvas, and edit or delete it through the normal footer controls. No shot execution or results were added. The executor and the schema-2 format are unchanged. Nothing was staged, committed, pushed or deployed.

## 1. Files changed and implementation summary

| File | Change |
|---|---|
| `lib/models/circuit_editing.dart` | Typed `CircuitDragData.measurement()` variant (`CircuitDragSource.measurement`, `isMeasurement`). It carries no `Gate`: reading `.gate` on a measurement drag throws `StateError`. Palette and placed gate drags are unchanged. |
| `lib/models/quantum_circuit.dart` | Adds `measurementById`, `canPlaceMeasurementAt` (the same checks `addMeasurement` applies), `updateMeasurementClassicalBit` and `maxClassicalBits = 1024`. The update keeps the ID, column, qubit and order, and is a no-op when the value is unchanged. `addMeasurement` now also rejects bits ≥ 1024 and validates through `canPlaceMeasurementAt`. |
| `lib/widgets/measurement_glyph.dart` (new) | Shared `MeasurementGlyph`: a meter symbol (arc plus needle) in a gate tile, an optional `cN` label, a selected state (the same green outline as selected gates) and a rejected state (red). |
| `lib/widgets/composer_gate_palette.dart` | New `measurementDraggable` option: a measurement tile at the end of the palette, the same size as gate tiles (52 px, 38 px dense), using `Draggable<CircuitDragData>` with feedback and dimmed-while-dragging, like gates. The old `onMeasurementTap` button is kept only for native. |
| `lib/widgets/composer_circuit_canvas.dart` | See the summary below this table. |
| `lib/screens/web_app.dart` | See the summary below this table. |
| `test/web_measurement_ux_test.dart` (new) | 8 focused tests. |
| `test/composer_circuit_canvas_test.dart` | Now expects the glyph and the `c4` label instead of the old `M\nc4` text. |
| `test/web_app_test.dart` | Stale expectations corrected (§3). |

**Canvas** (`composer_circuit_canvas.dart`):
- New host callbacks `onMeasurementDropped` and `onMeasurementSelected`. Without them, the canvas refuses measurement drags.
- A measurement drag reuses the existing drop-destination code, hover guide and scroll refresh, and draws a measurement preview at the target slot.
- With a host-owned selection, measurements are highlighted from `selectedGateId`. Taps are hit-tested by the canvas gesture detector, and the floating delete icon is gone.
- The legacy native path (canvas-local selection and delete icon) is unchanged.
- The guide's column count now includes measurement columns.

**Web host** (`web_app.dart`):
- Removed `_placingMeasurement`, the tap-to-place mode and the placement dialog from Web.
- Adds `_dropMeasurement`, `_selectMeasurement`, `_updateSelectedClassicalBit` and measurement-aware `_deleteSelectedGate`.
- Footer: a measurement summary, a classical-bit selector with an explanation, and the existing Delete button.
- Operation count, edit-rejection messages and the measured-circuit editing note.
- Restore status: "Restored N saved operation(s)."

## 2. Interaction and visual changes

- **Palette:** the `M` OutlinedButton is replaced by a meter tile matching the gate tiles. Its tooltip reads "Measure (Z basis): drag onto a qubit wire".
- **Drag and drop:**
  - Dragging over a wire shows a preview with the default destination (`c<qubit>`) in the hovered slot.
  - Valid slots (an empty column, clamped to the end of the circuit) show a normal preview. Occupied columns show a red preview.
  - Dropping on a valid slot places the measurement with destination q*n* → c*n* and selects it. Dropping on an occupied column changes nothing and shows a SnackBar plus status: "Measurement not placed: it needs an empty column. Drop it after the last gate."
- **Appearance:**
  - Placed measurements use the meter glyph with a `cN` label inside the tile, aligned and sized like gate tiles (30 px on the canvas). The wire is covered only by the tile itself, as with any gate.
  - Selected measurements get the same green outline as selected gates.
- **Selection:**
  - Tapping a measurement updates the Web host's selection. The footer shows **SELECTED MEASUREMENT** and "Measurement Z — q2 → c2", plus the note "Measurements are circuit instructions; their results will appear once circuit execution is supported."
  - "No gate selected" is never shown while a measurement is selected. Tapping empty canvas clears the selection.
- **Editing and deletion:**
  - A "Classical bit" dropdown (c0 … c(max(qubits, register width)−1)) appears with the help text "The measurement outcome (0 or 1) will be stored in this classical bit."
  - Changing it keeps the ID, column and order, saves automatically and updates the footer and status.
  - The existing **Delete** control removes the selected measurement. The Inspector returns to the live state view once no measurements remain.
- **Status:**
  - The operation count includes measurements, e.g. "3 operation(s) in circuit (1 measurement)."
  - Gate drops before a measurement show "Gates can only be added after the last measurement."
  - Rejected moves show the model's reason.
- **No silent disabling:** when a gate is selected in a measured circuit, the misleading "Drag to move" chip is hidden and replaced by "Moving and duplicating gates is paused while the circuit contains measurements."

**Native impact:** native keeps the tap-to-place button, its dialog and its canvas-local delete icon. Only the measurement visuals change, because the glyph is shared. No new native functionality was added.

## 3. Tests and results

**New: `test/web_measurement_ux_test.dart`, 8 tests, all pass on the VM and in Chrome.**

- **Model and drag data:**
  - The measurement drag data is typed (`.gate` throws).
  - `canPlaceMeasurementAt` matches `addMeasurement`, including the classical-bit bound.
  - The classical-bit update keeps the ID, column and order, notifies once, and survives an encode/decode round trip.
- **M tile:** it is a `Draggable` the same size as the H tile, and the legacy button is absent. The valid preview appears during the drag. The drop gives q2 / column 0 / c2 and the footer selects it. The status mentions results arriving later. There is no floating delete icon.
- **Rejection:** a measurement dropped on an occupied column shows the red preview, the SnackBar and the status, and leaves the circuit unchanged (gate ID preserved).
- **Selection and deletion:** clearing works; tapping a measurement selects it in the footer, with no "No gate selected" text and no canvas delete icon. Delete removes only the measurement. The Inspector switches from `UnexecutedMeasuredCircuit` back to the live state view.
- **Classical-bit edit:** changing c2 → c0 through the dropdown keeps the ID and column, updates the footer and status, saves to schema 2, and comes back identical in a fresh app session.
- **Gate drag/drop regression:**
  - H drops correctly and the status reads "1 operation(s) in circuit."
  - After adding M and then X, the status reads "3 operation(s) in circuit (1 measurement)."
  - X dropped before the barrier is rejected with an explanation.
  - A selected gate shows the paused-editing note and no move chip.

**Focused regression run: 206 tests, all pass on the VM.** Suites run:
- `composer_circuit_canvas_test`, `web_sandbox_measurement_test`
- `sandbox_lifecycle_schema2_test`, `sandbox_activation_test`, `sandbox_program_snapshot_test`, `sandbox_circuit_persistence_test`
- `web_sandbox_open_recovery_test`, `circuit_measurement_editing_test`, `circuit_program_test`
- `quantum_composer_editing_test` (native host), `quantum_workspace_layout_test`, `web_composer_layout_authority_test`
- `web_01_acceptance_test`, `web_app_test`, `web_learning_workspace_test`
- `web_measurement_ux_test`

**The four `web_app_test.dart` cases from W1:**

| Test | Finding | Resolution |
|---|---|---|
| `wide Composer prioritises the shared circuit above its tools` (122 vs ≥126 px) | Genuine layout regression from 4B.1: the `OutlinedButton` `M` was taller than the gate tiles and pushed the palette row up by 4 px. | **Fixed by W2:** the measurement tile is now the gate-tile size. Test unchanged, now passes. |
| `Web Composer canvas height follows qubit count and not circuit content` (202 vs ≥206 px) | Same cause. | **Fixed by W2.** Test unchanged, now passes. |
| `Composer restores the existing Sandbox workspace` | Stale status: 4B.1 changed the text to "Restored saved circuit." | The Web status again reports the count, "Restored N saved operation(s).", now counting gates and measurements. Test unchanged, now passes. |
| `Web Sandbox exposes failed clear and retries without losing saved data` | Stale test: its fault injection matched only the legacy `sandbox_circuit_snapshot*` keys and asserted through the legacy store, but Sandbox saves are now schema 2 (`sandbox_circuit_v2_*`). | The test now fails all `sandbox_circuit*` writes and asserts through `SandboxWorkspacePersistence(storage).load(1)`. The behaviour it checks (save-failed status, saved data kept, Retry save succeeds) is unchanged. |

**Static checks**
- `flutter analyze` on the changed files plus both other canvas hosts (`quantum_composer.dart`, `web_learning_workspace.dart`): no errors or warnings. The 7 remaining infos are pre-existing `curly_braces` lints on 4B.1 lines.
- `dart format` was applied to changed Dart files only. `git diff --check` is clean, and the new files have no trailing whitespace.

No full test suite, full analyzer, build or emulator was run.

## 4. Remaining limitations

- No shot execution or results (Phase 4B.2). The Inspector still shows the shared `UnexecutedMeasuredCircuit` text for measured circuits.
- Measurements can't be dragged to a new position. To move one, delete it and drop it again.
- Placement needs a fully empty column. Drops inside the circuit body are rejected, not snapped; in practice measurements go at the end or in columns left empty by deletions.
- Gate move and duplicate stay disabled in measured circuits (a model restriction from 4B.1). This is now explained, not lifted.
- Web has no keyboard or click-to-place alternative to dragging, now that tap-to-place is removed. Semantics labels and hints exist, but full keyboard placement is future work.
- No classical register wiring is drawn. The selector lists c0 … c(max(qubits, register width)−1).
- Drop resolution uses the drag feedback's top-left, the same convention as gate drags. Grabbing a tile far from its corner offsets the target slot, exactly as it does for gates.
- The glyph was checked by widget tests, not by eye in a running browser.
- Native keeps the legacy interaction, so Web and native measurement interaction intentionally differ.

## 5. Manual Web verification steps

1. Run `flutter run -d chrome`, go to **Composer** and open **3** qubits.
2. **Palette:** the last palette tile shows a meter symbol, is the same size as H/X, and its tooltip says "drag onto a qubit wire".
3. **Drag:** drag it over q2 to the right of the (empty) circuit. A meter preview labelled `c2` follows the slot. Drop it.
   - Check: the measurement shows with `c2`, has a green outline, and the footer reads "SELECTED MEASUREMENT — Measurement Z — q2 → c2" with the execution note.
   - Check: the status starts "Measurement added: q2 → c2".
   - Check: there is no trash icon on the canvas.
4. **Rejection:** drag H onto q0 at the first column. Then drag `M` over q1 in that same column.
   - Check: the preview turns red. Drop it: nothing is added, and a SnackBar plus status explain that an empty column is needed.
5. **Gates and barrier:** drop X onto q0 after the measurement; it's accepted and the status counts gates plus measurements. Drop X onto q1 before the measurement; it's rejected with "Gates can only be added after the last measurement."
6. **Selection:** click empty canvas and check the footer reads "NO GATE SELECTED". Click the measurement and check the footer shows it (never "No gate selected"). Click a gate and check the footer notes that moving/duplicating is paused.
7. **Edit:** select the measurement and change **Classical bit** to `c0`.
   - Check: the tile label and footer update to q2 → c0, and the help text explains the 0/1 outcome.
8. **Delete:** press **Delete**. The measurement disappears; once none remain, the Inspector shows the state vector again.
9. **Persistence:** add a measurement, set it to `c1`, reload the page and reopen 3 qubits. The measurement is in the same column with `c1`.
10. **Regression:** in a 2-qubit circuit, drag gates in, move them, duplicate and delete them with no measurements present. Behaviour should match the previous release.
