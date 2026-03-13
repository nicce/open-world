---
phase: 4
slug: inventory-slot-full-rejection
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-12
validated: 2026-03-13
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | GUT 9.3.0 |
| **Config file** | `.gutconfig.json` (project root) |
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

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File | Status |
|---------|------|------|-------------|-----------|-------------------|------|--------|
| 04-01-01 | 01 | 1 | INV-02 (slot-full) | unit | `make test` | `test_inventory.gd:331` — `test_insert_rejected_emitted_when_slots_full_but_weight_allows` | ✅ green |
| 04-01-02 | 01 | 1 | INV-02 (regression) | unit | `make test` | `test_inventory.gd:307` — `test_insert_rejected_emitted_when_weight_blocks_all` | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `tests/unit/test_inventory.gd` — `test_insert_rejected_emitted_when_slots_full_but_weight_allows()` at line 331 — 1/1 green

*All other test infrastructure (GUT, Makefile, existing signal tests) is already in place.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| "Too heavy!" HUD appears when all 15 slots occupied | INV-02 | Scene tree + visual confirmation required | Fill all 15 slots by picking up varied items; attempt to pick up one more; verify HUD label appears and fades |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 15s (suite runs ~1s)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** 2026-03-13 — INV-02 slot-full path has automated test; regression guard in place; 1 manual-only behavior documented

---

## Validation Audit 2026-03-13

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated to manual-only | 0 |
| Tests reviewed | 2 (slot-full signal + weight regression) |
| Suite result | 88/88 passed |
