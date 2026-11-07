# Qubit Quest — Phase W1: Web Sandbox Recovery

The Web Sandbox qubit selectors (1–5) now open their workspaces. Opening failures are no longer silent. Measurement UX and Phase 4B.2 were not touched. Nothing was committed, staged or pushed.

## 1. Root cause and fix

**Root cause (F1/D1, now confirmed in a browser).** `SandboxWorkspacePersistence` built its session ID with `Random.secure().nextInt(1 << 32)`.

- In JavaScript-compiled Dart, `1 << 32` evaluates to `0`, so the call becomes `nextInt(0)` and throws `RangeError: max must be in range 0 < max ≤ 2^32, was 0`.
- The throw happens when `SandboxPersistenceStore.programs` first constructs the owner. That is inside `_openSandbox`, whose `try/finally` had no `catch` (D2).
- The `Expando` cache never fills on failure, so every click failed the same way and the error appeared only in the console.
- The Dart VM uses 64-bit ints, which is why native and every VM test were unaffected.

**Fix: session ID** (`lib/models/sandbox_workspace_persistence.dart`)
- New `createSessionId()` returns `<microsecondsSinceEpoch>_<16 hex chars>`.
- The 64 random bits come from four `Random.secure().nextInt(0x10000)` chunks. Every bound is a literal far below 2^31, with no shifts, so it behaves the same on the VM and on JavaScript. There are no platform branches.
- The ID uses only `[0-9_a-f]` and stays well under the 80-character staging-ID limit.
- Storage keys, schema-2 format, staging, recovery and the per-qubit-count isolation are unchanged. Only the session part of *new* staging-key suffixes looks different, and no code parses it; `_readCandidate` checks only the `sandbox_circuit_v2_stage_q<n>_` prefix. Existing staged records remain readable.
- Two `@visibleForTesting` seams were added: `sessionChunkBound` and a `secureRandom` factory (defaults to `Random.secure`) that lets tests inject the same class of failure.

**Fix: open errors** (`lib/screens/web_app.dart`, `_openSandbox` and `_buildQubitChooser`)
- Unexpected initialization or restoration exceptions are now caught. The app then:
  - logs the error via `debugPrint`;
  - disposes any half-built circuit;
  - sets the status text and a new `_openError`, shown in the qubit chooser under key `web-composer-open-error`;
  - shows a SnackBar: "Could not open the *n*-qubit Sandbox. Saved circuits were kept. Please try again."
- It never substitutes an empty circuit.
- `_opening` is still reset in `finally` on success, cancellation and failure. The error clears at the start of the next attempt.
- Recoverable persistence errors still go through `loadSandboxWithRecovery`, so Retry, Recover previous and Cancel are unchanged. Cancel is not treated as an error.

## 2. Files changed

| File | Change |
|---|---|
| `lib/models/sandbox_workspace_persistence.dart` (untracked, Phase 2–4B work) | Web-safe `createSessionId`, test seams, `foundation` import |
| `lib/screens/web_app.dart` | `catch` in `_openSandbox`, `_openError` state, error text in the chooser |
| `test/web_sandbox_open_recovery_test.dart` (new) | 8 focused tests |
| `reports/PHASE_W1_WEB_RECOVERY.md` (new) | This report |

All other modified or untracked work was preserved. Only these three Dart files were formatted.

## 3. Tests executed

**New file `test/web_sandbox_open_recovery_test.dart`, 8 tests: all pass on the VM.**

- Session ID uses only Web-safe `nextInt` bounds (all below 2^31).
- Session ID format is compatible with staging keys, and 2000 IDs generated at the same timestamp are all distinct.
- A fresh owner initializes and saves with the real secure source.
- Each of the 1–5 selectors opens its workspace (correct qubit count and header).
- Initialization failure: an injected `RangeError` shows the error and opens no circuit; storage is untouched; a second click still responds (no stuck `_opening`); after the fault is removed, a retry opens the saved circuit intact.
- Recoverable load error: Cancel leaves the chooser with no error; clicking again re-shows the dialog; Retry opens once storage is readable.
- Saved circuits load without losing operations: a schema-2 circuit with a gate and two measurements round-trips exactly, and a legacy schema-1 record for 4 qubits converts with both gates.
- The five workspaces stay isolated: distinct saved circuits for 1–5 qubits each load correctly, and clearing the 3-qubit workspace leaves the other four saved.

**Related existing suites** (`web_sandbox_measurement_test`, `sandbox_lifecycle_schema2_test`, `sandbox_activation_test`, `sandbox_program_snapshot_test`, `sandbox_circuit_persistence_test`, `web_app_test`): 72 pass, 4 fail. All 4 failures are in `web_app_test.dart`. **They predate W1:** with my `web_app.dart` edits temporarily reverted the same four fail, and the file was then restored.

| Failing test | Cause |
|---|---|
| `Web Sandbox exposes failed clear and retries without losing saved data` | Expects "Circuit not saved. Please retry.", likely changed by the schema-2 save queue |
| `Composer restores the existing Sandbox workspace` | Expects "Restored 1 saved operation(s)."; the uncommitted diff changed it to "Restored saved circuit." |
| `wide Composer prioritises the shared circuit above its tools` | 122 vs ≥126 px, likely the 4B.1 `M` palette button |
| `Web Composer canvas height follows qubit count and not circuit content` | 202 vs ≥206 px, likely the 4B.1 `M` palette button |

These belong to the measurement/4B.1 follow-up and were left as they are.

**Static checks**
- `flutter analyze` on the 3 changed files: no new issues. The only remaining notes are 4 pre-existing `curly_braces` infos in `sandbox_workspace_persistence.dart`, on lines I didn't change.
- `dart format --set-exit-if-changed`: clean. `git diff --check`: clean. No trailing whitespace in the untracked files.

No full test suite, full analyzer or build was run.

## 4. Browser-specific verification

`flutter test --platform chrome` (DDC, JavaScript) was run with a temporary probe test, deleted afterwards, plus the new test file:

- `1 << 32` evaluated to `0` in Chrome.
- The old expression threw `RangeError: max must be in range 0 < max ≤ 2^32, was 0`, which confirms D1 in a real browser.
- The new `createSessionId()` produced `1794070122409000_1b5deab9f4cb0487`, and `SandboxWorkspacePersistence.forStorage` constructed successfully.
- All 8 new tests pass in Chrome.

The `teX2SVG` console errors in that run are harness noise: the MathJax JS isn't loaded in the test page. They were not caused by this change.

## 5. Remaining limitations and risks

- I verified under DDC (debug JS), not a dart2js release build or dart2wasm. dart2js uses the same 32-bit shift semantics, and the new code uses no shifts. A release smoke test is still recommended (§6).
- `secureRandom` is a mutable static seam, documented as test-only. Production never reassigns it.
- The failure UI shows a generic message; details go only to the console.
- Native code paths are unchanged, but native (`home_page.dart`, `quantum_composer.dart`) also uses `programs` and benefits from the fix.
- The four pre-existing `web_app_test` failures remain.
- Measurement UX defects D3–D8 from the 4B.1 review are out of scope.

## 6. Manual verification steps

1. `flutter run -d chrome --release` (or deploy the Web build), open DevTools → Console, and go to **Composer**.
2. Click **1**. The workspace opens with a 1-qubit circuit and the header reads "1 qubits". The console shows no `RangeError`.
3. Click **Change**, then repeat for **2**, **3**, **4** and **5**. Each opens with the matching number of wires.
4. **Saved circuits:**
   1. In the 2-qubit workspace, add H on q0 and CNOT q0→q1.
   2. Click Change and open 3 qubits; add X on q2.
   3. Reload the page.
   4. Open 2 qubits: H and CNOT should be there. Open 3 qubits: only X on q2. 1, 4 and 5 qubits should be empty, unless they already had saved circuits.
5. **Earlier saves:** in a browser profile that used the previous Web version, open each qubit count that had a saved circuit and confirm its gates appear.
6. **Recoverable error (optional):**
   1. In DevTools → Application → Local Storage, set `flutter.sandbox_circuit_v2_active_q1` to `"invalid"`. Include the quotes, because shared_preferences stores values as JSON on Web.
   2. Click **1**. "Sandbox could not be restored" appears.
   3. Click **Cancel**. You stay on the chooser.
   4. Click **1** again; the dialog reappears.
   5. Delete the key and click **Retry**. The workspace opens.
7. **Silent-failure regression check:** none of the above should ever leave a click with no visible result. Any unexpected failure must show the red message under the qubit buttons, plus a SnackBar.
