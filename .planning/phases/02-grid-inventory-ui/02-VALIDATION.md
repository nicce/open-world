---
phase: 2
slug: grid-inventory-ui
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-10
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

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 2-01-01 | 01 | 0 | INV-01, INV-02 | unit | `make test` | ❌ Wave 0 | ⬜ pending |
| 2-01-02 | 01 | 1 | INV-01 | unit | `make test` | ✅ (after Wave 0) | ⬜ pending |
| 2-01-03 | 01 | 1 | INV-02 | unit | `make test` | ❌ Wave 0 (extend existing) | ⬜ pending |
| 2-01-04 | 01 | 1 | INV-02 | manual | Open game, fill inventory, try pickup | manual only | ⬜ pending |
| 2-01-05 | 01 | 1 | INV-03 | unit | `make test` | ✅ (existing test_inventory.gd) | ⬜ pending |
| 2-02-01 | 02 | 1 | INV-01 | manual | Open inventory, verify grid renders | manual only | ⬜ pending |
| 2-02-02 | 02 | 1 | INV-02 | manual | Check weight label and rejection HUD | manual only | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/unit/test_inventory_ui_helpers.gd` — stubs for INV-01 (abbreviation logic, slot count constant) and INV-02 (weight label format string)
- [ ] `tests/unit/test_inventory.gd` — add `test_insert_rejected_signal_emitted_when_weight_full` covering INV-02 `insert_rejected` signal path

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

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
