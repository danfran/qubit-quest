# Qubit Quest v2.6 M11B: visual design

This refines the existing identity; it does not replace it. The following are **retained unchanged**:
- the logo ⟨ϕubit|ϕuest⟩;
- the dark-only theme;
- the cyan interactive accent (`#56CCF2`) and violet strong accent (`#B388FF`);
- the success, warning and error colours;
- the gate gradient families (`lib/widgets/gate_visual_style.dart`);
- the spacing scale (4 / 8 / 12 / 16 / 24 / 32) and the radii (10 / 12 / 14 / 18 / pill).

Every token below is used by the prototype file, so the renders show it.

## 1. Current state [Code]

- `QubitQuestColors` defines:

  | Token | Value |
  |---|---|
  | `background` | `#00030A` |
  | `surface` | `#111827` |
  | `surfaceRaised` | `#18233A` |
  | `surfaceInset` | `#030814` |
  | `surfaceInsetRaised` | `#101A2D` |
  | `border` | `#344A73` @ 40% |

- In practice almost every region uses `background`, `surface` or `surfaceInset`:
  - global navigation, section navigation, page headers and the Composer panels are all near-black;
  - they are distinguished only by 1 px borders.
- The page header and the global top bar are the same black, so the logo bar and the page title read as one band.
- **Typography** (`QubitQuestTypography`): display 28, title 22, heading 17, question 19, body 14, supporting 13, label 12, math 15/18/16. The scale is sound but under-used. Lesson questions, panel titles and helper text often appear at similar sizes.
- **Breakpoints** are scattered:

  | Area | Breakpoints (px) |
  |---|---|
  | Shell | 900 |
  | Journey | 720 / 960 / 1200 |
  | Notebook and Mastery | 760 / 1200 |
  | Composer | tiers 640 / 1200-ish geometry; toolbar 860 / 980 |
  | Inspector | 820 / 560 |
  | Bloch Explorer | 760 / 1180 (with height conditions) |
  | Exercise | 640 |
  | Activity | compact 680 |

## 2. Surface ladder [Proposal]

The ladder separates layers by tone, not by more bordered cards. Navy tones carry content and charcoal carries chrome.

| Token (proposed) | Value | Layer | Existing token it replaces or extends |
|---|---|---|---|
| `app` | `#05070C` | Behind everything | `background` (`#00030A`), slightly lifted |
| `nav` | `#0A0D14` | Global navigation (charcoal, neutral) | new |
| `section` | `#0B1220` | Section navigation (deep navy) | new |
| `page` | `#0D1526` | Page header band, Composer header, action bar | new |
| `work` | `#101A2C` | Primary panels | ≈ `surface` |
| `work2` | `#0E1728` | Secondary workspace (palette strip, reading backdrop) | new |
| `inset` | `#070B14` | Wells: circuit, maths, figures, charts | ≈ `surfaceInset` |
| `inspector` | `#131D31` | Contextual inspector, Read panel | ≈ `surfaceInsetRaised`, lifted |
| `raised` | `#18233A` | Selected segment, raised controls | `surfaceRaised` (unchanged) |

Rules:
- Adjacent layers always differ by at least one ladder step. Borders become secondary: soft lines (`border` @ 22%) only where two equal tones meet.
- **Wells are darker than their surroundings** (the circuit and maths sit "in" the surface); **the inspector is lighter** (it sits "on" the workspace).
- Cards are reserved for *peer* items in a grid (analysis panels, option cards, figures). Sections inside the inspector and the Read panel are divided by rules, not boxed.

## 3. Typography [Proposal]

Same family (the Flutter default, Roboto on web); the scale is assigned by role.

| Role | Size / weight | Use |
|---|---|---|
| Page or article title | 28–30 / 600 | Notebook article, chapter page, Mastery title |
| Conceptual question | 22 / 600 | Lesson and challenge question (`question` 19 → 22 on desktop) |
| Page header title | 21 / 600 (compact: 16) | Section pages; compact headers in workspaces |
| Section heading | 17–18 / 600 | Article sections, Mastery question line |
| Body | 14–15 / 400, line-height 1.6–1.7 | Reading text 15 at ≤ 68 characters per line |
| Panel label | 11.5 / 600, uppercase, +0.08em | Panel titles ("CURRENT STATE"). **Never wraps mathematics** (see §5) |
| Supporting | 12.5–13 / 400, muted | Helper and validation notes |
| Numerics | Tabular monospace | Probabilities, counts, decimals |
| Mathematics | Serif maths face (`LatexText` / TeX as today) at 16–19 | State expressions, formulas |

## 4. Component treatments (brief §2)

| Element | Treatment |
|---|---|
| Global navigation | Charcoal rail; selected item = cyan tint and cyan text; group labels in violet; logo at the top of the rail |
| Section navigation | Navy column; status dots (filled green = done, cyan ring = current, grey = not started); the active row is tinted; current chapter expanded |
| Page headers | `page` band: breadcrumb (muted, with links), title, status chips, primary action at right |
| Primary workspace | `work` panels on a `work2` / `app` backdrop; one primary action per screen |
| Secondary workspace | `work2` strips (palette); no card chrome |
| Contextual inspector | `inspector` tone with a left border; header (gate tile, name, placement, close) → actions → stacked sections → disclosures → Related |
| Mathematical content | Inset **maths well** with a 3 px violet left rule; displayed maths centred-left; never inside uppercase labels |
| Experimental results | Panel pair: setup and outcomes. Legend shows **outline = exact, fill = observed**; counts table; basis and qubit order stated |
| Notifications and feedback | Check feedback in the action bar with a semantic stripe (warning / success / error). Transient confirmations as dark toasts (M9). No feedback over the circuit |
| Interactive controls | Pills for actions (primary = solid cyan; secondary = outline; quiet = text); segmented controls for modes; chips for filters and status |
| Expanded and collapsed | Disclosure rows with ▸/▾, a content label, and an optional inline summary in muted text |

## 5. Mathematics presentation rules

- **Keep the notation guide** (`V26_NOTATION_GUIDE.md`): register order, U+2212 minus, one global-phase factor, and the basis named for every correlation claim.
- **Never place mathematics in text that is uppercased or letter-spaced.** Uppercasing changes symbols: the prototype pass caught "Rx(θ)" rendering as "RX(Θ)". Panel labels with symbols use a `nocase` variant.
- **Large registers** (more than 8 non-zero terms):
  - show the closed form;
  - add a **sign/magnitude map** (prototype 2): a 2 × 16 grid for five qubits, with labels q4 | x;
  - keep the full table in a disclosure.

  The amplitude table stays for 8 terms or fewer.

## 6. Responsive tiers [Proposal]

One set of tiers for the whole application, measured on the viewport for the shell and on the host width for workspaces:

| Tier | Width | Shell | Section navigation | Composer | Lesson / challenge | Notebook | Bloch |
|---|---|---|---|---|---|---|---|
| Ultrawide | ≥ 2000 | Nav 232 | 300–320 | Analysis capped at 1760 px; circuit well unbounded | Same as wide | Centred 760 + margin 250 | Sphere capped by height |
| Wide | 1440–1999 | Nav 232 | 300 | 3-column analysis (≥ 1600) or 2-column; inspector docked 340 | Curriculum with lessons + workspace | Margin column ≥ 1600 | Act 300 · sphere · Read 340 |
| Standard | 1280–1439 | Rail 76 | 264 | 2-column analysis; inspector docked | Curriculum 264 | Centred column | Act 270 · Read 310 |
| Compact | 1024–1279 | Rail 76 | 228 (collapsible) | Inspector as overlay | Curriculum collapsible | Spread → single column | Read moves under the stage |
| Tablet | 900–1023 | Rail 76 | Context strip | 2-column analysis | Context strip; comparison stacks | Single column | Stacked |
| Small | 600–899 | Top bar + drawer | Context strip | 1-column analysis | Context strip; sticky action bar | Single column | Sphere first |
| Phone | < 600 | Top bar | Context strip | Inspector bottom sheet; no rail | Sticky action bar | Single column, 24 px title | Sphere → Act → Timeline → Read |

The 900 px shell breakpoint is retained. The scattered component breakpoints (640 / 680 / 720 / 760 / 820 / 860 / 960 / 980 / 1180 / 1200) collapse into these tiers. The Composer and inspector keep host-width measurement, because they are embedded in different hosts.

## 7. Gate colours

Unchanged: H red; X family blue (X, CX, CCX, MCX, Rx); Y family cyan (Y, CY, Ry); Z deep blue; S periwinkle; T/Rz violet; CZ sky; M slate.

One documented clarification: dimmed (unavailable) gates use 38% opacity and keep their hue, so the family remains recognisable.
