# Qubit Quest v2.6: Learning Journey and web shell design (M5)

Status: implemented in M5 (2026-11-25). This is the tracked specification for the web Learning Journey and the shared shell conventions. The native `LearningMapScreen` remains for the mobile app.

## 1. Architecture

```text
WebJourneyWorkspace (web_learning_workspace.dart)    selection state, lesson host switching
 ├─ WebJourneyOverview (web_journey_overview.dart)   master–detail curriculum (presentation only)
 │    ├─ header: "Learning Journey", overall progress, Mastery Challenges link
 │    ├─ curriculum list: one row per chapter, one status glyph each
 │    └─ chapter detail: status, title, introduction, primary action,
 │       illustration, learning outcomes, lessons, connections
 └─ _ChapterWorkspace → WebLessonWorkspace           existing lesson hosts (unchanged; M6a)
JourneyCurriculum (models/journey_curriculum.dart)   read-only status, progress and actions
JourneyChapterIllustration (widgets/…)               chapter circuit fragments (Composer painter)
```

`JourneyCurriculum.of(state)` derives everything from the existing rules:

- **Lesson availability:** `ProgressionRules.isJourneyLessonUnlocked`.
- **Chapter completion:** `CampaignProgressPolicy.chapterProgress`.

It stores nothing and changes nothing. Totals come from `journeyChapters` and `journeyLessons`, so new chapters need no structural change.

## 2. Statuses

| Status | Rule | Glyph |
|---|---|---|
| Completed | every lesson completed | ✓ green |
| In progress | unlocked, some lessons completed | ▶ cyan when active, otherwise ○ |
| Not started | unlocked, none completed | ▶ cyan when active, otherwise ○ |
| Locked | first lesson not unlocked | lock |

**Active chapter:** the chapter containing the frontier, i.e. the first lesson in curriculum order that is unlocked and not completed.

**Selection** is separate from status:

- **Highlight:** a raised background and a cyan left edge.
- **Detail:** shows whether the chapter is "Your current chapter". When another chapter is selected, a link returns to the current one.
- **One glyph per row:** no duplicate badges, borders or glows.

## 3. Selection

- **Opening the Journey:** the active chapter is selected. After the whole curriculum is complete, the final chapter; otherwise chapter 1.
- **Stored identifiers:** none; the selection is presentation state. Deep links and remembered selections are clamped with `validSelection`, so missing, outdated or future chapter numbers fall back safely.
- **Returning from a lesson:** selects that lesson's chapter, and its progress is re-read from the controller.

## 4. Locked-chapter preview

- **What a locked chapter shows:** its number, title, introduction, illustration, learning outcomes and lesson titles. Lessons are visibly locked.
- **Primary action:** disabled.
- **Prerequisite:** the actual one is named ("Opens when you complete ‘…’, the final lesson of Chapter N−1"). Under the linear rule, completing lesson L unlocks L+1.
- **Safety:** previewing never unlocks content, completes lessons or changes the frontier. `WebJourneyWorkspace._openLesson` re-checks `isJourneyLessonUnlocked` before any lesson host opens. Solutions are never shown; they live only in lesson hosts, behind Check.

## 5. Chapter detail

- **Content:** status line, title, introduction (`categoryIntro`), primary action, chapter progress, illustration, then:
  - **"What you will learn":** each lesson's existing `keyInsight`;
  - **"Lessons":** number, title, type label, status, and Next / Open / Review / Locked;
  - **"Connections."**
- **Primary action:** Start chapter (no lesson done), Continue · Lesson N.M (next unlocked incomplete lesson), Review chapter (completed: opens lesson 1; progress is never reset), Locked (disabled).
- **Lesson rows:** open lessons directly, replacing the previous map → chapter → chooser path.
- **Lesson types:** Circuit, Fill the gate, Circuit reading, Concept check, Question, Measurement lab.

## 6. Illustrations

Chapters 2–10 show a circuit fragment drawn by the Composer's painter, with a caption verified against the simulator in `test/journey_curriculum_test.dart`.

**No preview is the complete solution of any Journey lesson (M6a).**

- **Test:** a data-driven test copies each preview's gate sequence, after a lesson's fixed gates, into every lesson whose palette allows it, and requires the lesson's own evaluator to fail.
- **What it found:** the M5 previews for chapters 1, 3, 4, 5, 6 and 7 solved lessons 1–3, 11–13, 17, 20, 23–25, 28, 33 and 34. They were replaced:

| Chapter | Preview (M6a) | Shows |
|---|---|---|
| 1 | none (text-first) | every chapter-1 lesson offers only X, so any X circuit is an answer |
| 2 | H then Z | (|0⟩ − |1⟩)/√2, the hidden sign |
| 3 | H on q1 of two qubits | (|00⟩ + |10⟩)/√2, superposition of one qubit |
| 4 | H, H | returns |0⟩: destructive interference |
| 5 | H, CX, then X on q1 | (|01⟩ + |10⟩)/√2: Z-basis results always opposite; neither qubit has a state of its own |
| 6 | X, then a CX chain over three qubits | |111⟩: CX passes basis values (not arbitrary states) |
| 7 | H on q2, CX to q1 and q0 | GHZ (|000⟩ + |111⟩)/√2, a coherent superposition, not a 50/50 mixture |
| 8–10 | unchanged | kickback, CZ oracle, two-qubit Grover round |

- **Text-first chapters:** chapters 11–13 remain text-first.
- **Kets in captions:** `keepKetsTogether` keeps each ket on one line.

## 7. Progress

- **Header:** "*a* of *C* chapters completed · *b* of *L* lessons" and **one** overall bar (the lesson fraction).
- **Chapters:** "*x* of *n* lessons completed". In-progress rows show *x*/*n*.
- **Source:** persisted `completedLessonIds` and `maxUnlockedLevel`; the storage format and completion criteria are unchanged.

## 8. Connections (concept relationships)

- **Source:** the existing `LearningMapScreen.conceptLinks` (2→4, 3→4, 5→7, 9→11, 10→11, 12→Mastery). They appear in the detail as "Builds on" and "Prepares you for", with links.
- **Labelling:** marked as conceptual: "chapters still open in order".
- **Removed:** the chip collection from primary navigation.
- **Future option (not implemented):** a secondary concept-graph view.

## 9. Mastery availability (D10 resolved)

- **Access:** always open (`ProgressionRules.masteryChallengesUnlocked`).
- **Web:** the Journey header offers "Mastery Challenges", and chapter 12's connection says Mastery is open at any time. The dead sidebar lock path is removed.
- **Native map:** the Mastery node is drawn available and opens Mastery from a fresh install, matching the real access rule.
- **Unchanged:** challenge unlocking and completion.

## 10. Responsive behaviour

The layout follows the **workspace** width, not the browser width:

| Workspace width | Layout |
|---|---|
| ≥ 1200 | Master–detail, 300 px curriculum |
| 960–1199 | Master–detail, 268 px curriculum |
| 720–959 | Master–detail, 236 px curriculum |
| < 720 | Sequential: curriculum list → chapter (with "All chapters" back) → lesson |

- **Detail text:** never wider than 760 px. The illustration card is sized to its circuit (≤ 560 px) and the circuit is drawn at 1.3×.
- **Invariant:** resizing or collapsing navigation keeps the selection and never changes progress.

## 11. Shell

- **Destinations:** LEARN (Journey, Notebook, Mastery Challenges) and EXPLORE (Composer, Bloch Explorer).
- **Header:** 52 px with a 26 px wordmark (was 56 / 30).
- **Tokens:** shell colours use `QubitQuestColors.shellDivider` and `navigationSelected` instead of raw literals.
- **Navigation:** the collapsible rail, drawer and preferences are unchanged.
- **Journey heading:** "Learning Journey" appears once, not repeated in a secondary header.

## 12. Browser routing (D8, partial)

- **Implemented:** hash routes for destinations and Journey chapters: `#/journey`, `#/journey/chapter-3`, `#/notebook`, `#/mastery`, `#/composer`, `#/bloch`.
  - **Startup:** the address selects the destination and chapter (`parseWebRoute`). `main()` reads the route from `PlatformDispatcher.defaultRouteName` before `runApp`, because the startup splash's `MaterialApp` reports `/` and replaces the address before the shell is built. `Uri.base` cannot be used: it is the document base and has no fragment.
  - **While running:** the address mirrors the current destination with a history *replace*, so reload returns to the same place.
  - **Safety:** a chapter link only selects the chapter; locked lessons stay locked.
  - **Sessions:** destinations remain mounted, so routing never recreates Composer sessions or drops measurement results.
- **Deferred:**
  - Back/Forward history between destinations: the root `Navigator` owns browser pops, and doing this properly needs a Router migration.
  - Lesson-level URLs.

## 13. M6a integration (as built)

- **Lesson host:** `_openLesson` opens `WebLessonWorkspace`, which runs circuit lessons in `WebComposerExercise` on the shared workspace and concept checks on a reading page. The chapter's context header (breadcrumb, title, objective, lesson chooser and progress) sits above both.
- **Returning:** the back arrow, or "Back to chapter" after completion, returns to the overview with the lesson's chapter selected and its progress re-read.
- **Shortcuts:** `WebJourneyWorkspace(isActive:)` gives the lesson keyboard shortcuts only while the Journey is visible.
- **Wording:** chapter intros say "learners"; the Chapter 5/6 controlled-gate and Chapter 7 GHZ key insights were corrected for scientific accuracy (see the M6a report).
