# Project Research Summary

**Project:** open-world (Godot 4 RPG) — v1.2 Save & Load
**Domain:** Save & Load system for Godot 4 Resource-based inventory/equipment game
**Researched:** 2026-03-30
**Confidence:** HIGH

## Executive Summary

This project adds a persistent save/load system to an existing Godot 4 top-down RPG that already has a component-based inventory, equipment, and world scene. The implementation follows Godot 4 best practices: a `SaveManager` Autoload handles all file I/O using `FileAccess` + `JSON`, while a new `ItemRegistry` Autoload maps stable `StringName` item ids back to typed Resource instances on load. All serialisation operates on id strings — never on Resource objects directly — because `JSON.stringify` cannot encode GDScript Resources.

The recommended approach is a 4-phase incremental build. Phase 9 builds the pure-logic foundation (ItemRegistry + Resource serialisation methods), which is fully unit-testable in isolation. Phase 10 introduces file I/O for the first time (SaveManager write then load path). Phase 11 closes the full round-trip including world state (collectables + dead enemies). Phase 12 wires autosave triggers and polish. This ordering is driven by hard dependency chains: nothing can be deserialised without ItemRegistry, and save output must be verified before load logic is written.

The critical architectural constraint is that Resource instances must be mutated in place on load — never replaced. `world.gd._ready()` wires `player.inventory` and `player.equipment_data` to UI nodes; replacing those instances after wiring silently orphans signal subscriptions. The second critical constraint is that `SaveManager.load_game()` must be called last in `world.gd._ready()`, after all UI subscriptions are established. Both constraints are easy to violate silently, which is why the phased approach — verifying the write path before touching load — is strongly recommended.

## Key Findings

### Recommended Stack

The entire save system uses Godot 4 built-ins with no new dependencies. `FileAccess` handles file I/O; `JSON.stringify` / `JSON.parse_string` handle serialisation. Two new Autoloads are required: `SaveManager` (owns save/load orchestration) and `ItemRegistry` (resolves item ids to typed Resources). The `BackgroundMusic` Autoload is the direct architectural precedent for both. `ResourceSaver` and `ConfigFile` were explicitly evaluated and rejected — neither can encode the mixed world-state dictionary the save file requires.

**Core technologies:**
- `FileAccess` + `JSON` (built-in): file I/O and serialisation — only option that handles nested world state dict cleanly
- `SaveManager` autoload: orchestration — must be Autoload because `world.gd` is freed on `reload_current_scene()` (player death)
- `ItemRegistry` autoload: id-to-Resource resolution — prerequisite for all deserialisation; must exist before any `from_dict()` is written
- `GUT` 9.3.0: unit testing — `SaveFileIO` wrapper needed so tests can inject a temp path instead of `user://`
- `gdtoolkit 4.*`: lint and format — already in project, no changes needed

### Expected Features

All P1 features ship in v1.2 core. P2 features (autosave, dead-enemy persistence, versioning) are polish within v1.2. Multiple save slots and cloud save are explicitly deferred to v2+.

**Must have (table stakes):**
- Player position saved — progress means nothing without this
- Player HP saved — returning to full HP after load is wrong; 0-HP loop is game-breaking
- Inventory saved — collected items must persist across sessions
- Equipment saved — equipped weapon must persist
- World state: collectables — picked-up items must not respawn
- Manual save via campfire — player needs intentional save trigger (campfire `sleep` interaction already exists)
- Load on game start — progress restored automatically

**Should have (genre expectation):**
- Autosave on sleep/area transition — matches Stardew-like genre convention; one `call_deferred` line
- Dead enemy persistence — world feels persistent between sessions
- Save file versioning (`"version": 1`) — forward-compatibility for Hunger and Stamina milestone

**Defer (v2+):**
- Multiple save slots — high UI complexity; no meaningful diverging choices in game yet
- Binary/encrypted saves — no benefit in a single-player local game; plain JSON is the correct choice
- Cloud save — requires external service and conflict resolution; out of scope

### Architecture Approach

The architecture reuses existing Godot patterns already established in the codebase. `SaveManager` follows the `BackgroundMusic` Autoload precedent. `ItemRegistry` is a new Autoload populated in the Inspector with all `.tres` item assets. `Inventory` and `EquipmentData` gain `to_dict()` / `from_dict()` methods that mutate in place and emit their existing signals so the UI refreshes without additional wiring. `HealthComponent` gains a single `load_health(value)` bypass method. World state is tracked via `collected_ids` and `dead_enemy_ids` arrays on `world.gd`, with collectables and enemies exposing `StringName` id fields.

**Major components:**
1. `ItemRegistry` autoload — maps `StringName id` to `Item Resource`; prerequisite for all deserialisation
2. `SaveManager` autoload — owns file I/O; atomic write (tmp then rename); calls `Inventory.from_dict()`, `EquipmentData.from_dict()`, `HealthComponent.load_health()`
3. `Inventory` / `EquipmentData` — gain `to_dict()` / `from_dict()`; mutate in-place, emit existing signals
4. `world.gd` — tracks `collected_ids` + `dead_enemy_ids`; calls `SaveManager.load_game()` last in `_ready()`
5. `campfire.gd` + area transition nodes — autosave triggers with dead-player guard

### Critical Pitfalls

1. **Saving Resource objects instead of item ids** — `JSON.stringify` produces `{}` for GDScript objects silently; always save `str(slot.item.id)` and resolve via `ItemRegistry` on load.
2. **Replacing Resource instances on load** — breaks signal subscriptions wired in `world.gd._ready()`; use `from_dict()` to mutate the existing instance in place, never `player.inventory = new_inventory`.
3. **Load timing before UI subscriptions are wired** — `equipment_changed` fires into void if load runs before `hud_strip.set_equipment_data()`; `SaveManager.load_game()` must be the last call in `world.gd._ready()`.
4. **Partial write corrupts save file** — `FileAccess.WRITE` truncates the file immediately on open; write to `user://save.tmp`, verify JSON parses, then rename to `user://save.json`.
5. **Autosave during area transition fires on unstable scene tree** — use `call_deferred("_do_autosave")`; guard all save triggers with `if player.current_state == Player.State.DEAD: return`.

## Implications for Roadmap

Based on research, the dependency chain mandates a 4-phase structure. Each phase has a clear "you cannot start this without the previous phase complete" dependency.

### Phase 9: Foundation — ItemRegistry and Resource Serialisation

**Rationale:** `ItemRegistry` is the hard prerequisite for all `from_dict()` calls. No deserialisation is possible without it. `Inventory.to_dict()` / `from_dict()` and `EquipmentData.to_dict()` / `from_dict()` are pure functions with no file I/O — fully unit-testable in isolation. `HealthComponent.load_health()` is a one-line addition. Building all pure logic before touching the file system means the most complex serialisation logic is verified before any integration work begins.

**Delivers:** `ItemRegistry` autoload registered; `Inventory` and `EquipmentData` round-trip methods; `HealthComponent.load_health()`; unit test coverage for all new methods.

**Addresses:** ItemRegistry (P1), Inventory round-trip (P1), Equipment round-trip (P1)

**Avoids:** Pitfall 1 (Resource objects in JSON), Pitfall 6 (HealthComponent runtime var missed)

### Phase 10: SaveManager — Write Path and Player Round-Trip

**Rationale:** Write path must be verified correct before load logic is written. `SaveManager` is an Autoload (must survive scene reload) — its structure must be right before anything else uses it. Player position and HP are the simplest possible load targets — no item resolution needed. Establishing the atomic write pattern and the `SaveFileIO` injection wrapper here means all later phases inherit correct I/O discipline.

**Delivers:** `SaveManager` Autoload registered; atomic write to `user://save.json`; load of player position + HP; `SaveFileIO` wrapper for GUT testability.

**Addresses:** Player position saved (P1), Player HP saved (P1), Load on game start (P1)

**Avoids:** Pitfall 3 (load timing), Pitfall 4 (partial write corruption), Pitfall 12 (GUT headless `user://` incompatibility)

### Phase 11: Full Round-Trip — Inventory, Equipment, and World State

**Rationale:** This is the highest-complexity phase. Inventory direct-slot assignment (bypassing `insert()` rules) and in-place mutation are the biggest implementation risks — address after the simpler player data path is proven. Collectable and enemy world state require adding `StringName` id fields to existing scenes and wiring `collected` / `dead` signals into `world.gd`. Running the full GUT suite after each step is the safety net.

**Delivers:** Full inventory + equipment round-trip; collectable world state (no respawn); dead-enemy persistence; unit and integration test coverage.

**Addresses:** Inventory saved (P1), Equipment saved (P1), World state collectables (P1), Dead enemy persistence (P2)

**Avoids:** Pitfall 2 (replacing Resource instances), Pitfall 7 (collectables respawn), Pitfall 9 (UI reference chain break)

### Phase 12: Autosave Triggers and Polish

**Rationale:** Autosave is a single line in `campfire.gd` and a deferred call in area transitions. Save file versioning is one key added to the save dict. These are isolated, low-risk additions that are cleanest as a final polish phase after the core round-trip is verified end-to-end.

**Delivers:** Autosave on campfire sleep + area transition; `"version": 1` key in save file; dead-player guard on all save triggers.

**Addresses:** Autosave on sleep/transition (P2), Save file versioning (P2)

**Avoids:** Pitfall 5 (autosave during unstable scene tree), Pitfall 10 (autosave during player death)

### Phase Ordering Rationale

- **ItemRegistry before SaveManager:** Hard dependency — `SaveManager.load_game()` calls `Inventory.from_dict(data, ItemRegistry)`. You cannot load inventory without ItemRegistry.
- **Write path before load path:** Verify JSON output is correct (open the file, inspect it) before writing code that reads it. Prevents debugging a load regression caused by a serialisation bug.
- **Player data before world state:** World state (collectables, enemies) requires modifying existing scene scripts and adding id fields. Player data requires only adding methods to Resources. Lower-risk change first.
- **Autosave last:** Autosave is a trigger wrapper — it calls the already-working save path. There is no reason to build it before the underlying save is proven.
- **Mutation in place throughout:** All three phases that touch Resource data (9, 10, 11) follow the same in-place mutation contract. Establishing it in Phase 9 means it is never accidentally violated later.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 11:** Direct-slot assignment for inventory load bypasses `insert()` rules — the exact slot assignment API needs verification against the current `Inventory` implementation before coding begins.

Phases with standard patterns (skip research-phase):
- **Phase 9:** Pure GDScript methods on existing Resources; well-established Godot pattern; no external APIs.
- **Phase 10:** `FileAccess` + `JSON` + Autoload registration; all documented in Godot 4 official docs; atomic write pattern is standard.
- **Phase 12:** One-line campfire hook + `call_deferred`; no novel patterns.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Direct codebase inspection; `FileAccess` + `JSON` is the only viable option given PROJECT.md constraints |
| Features | HIGH | Clear scope boundary for v1.2; P1/P2/P3 split grounded in genre conventions and dependency analysis |
| Architecture | HIGH | Based on direct reading of all affected scripts; Autoload pattern matches existing `BackgroundMusic` precedent |
| Pitfalls | HIGH | All pitfalls derived from actual code inspection, not speculation; each references the specific line/pattern that causes the failure |

**Overall confidence:** HIGH

### Gaps to Address

- **`gold_key` collectable_id:** Audit whether `gold_key.tscn` already has a stable `collectable_id` field or needs one added. Address at the start of Phase 11.
- **`lake_world.gd` scope:** PROJECT.md flags this as potentially orphaned. Determine before Phase 11 whether it contains collectables that need `collected_ids` tracking.
- **Inventory slot assignment API:** Confirm the exact method for direct slot assignment in `Inventory` before writing `from_dict()`. If `slots` is not directly accessible, a `set_slot(index, item, qty)` method may be needed.
- **Save file versioning migration:** `"version": 1` is included in Phase 12 as a forward-compatibility key. Actual migration logic (e.g., for Hunger and Stamina) is not in scope for v1.2 and should be flagged as a future milestone dependency.

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection of `scripts/resources/inventory.gd`, `scripts/resources/equipment_data.gd`, `scripts/health_component.gd`, `scripts/world.gd`, `scripts/collectable.gd`, `scripts/snake.gd`, `scripts/campfire.gd`, `project.godot` — all integration points verified against actual code
- Godot 4 official API: `FileAccess`, `JSON`, `DirAccess`, Autoload registration — built-in APIs used throughout

### Secondary (MEDIUM confidence)
- Godot community patterns for save/load via `FileAccess` + JSON — atomic write pattern, id-based serialisation
- GUT framework documentation — `SaveFileIO` injectable wrapper pattern for headless test compatibility

---
*Research completed: 2026-03-30*
*Ready for roadmap: yes*
