# Qubit Quest — Phase W3: Measurement Ordering and Circuit Editing

In the Web Sandbox, measurements now occupy a single qubit slot instead of a whole column. Gates can be inserted before measurements, with later operations shifting right. A conservative terminal-measurement policy is enforced per qubit. The executor and the schema-2 JSON format are unchanged. No results UI was added. Nothing was staged, committed, pushed or deployed.

## 1. Findings: execution and editing semantics before W3

**Executor (`circuit_executor.dart`) — unchanged.**
- `runShot` executes `CircuitProgram.operations` strictly in list order. A `MeasureZOperation` projects and renormalizes the state and writes its classical bit. Later unitaries act on the collapsed state.
- **Mid-circuit unitaries after a measurement are supported and mathematically correct.** Nothing in the executor needs a measurement to have its column to itself.
- Operations on disjoint qubits commute, so any order within a column is equivalent.

**`CircuitProgram` validation.**
- Required: nondecreasing columns, disjoint operands within a column, and *"a measurement occupies its column exclusively, providing a conservative global barrier"*.
- That rule was an editor-side simplification, not an execution need.

**Composer model (`QuantumCircuit`).**
- Gates live in the `placedGates` grid, and every gate edit rewrites grid columns: vertical-line insertion, gravity compaction (`shiftLeft` → `_compactDetachedRows`), conflict shifting (`_shiftConflictingLogicalGatesRight`), and the move and duplicate planners.
- Measurements lived *outside* the grid, in `_measurements`, with absolute columns that none of those algorithms knew about.
- 4B.1 kept them consistent with blunt guards:
  - inserts at or before the last measurement column were `invalid`;
  - move and duplicate were disabled entirely;
  - compaction could not cross a measurement column.
- **Consequences:**
  - Every measurement was a full-column barrier.
  - Nothing could be inserted before it.
  - Any gate, *including one on the measured qubit*, could be added after it.
- The executor would run such post-measurement gates faithfully, and column order did reflect execution order. But the editor could not keep that order through general shifting, which is why editing had to be frozen.

**Latent determinism bug, fixed.** `CircuitProgram.fromCircuit` broke same-column ties by gate index, and every measurement got −1. With measurements sharing columns, Dart's unstable `List.sort` could serialize them in either order. Same-column operations are now ordered by their topmost occupied qubit, which is a total order because their footprints are disjoint.

**Blocker assessment.** The representation *can* support the requested rules safely if measurements become grid cells, so no stop was needed. That is the implemented solution (§2).

## 2. Editing rules implemented

**Representation**
- A measurement is a single-qubit grid cell: new `SelectedGateType.measureZ`, with `PlacedQuantumGate.classicalBit` holding the destination.
- It is never a unitary: it is excluded from `logicalGates`/`logicalGateById`, from the painter, from the matrix engine (still guarded by `NonUnitaryProgram`), and from the unitary-gate check in `CircuitProgram`.
- Because it lives in the grid, it takes part in the existing insertion shifting, conflict shifting, gravity compaction and move planning. None of these ever reorder cells within one qubit row.

**Rules**
1. **Per-qubit occupancy.** A measurement occupies only its own qubit slot, so operations on other qubits may share its column.
2. **Insertion.** Measurements and single-qubit gates use the same `_insertSingleCell`: fill an empty slot, or insert a vertical line that shifts all later operations right, keeping their relative order. Then the usual compaction runs.
3. **Default destination** is `c[qubit]`.
4. **Terminal measurement per qubit.** After any edit, no operand of an operation (gate target or control, or another measurement) may sit on a measured qubit at a later column than its measurement.
   - Link cells of multi-qubit gates are *not* operands, so a CNOT q0→q2 may cross a measured q1.
   - This covers multi-qubit gates on every qubit they act on, and forbids re-measuring a qubit.
5. **Classical destinations.** Each classical bit can be written by one measurement. New edits and destination changes may not create a shared bit. The selector shows used bits as disabled ("c1 (used by q1)").
6. **Enforcement: "no new ordering violations".**
   - For measured circuits, every structural edit runs in a transaction: insert single/double/triple, remove gate, insert/move/remove measurement, change destination. Move and duplicate plans run the same check before they are offered.
   - The check compares ordering facts before and after the edit. If the edit adds a post-measurement operation, or a new shared or reordered classical bit, the grid and ID allocator are restored exactly (cell identities included), and the outcome is `invalid` with a reason.
   - Notifications are deferred during the transaction, so listeners and autosave never see a rejected attempt.
   - Unmeasured circuits skip the guard entirely, so existing gate behaviour is unchanged.
7. **Measurement movement.**
   - `planMeasurementMove` / `moveMeasurementWithOutcome` reuse the shared logical move planner. Moves are horizontal on the measurement's own qubit, and the ID and destination are preserved.
   - With the existing gravity compaction, a measurement settles just after the last operation on its qubit, like a gate at the end of its row. So a horizontal move takes effect where a multi-qubit link crosses its wire, resolves to "same" otherwise, and is rejected if it would precede an operation on its own qubit.
8. **Gate move and duplicate are re-enabled in measured circuits**, subject to rule 6. The 4B.1 blanket guards (`_lastBarrier`, `hasMeasurements` rejections in insert/move/duplicate/commit, the compaction barrier and the `insertGateAt` throw) are replaced by this precise invariant. They were not just deleted.
9. **Legacy circuits.**
   - Saved programs containing post-measurement operations restore exactly and are never rewritten on load (encode round-trip verified).
   - Edits may keep existing violations but cannot add new ones. Deleting the offending operation is allowed.
   - The Web footer explains this when `hasPostMeasurementOperations` is true.
10. **Raw `addMeasurement`** remains as a low-level exact placement into an empty cell, for tests and constructed programs. Composer hosts use `insertMeasurementWithOutcome`. Native tap-to-place was switched to it, so native cannot bypass the rules; native has no new UI.
11. **`CircuitProgram` validation** no longer requires an exclusive measurement column. It still requires disjoint operands per column and nondecreasing columns. The schema-2 JSON format is unchanged.

**Web UX**
- **Measurement drags** (new from the palette, or an existing one via a pointer-anchored handle) preview the **exact** proposed grid from a dry run or move plan. Shifted gates and measurements are drawn where the commit will put them.
- **Gate drags in measured circuits** get the same exact dry-run preview for single-qubit gates.
- **Invalid destinations** show a red slot (plus a red measurement ghost for measurement drags). Dropping there changes nothing and shows status plus SnackBar: "Not changed: A measured qubit cannot receive further operations. Place gates before the measurement on that qubit."
- **Messages:** the obsolete "Gates can only be added after the last measurement." and "Moving and duplicating gates is paused…" are removed. The "Drag to move" and "Duplicate" controls are back for gates in measured circuits. Rejections show the model's reason.
- **Kept:** the W2 meter icon, draggable palette tile, selection, footer summary, destination selector (now marking used bits) and Delete.
- **No new modal dialogs.** The existing control and angle dialogs for controlled and rotation gates are unchanged.

## 3. Files changed

| File | Change |
|---|---|
| `lib/models/selected_gate_type.dart` | `measureZ` cell type (label `M`). |
| `lib/models/placed_quantum_gate.dart` | `classicalBit` field (in `==`/`hashCode`) and `isMeasurement`. |
| `lib/models/logical_gate_footprint.dart` | `isMeasurement`. Measurements have valid single-cell topology and can move horizontally. |
| `lib/models/quantum_circuit.dart` | See the summary below this table. |
| `lib/models/circuit_program.dart` | Exclusive-column rule removed. `measureZ` rejected as a unitary. Deterministic same-column ordering. |
| `lib/models/circuit_editing.dart` | `CircuitDragData.measurement({sourceId})` and `isMeasurementMove`. |
| `lib/widgets/quantum_circuit_painter.dart` | Skips measurement cells; the canvas draws them. |
| `lib/widgets/composer_circuit_canvas.dart` | See the summary below this table. |
| `lib/screens/web_app.dart` | See the summary below this table. |
| `test/web_measurement_ordering_test.dart` (new) | 11 W3 tests. |
| `test/circuit_measurement_editing_test.dart` | 5 tests updated from barrier semantics to W3 rules. |
| `test/sandbox_lifecycle_schema2_test.dart` | 2 tests updated to edit within the terminal policy. |
| `test/web_measurement_ux_test.dart` | W2 tests updated: the old `canPlaceMeasurementAt` check became a preview test; column-occupancy rejection became terminal rejection; the measured-circuit editing note was removed. |

**`quantum_circuit.dart`:**
- Grid-backed measurements: `measurements`, `measurementsInRows`, `measurementById`, `hasMeasurements`, `classicalBitCount`.
- Ordering facts and transactions with deferred notification.
- `insertMeasurementWithOutcome`, `previewMeasurementInsertion`, `previewSingleGateInsertion`, `planMeasurementMove`/`moveMeasurementWithOutcome`, `updateMeasurementClassicalBitWithOutcome`, `removeMeasurementWithOutcome`, `hasPostMeasurementOperations`.
- Guarded insert and remove; ordering checks in the move and duplicate planners.
- Restoration places measurement cells in the grid.
- The 4B.1 barrier guards were removed; `_lastBarrier` and `_measurements` are gone.

**`composer_circuit_canvas.dart`:**
- Exact dry-run previews and rejection state.
- Red rejected slot in the guide painter.
- Host measurement layer drawn from the current or preview grid, plus transparent move handles.
- New `onMeasurementMoved` and `onDropRejected` callbacks.
- The legacy native path keeps its own overlays, and its placement now uses `insertMeasurementWithOutcome`.

**`web_app.dart`:**
- Uses the outcome APIs for insert, move, destination change and delete.
- `_rejectEdit` shows status plus SnackBar.
- Used-bit marking in the selector and the legacy-circuit note.
- Obsolete barrier messages and the paused-editing note removed.

## 4. Tests executed and results

| Run | Result |
|---|---|
| `test/web_measurement_ordering_test.dart` (new, 11 tests) | All pass on the VM and in Chrome. |
| Focused regression set: 18 measurement, persistence, executor, program, canvas, native Composer, Web layout, Web app and learning-workspace suites | **239 / 239 pass.** |
| Every test file exercising gate insert/move/duplicate/remove, `CircuitGeometry` or `QuantumCircuitPainter` (22 files, incl. `circuit_editing_test`, `composer_interaction_parity_test`, `composer_release_hardening_test`, `qubit_ordering_test`, `levels_test`) | **504 / 504 pass.** |
| `web_measurement_ux_test.dart` + `web_measurement_ordering_test.dart` in Chrome | 19 / 19 pass. |
| After the native placement change: canvas, lifecycle, native editing, W2, W3 | 89 / 89 pass. |

The new tests cover:
- **Model:**
  - gate insertion before a measurement, with shifting and preserved IDs and bits;
  - compatible column sharing, plus executor determinism;
  - CNOT relationships preserved through shifting;
  - terminal rejection of single and multi-qubit gates (control and target) and of re-measurement — with no mutation and no notification;
  - a CNOT allowed before the measurement;
  - duplicate classical bit rejected;
  - a link crossing a measured wire allowed;
  - a measurement moved across a link (ID and bit kept), and an invalid move rejected unchanged;
  - shared-column persistence round-trip;
  - a legacy post-measurement program restoring unchanged, allowing unrelated edits, rejecting new violations and allowing the offending gate to be deleted.
- **Web:**
  - a gate dropped before a measurement, with the preview showing the measurement's shifted position before commit;
  - a measurement drag-moved across a link, with a valid preview, and an invalid move showing the red preview, being rejected unchanged, and persisting correctly;
  - a legacy circuit opening unchanged with the explanatory note.

**Static checks**
- `dart format` was applied to changed files only. `git diff --check` is clean, and the new files have no trailing whitespace.
- `flutter analyze` on the changed files plus every file using `SelectedGateType` (for exhaustiveness): no errors or warnings. The 7 remaining infos are pre-existing `curly_braces` lints on 4B.1 lines.

No full test suite or full analyzer was run.

## 5. Unsupported or limited scenarios

- **No reset, conditional or classical-controlled gates.** A qubit cannot be re-measured or receive any operation after its measurement.
- **Measurements move horizontally on their own qubit only.** Moving one to another wire means deleting it and dropping it again. Because of the existing gravity compaction, a measurement's column is fixed by the last operation on its qubit, so most horizontal drags resolve to "same". Moves only matter across multi-qubit link crossings.
- **One measurement per classical bit for new edits.** Legacy circuits that share a bit stay valid. Edits that would reorder those measurements are rejected with "Each classical bit can be written by one measurement."
- **Controlled-gate palette previews** check the hovered (target) wire. A conflict on the control wire, which is chosen in the existing control dialog, is caught at commit and reported. Exact shifted previews are shown for single-qubit gates and measurements only.
- The legacy native API `removePlacedGate` (index-based) is not wrapped in the ordering transaction. Its compaction cannot create post-measurement operations; it could only reorder legacy shared-bit measurements. The Web host never uses it.
- **Forward compatibility:** schema-2 files with a measurement sharing a column are rejected by builds older than W3, whose validation required exclusive columns. The JSON format is unchanged; only validation is more permissive.
- **No execution or results UI.** The Inspector still shows the unexecuted-measurement notice.

## 6. Manual Web verification steps

1. `flutter run -d chrome`, then **Composer → 2 qubits**.
2. **Shared column:** drop **H** on q0, then drag **M** onto q1. The measurement sits in column 0 beside H, and the footer shows "Measurement Z — q1 → c1".
3. **Gate before a measurement:**
   1. Drag **M** onto q0 so it lands right after H.
   2. Drag **X** over q0 at column 0. While hovering, the preview shows X at column 0, with H and the q0 measurement shifted right.
   3. Drop it. The circuit matches the preview and the measurement keeps its `c0` label.
4. **Terminal rejection:** drag **X** over q0 *after* its measurement. The slot turns red. Drop it: nothing changes, and status plus SnackBar say a measured qubit cannot receive further operations. Repeat with a CNOT whose control or target is q0 (choose the control in the dialog); it is rejected with the same reason.
5. **Move across a link:**
   1. Open **3 qubits** and add a CNOT q0→q2 (q1 shows the link).
   2. Drop **M** on q1 after the link.
   3. Drag that measurement left of the link. The preview shows it moving; after the drop it keeps its destination.
   4. Drag a q2 measurement left of the CNOT. It shows red and is rejected.
6. **Gate editing in measured circuits:** select a gate. **Drag to move** and **Duplicate** are available. Moving it after a measurement on its own qubit is rejected with a reason.
7. **Destination:** select a measurement. In **Classical bit**, bits used by other measurements show "(used by qN)" and can't be chosen. Pick a free bit, and the tile label updates.
8. **Delete:** delete a measurement. Later operations compact left, and with no measurements left the Inspector shows the state view again.
9. **Persistence:** reload the page and reopen the same qubit count. Columns, measurement IDs (positions) and destinations match.
10. **Legacy circuit (optional):** load a schema-2 record saved by W2 that has a gate after a measurement on the same qubit. It opens unchanged, with the footer note explaining that edits adding more post-measurement operations are rejected.
