---
phase: 3
slug: item-management
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-11
validated: 2026-03-13
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | GUT 9.3.0 |
| **Config file** | `addons/gut/` (installed via `make install-gut`) |
| **Quick run command** | `make test` |
| **Full suite command** | `make test` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `make lint && make format-check && make test`
- **After every plan wave:** Run `make lint && make format-check && make test`
- **Before `/gsd:verify-work`:** Full suite must be green + manual smoke test
- **Max feedback latency:** ~10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File | Status |
|---------|------|------|-------------|-----------|-------------------|------|--------|
| 3-W0-01 | Wave 0 | 0 | ITEM-01, ITEM-02, ITEM-03 | unit | `make test` | `tests/unit/test_item_management.gd` (8 tests) | ✅ green |
| 3-01-01 | 01 | 1 | ITEM-01 | unit | `make test` | `test_use_consumable_removes_one_from_inventory` | ✅ green |
| 3-01-02 | 01 | 1 | ITEM-01 | unit | `make test` | `test_use_nonconsumable_is_noop`, `test_use_with_no_selection_is_noop` | ✅ green |
| 3-02-01 | 02 | 1 | ITEM-02 | unit | `make test` | `test_drop_removes_one_unit`, `test_drop_last_unit_empties_slot` | ✅ green |
| 3-02-02 | 02 | 1 | ITEM-02 | unit | `make test` | `test_drop_with_no_selection_is_noop` | ✅ green |
| 3-03-01 | 03 | 2 | ITEM-03 | unit | `make test` | `test_collect_emits_item_collected_on_success`, `test_collect_does_not_emit_on_failed_insert` | ✅ green |
| 3-03-02 | 03 | 2 | ITEM-03 | manual | see Manual-Only below | — | ✅ documented |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `tests/unit/test_item_management.gd` — 8 tests: ITEM-01 ×3, ITEM-02 ×3, ITEM-03 ×2 — 8/8 green

*Existing infrastructure (`test_inventory.gd`, `test_inventory_slot.gd`, `test_inventory_ui_helpers.gd`) covers the data layer. No framework config changes needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Slot click visual highlight | ITEM-01, ITEM-02 | Scene-tree-dependent; no headless GUT support without full scene instantiation | Open inventory, click a slot, verify it appears highlighted |
| Collectable world-spawn at player position | ITEM-02 | Requires live scene tree for position and node add | Open inventory, drop an item, verify collectable appears near player |
| Pickup label notification on screen | ITEM-03 | Requires CanvasLayer + Timer in running scene | Pick up an item, verify brief label appears and fades |
| Full smoke test | ITEM-01, ITEM-02, ITEM-03 | End-to-end in running game | Open inventory → use medpack (HP restored, slot count decrements) → drop key (key appears in world) → walk over key (pickup label shows) |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 10s (suite runs ~1s)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** 2026-03-13 — all 3 requirements have automated test coverage; 4 manual-only behaviors documented above

---

## Validation Audit 2026-03-13

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated to manual-only | 0 |
| Tests reviewed | 8 (test_item_management.gd ×8) |
| Suite result | 88/88 passed |
