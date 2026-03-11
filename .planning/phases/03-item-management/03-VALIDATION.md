---
phase: 3
slug: item-management
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-11
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

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 3-W0-01 | Wave 0 | 0 | ITEM-01, ITEM-02, ITEM-03 | unit stub | `make test` | ❌ W0 | ⬜ pending |
| 3-01-01 | 01 | 1 | ITEM-01 | unit | `make test` | ✅ W0 | ⬜ pending |
| 3-01-02 | 01 | 1 | ITEM-01 | unit | `make test` | ✅ W0 | ⬜ pending |
| 3-02-01 | 02 | 1 | ITEM-02 | unit | `make test` | ✅ W0 | ⬜ pending |
| 3-02-02 | 02 | 1 | ITEM-02 | unit | `make test` | ✅ W0 | ⬜ pending |
| 3-03-01 | 03 | 2 | ITEM-03 | unit | `make test` | ✅ W0 | ⬜ pending |
| 3-03-02 | 03 | 2 | ITEM-03 | manual | see Manual-Only below | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/unit/test_item_management.gd` — stubs for ITEM-01 (use consumable), ITEM-01 (non-consumable no-op), ITEM-01 (no selection no-op), ITEM-02 (drop removes 1), ITEM-02 (drop last deselects), ITEM-02 (no selection no-op), ITEM-03 (collect emits signal), ITEM-03 (failed insert no signal)

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

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
