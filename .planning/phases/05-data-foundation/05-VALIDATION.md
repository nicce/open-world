---
phase: 5
slug: data-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-18
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | GUT 4.x |
| **Config file** | `tests/.gutconfig.json` |
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
| 05-01-01 | 01 | 0 | EQUIP-05 | unit | `make test` | ❌ W0 | ⬜ pending |
| 05-01-02 | 01 | 1 | EQUIP-05 | unit | `make test` | ❌ W0 | ⬜ pending |
| 05-01-03 | 01 | 1 | EQUIP-05 | unit | `make test` | ❌ W0 | ⬜ pending |
| 05-02-01 | 02 | 1 | CTXMENU-01 | unit (signal) | `make test` | ❌ W0 | ⬜ pending |
| 05-02-02 | 02 | 1 | CTXMENU-01 | unit | `make test` | ❌ W0 | ⬜ pending |
| 05-02-03 | 02 | 1 | CTXMENU-02 | unit | `make test` | ❌ W0 | ⬜ pending |
| 05-02-04 | 02 | 1 | CTXMENU-04 | manual | n/a | n/a | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/unit/test_equipment_data.gd` — stubs for EQUIP-05 (equip/unequip method contracts, signal emission, return values)
- [ ] `tests/unit/test_context_menu_builder.gd` (optional) — stubs for CTXMENU-02 item-type-to-menu-options logic if extracted to a pure function

*Existing `tests/unit/` infrastructure covers all other needs — no new fixtures or framework install required.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Closing inventory panel dismisses any open context menu | CTXMENU-04 | PopupMenu node interaction requires live scene tree | 1. Open inventory. 2. Right-click item in bag slot. 3. Verify popup appears. 4. Press Tab/I to close inventory. 5. Verify popup is dismissed. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
