# Visual milestone reporting

Every milestone that changes what the app looks like ends with review material that an external reviewer can assess without running the app. This convention is permanent from v2.6 M11E onwards.

## Deliverables

| Deliverable | Location | Purpose |
|---|---|---|
| Implementation report | `reports/<VERSION>_<MILESTONE>_<TOPIC>.md` | Findings, decisions, changes, files, tests, limitations, deviations |
| Original screenshots | `reports/screenshots/<version>_<milestone>/` | The evidence: full resolution, from the running app |
| Contact sheets | `reports/screenshots/<version>_<milestone>/contact_sheets/` | Representative, grouped overview for visual review |
| Contact-sheet manifest | `reports/screenshots/<version>_<milestone>/contact_sheets.manifest` | How the sheets were grouped, so they can be regenerated |

**Contact sheets supplement the original screenshots; they never replace them.** Where fine mathematical or UI detail matters (typeset expressions, glyphs, alignment, one-pixel rules), the report also points to the individual full-resolution screenshot.

`/reports` is git-ignored, so screenshots, sheets and manifests stay local and are never committed. Tracked decisions belong in `docs/`.

## Screenshots

- Take them from a **running release build**, not from widget tests.
- Name them `before_<id>_<subject>_<W>x<H>.png` and `after_<id>_<subject>_<W>x<H>.png`.
  - Use the same `<id>_<subject>_<W>x<H>` for a Before/After pair, so the two can be matched automatically.
  - Add a suffix such as `_scrolled` for a second view of the same page.
- Capture "before" shots from the previous build before changing code.
- Cover the standard sizes the milestone affects: 390 × 844, 500 × 900, 800 × 900, 1024 × 768, 1280 × 800, 1440 × 900, 1920 × 1080, 2560 × 1080, and landscape 844 × 390.
- Never edit or regenerate accepted screenshots just to make sheets.

## Contact sheets

They are generated with `tools/contact_sheet.sh` (ImageMagick 7). Run `tools/contact_sheet.sh --help` for every option.

| Layout | Grid | Use for |
|---|---|---|
| `desktop` | 2 × 2 | Desktop and tablet pages, landscape phones |
| `maths` | 1 column × 2 rows | Fine mathematical or typographic detail |
| `mobile` | 3 columns × 1 row | Portrait phone screenshots |
| `compare` | 2 × 1 | Before (left) and After (right) |

**Rules**
- Group sheets by what the reviewer assesses (for example "Article experience", "Gate references", "Mobile layouts"), not by capture order.
- Prefix sheet names with a two-digit group number so they sort in reading order.
- Never mix desktop and mobile screenshots on one sheet.
- Leave out near-duplicates; readability beats packing.
- Use `compare` sheets only for the significant before/after changes, one pair per sheet.

**Usage**

```sh
# One sheet (pages continue as NAME_p01, NAME_p02 … when needed)
tools/contact_sheet.sh --layout desktop --name 01_article_experience \
  reports/screenshots/v26_m11e after_n04_bell_state_1440x900.png …

# Every before_/after_ pair in a directory
tools/contact_sheet.sh --layout compare --name 08_before_after \
  reports/screenshots/v26_m11e

# All of a milestone's sheets from its manifest (recommended)
tools/contact_sheet.sh --manifest \
  reports/screenshots/v26_m11e/contact_sheets.manifest \
  reports/screenshots/v26_m11e
```

Manifest lines read `NAME LAYOUT FILE...`. Lines starting with `#` are comments. The sheet heading is derived from `NAME`.

The tool:
- only reads the originals;
- keeps every aspect ratio, never cropping, distorting or enlarging;
- prints each original filename above its screenshot;
- orders files deterministically;
- writes identical PNGs for identical inputs.

## Report checklist

The implementation report lists, in this order:
1. initial findings;
2. design decisions;
3. the changes;
4. component reuse;
5. files;
6. scientific or content corrections;
7. tests run, with results;
8. the screenshot inventory **and the contact-sheet inventory**;
9. known limitations;
10. deviations from the brief;
11. recommendations for later milestones.
