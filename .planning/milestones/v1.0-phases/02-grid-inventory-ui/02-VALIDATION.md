---
phase: 2
slug: grid-inventory-ui
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-10
validated: 2026-03-13
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | GUT (Godot Unit Testing) |
| **Config file** | `.gutconfig.json` / `make test` |
| **Quick run command** | `make lint && make format-check && make test` |
| **Full suite command** | `make lint && make format-check && make test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `make lint && make format-check && make test`
- **After every plan wave:** Run `make lint && make format-check && make test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File | Status |
|---------|------|------|-------------|-----------|-------------------|------|--------|
| 2-01-01 | 01 | 0 | INV-01, INV-02 | unit | `make test` | `tests/unit/test_inventory_ui_helpers.gd` (5 tests) | ✅ green |
| 2-01-02 | 01 | 1 | INV-01 | unit | `make test` | `tests/unit/test_inventory_ui_helpers.gd` (abbreviate ×3) | ✅ green |
| 2-01-03 | 01 | 1 | INV-02 | unit | `make test` | `tests/unit/test_inventory.gd` (signal tests ×5) | ✅ green |
| 2-01-04 | 01 | 1 | INV-02 | manual | Open game, fill inventory, try pickup | manual only | ✅ documented |
| 2-01-05 | 01 | 1 | INV-03 | unit | `make test` | `tests/unit/test_inventory.gd` + `test_inventory_slot.gd` (9 stacking tests) | ✅ green |
| 2-02-01 | 02 | 1 | INV-01 | manual | Open inventory, verify grid renders | manual only | ✅ documented |
| 2-02-02 | 02 | 1 | INV-02 | manual | Check weight label and rejection HUD | manual only | ✅ documented |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `tests/unit/test_inventory_ui_helpers.gd` — covers INV-01 (abbreviate ×3) and INV-02 (format_weight ×2) — 5 tests, 5/5 green
- [x] `tests/unit/test_inventory.gd` — 5 signal tests: `inventory_changed` ×2, `insert_rejected` ×3 (weight-blocked, slot-full, success cases) — all green

*Existing infrastructure (`make test`, GUT, `test_inventory.gd`) covers INV-03 already.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Inventory grid renders 15 slots on screen | INV-01 | GUT cannot render Control nodes headlessly | Open game → press Tab → count visible slot panels |
| Item icon/abbreviation appears in slot | INV-01 | Visual rendering requires scene tree | Pick up Medicpack → open inventory → slot shows "Medi" or icon |
| Weight label shows "X.X / Y kg" in panel | INV-02 | UI rendering not testable headlessly | Pick up item → open inventory → verify bottom label format |
| "Too heavy!" HUD appears on overweight pickup | INV-02 | HUD requires running game | Fill inventory to weight limit → walk into collectable → verify "Too heavy!" fades in/out |
| Stackable item increments quantity, not new slot | INV-03 | Visual slot rendering | Pick up 2x same item → verify single slot with quantity=2 |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s (suite runs ~1s)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** 2026-03-13 — all automatable requirements covered; 3 manual-only behaviors documented above

---

## Validation Audit 2026-03-13

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated to manual-only | 0 |
| Tests reviewed | 14 (5 ui_helpers + 5 inventory signals + 4 stacking) |
| Suite result | 88/88 passed |
