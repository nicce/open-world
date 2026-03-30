---
phase: 7
slug: combat-wiring-hud-strip
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-19
---

# Phase 7 — Validation Strategy

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
- **Max feedback latency:** ~10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 7-01-01 | 01 | 0 | CMBT-03, CMBT-04 | unit | `make test` | ❌ W0 | ⬜ pending |
| 7-02-01 | 02 | 1 | CMBT-03, CMBT-04 | unit | `make test` | ✅ (after W0) | ⬜ pending |
| 7-03-01 | 03 | 1 | CMBT-05 | manual/smoke | — | N/A | ⬜ pending |
| 7-04-01 | 04 | 1 | HUD-01, HUD-02 | manual/smoke | — | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/unit/test_player_combat.gd` — stubs for CMBT-03 and CMBT-04 using `PlayerStub` pattern from `test_player_state.gd`

*All other requirements (CMBT-05, HUD-01, HUD-02) are manual-verification only — no test file gaps.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| WeaponIndicator visible when weapon equipped, hidden when not | CMBT-05 | Requires running scene tree and visual inspection | Equip a weapon → verify indicator appears above player; unequip → verify indicator disappears |
| HUD strip always visible regardless of inventory state | HUD-01 | CanvasLayer visibility is UI runtime behavior | Open and close inventory panel → verify HUD strip remains visible at all times |
| HUD slot shows correct texture or label when equipment changes | HUD-02 | UI rendering requires running scene | Equip weapon with texture → verify slot shows texture; equip item without texture → verify slot shows item name |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
