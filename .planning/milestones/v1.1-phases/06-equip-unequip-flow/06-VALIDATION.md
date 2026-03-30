---
phase: 6
slug: equip-unequip-flow
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-18
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | GUT 9.3.0 |
| **Config file** | `addons/gut/` (installed via `make install-gut`) |
| **Quick run command** | `make lint && make format-check && make test` |
| **Full suite command** | `make test` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `make lint && make format-check && make test`
- **After every plan wave:** Run `make test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 06-01-01 | 01 | 0 | EQUIP-01, EQUIP-02, EQUIP-03, EQUIP-04 | unit stub | `make test` | ❌ W0 | ⬜ pending |
| 06-01-02 | 01 | 1 | EQUIP-01 | unit | `make test` | ❌ W0 | ⬜ pending |
| 06-01-03 | 01 | 1 | EQUIP-02 | unit | `make test` | ❌ W0 | ⬜ pending |
| 06-01-04 | 01 | 1 | EQUIP-03 | unit | `make test` | ❌ W0 | ⬜ pending |
| 06-01-05 | 01 | 1 | EQUIP-04 | unit | `make test` | ❌ W0 | ⬜ pending |
| 06-02-01 | 02 | 2 | EQUIP-01, EQUIP-02, EQUIP-04 | manual | Visual inspection | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/unit/test_equip_flow.gd` — stubs for EQUIP-01, EQUIP-02, EQUIP-03, EQUIP-04
- [ ] `scripts/resources/player_equipment_data.tres` — EquipmentData resource created and assigned to Player scene Inspector (verify or create if Phase 5 left it unconfirmed)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Item disappears from bag grid after equip | EQUIP-01 | Requires Godot renderer to verify UI update | Open inventory, right-click weapon, select Equip, confirm item is gone from bag grid |
| Old weapon reappears in bag on swap | EQUIP-02 | Requires visual confirmation of slot UI | Equip weapon A; equip weapon B; confirm A is in bag and B is in weapon slot |
| Equip button absent or rejected when bag full | EQUIP-03 | Requires runtime bag-full state | Fill bag completely, then attempt unequip; confirm weapon stays equipped |
| Tool item moves to tool slot | EQUIP-04 | Requires visual confirmation of equipment slot UI | Right-click tool item, select Equip, confirm tool slot shows item and bag slot is empty |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
