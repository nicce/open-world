---
phase: 4
slug: inventory-slot-full-rejection
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-12
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

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 04-01-01 | 01 | 1 | INV-02 (slot-full) | unit | `make test` | ❌ W0 — add to `tests/unit/test_inventory.gd` | ⬜ pending |
| 04-01-02 | 01 | 1 | INV-02 (regression) | unit | `make test` | ✅ already in `test_inventory.gd:307` | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/unit/test_inventory.gd` — add `test_insert_rejected_emitted_when_slots_full_but_weight_allows()` for INV-02 slot-full path

*All other test infrastructure (GUT, Makefile, existing signal tests) is already in place.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| "Too heavy!" HUD appears when all 15 slots occupied | INV-02 | Scene tree + visual confirmation required | Fill all 15 slots by picking up varied items; attempt to pick up one more; verify HUD label appears and fades |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
