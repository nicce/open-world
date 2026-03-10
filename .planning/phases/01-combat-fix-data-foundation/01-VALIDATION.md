---
phase: 1
slug: combat-fix-data-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-10
---

# Phase 1 — Validation Strategy

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
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 1-01-01 | 01 | 0 | CMBT-01 | unit | `make test` | ❌ W0 | ⬜ pending |
| 1-01-02 | 01 | 0 | CMBT-02 | unit | `make test` | ❌ W0 | ⬜ pending |
| 1-02-01 | 02 | 0 | DATA-01 | unit | `make test` | ⚠️ partial | ⬜ pending |
| 1-02-02 | 02 | 0 | DATA-02 | unit | `make test` | ⚠️ partial | ⬜ pending |
| 1-02-03 | 02 | 0 | DATA-03 | unit | `make test` | ⚠️ partial | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/unit/test_player_state.gd` — covers CMBT-01 (state machine reset logic)
- [ ] `tests/unit/test_snake.gd` — covers CMBT-02 (knockback velocity application)
- [ ] New test cases in `tests/unit/test_inventory_slot.gd` — DATA-01 id-based stacking (two items with same name but different id must not stack)
- [ ] New test cases in `tests/unit/test_inventory.gd` — DATA-02 deep copy isolation, DATA-03 exact weight limit acceptance

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| AnimationTree `animation_finished` fires with correct leaf name | CMBT-01 | Godot AnimationTree leaf naming requires runtime validation | Run game, attack, observe if state resets; check print output for signal name |
| Enemy recoil visually apparent | CMBT-02 | Visual feedback requires in-editor play | Attack snake, verify visible knockback recoil in game view |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
