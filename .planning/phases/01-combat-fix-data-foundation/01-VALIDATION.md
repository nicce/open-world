---
phase: 1
slug: combat-fix-data-foundation
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-10
validated: 2026-03-13
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

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File | Status |
|---------|------|------|-------------|-----------|-------------------|------|--------|
| 1-01-01 | 01 | 0 | CMBT-01 | unit | `make test` | `tests/unit/test_player_state.gd` (3 tests) | ✅ green |
| 1-01-02 | 01 | 0 | CMBT-02 | unit | `make test` | `tests/unit/test_snake.gd` (3 tests) | ✅ green |
| 1-02-01 | 03 | 1 | DATA-01 | unit | `make test` | `tests/unit/test_inventory_slot.gd` (2 tests) | ✅ green |
| 1-02-02 | 03 | 1 | DATA-02 | unit | `make test` | `tests/unit/test_inventory.gd` (2 tests) | ✅ green |
| 1-02-03 | 03 | 1 | DATA-03 | unit | `make test` | `tests/unit/test_inventory.gd` (1 test) | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `tests/unit/test_player_state.gd` — covers CMBT-01 (state machine reset logic) — 3 tests, 3/3 green
- [x] `tests/unit/test_snake.gd` — covers CMBT-02 (knockback velocity application) — 3 tests, 3/3 green
- [x] New test cases in `tests/unit/test_inventory_slot.gd` — DATA-01 id-based stacking — 2 tests, 2/2 green
- [x] New test cases in `tests/unit/test_inventory.gd` — DATA-02 deep copy isolation, DATA-03 exact weight limit — 3 tests, 3/3 green

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| AnimationTree `animation_finished` fires with correct leaf name | CMBT-01 | Godot AnimationTree leaf naming requires runtime validation | Run game, attack, observe if state resets; check print output for signal name |
| Enemy recoil visually apparent | CMBT-02 | Visual feedback requires in-editor play | Attack snake, verify visible knockback recoil in game view |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s (suite runs ~1s)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** 2026-03-13 — all 5 requirements have automated test coverage; 2 manual-only behaviors documented above

---

## Validation Audit 2026-03-13

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated to manual-only | 0 |
| Tests reviewed | 11 (3 CMBT-01 + 3 CMBT-02 + 2 DATA-01 + 2 DATA-02 + 1 DATA-03) |
| Suite result | 88/88 passed |
