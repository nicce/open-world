# Pitfalls Research

**Domain:** Adding Save & Load to existing Godot 4 Resource-based inventory/equipment system
**Researched:** 2026-03-30
**Confidence:** HIGH (direct codebase inspection of all affected files)

## Critical Pitfalls

### 1. Saving Item Resource objects instead of `item.id`

**What happens:** `InventorySlot.item` is a typed `Item` Resource object. `JSON.stringify` cannot serialise GDScript objects — it produces `{}` or throws silently.

**Prevention:** Always save `str(slot.item.id)` (the StringName). On load, resolve via `ItemRegistry.get_item(StringName(saved_id))`.

**Phase:** Phase 9 (Inventory serialisation)

---

### 2. EquipmentData weapon/tool saved as Resource reference

**What happens:** Same as above — `EquipmentData.weapon` is an `Item` Resource. JSON will not serialise it.

**Additional risk:** If load runs before `hud_strip` is subscribed to `equipment_changed`, the signal fires into void and the HUD never updates.

**Prevention:** Save weapon/tool as id strings only. Call `SaveManager.load_game()` as the last line of `world.gd._ready()`.

**Phase:** Phase 9–10 (EquipmentData serialisation + load timing)

---

### 3. Loading before `player._ready()` clone completes

**What happens:** `player.gd._ready()` does `inventory = inventory.clone()` to isolate the player's inventory from the `.tres` template Resource. If load runs before this, it mutates the template. After `reload_current_scene()` on death, the template is dirty — subsequent loads have incorrect starting state.

**Prevention:** Call `SaveManager.load_game()` from `world.gd._ready()`. Children complete `_ready()` before parents in Godot's scene tree — player's clone runs first automatically. No extra action needed as long as load stays in `world.gd._ready()`.

**Phase:** Phase 10 (load path implementation)

---

### 4. Partial write corrupts the save file

**What happens:** `FileAccess.open(path, FileAccess.WRITE)` truncates the existing file immediately on open. If the game crashes mid-write, the file contains partial JSON — unrecoverable.

**Prevention:** Write to `user://save.tmp`, parse to verify valid JSON, then rename to `user://save.json` via `DirAccess.rename_absolute()`.

**Phase:** Phase 10 (SaveManager write path)

---

### 5. Autosave during area transition fires before scene tree is stable

**What happens:** `body_entered` signals fire mid-transition before `_ready()` has run on the new scene. Calling `save_game()` at that point may read null nodes.

**Prevention:** Use `call_deferred("_do_autosave")` in the area transition handler.

**Phase:** Phase 12 (autosave triggers)

---

## Moderate Pitfalls

### 6. `HealthComponent.health` is a runtime var — not `@export`

**What happens:** Code scanning `@export` fields to build the save dict will miss `health` — it's a plain `var` assigned in `_ready()`.

**Prevention:** Explicitly save `health_component.health` and `health_component.max_health`. Add `load_health(value: int)` to `HealthComponent` to bypass the `_ready()` init.

**Phase:** Phase 9

---

### 7. Collectables respawn after load

**What happens:** Collectables are instanced nodes in `world.tscn`. `reload_current_scene()` re-instantiates the full scene — all collectables reappear, even previously collected ones.

**Prevention:** Save a `collected_ids: Array[StringName]`. On load, iterate nodes in the `"collectables"` group, find matching ids, call `queue_free()` immediately.

**Phase:** Phase 11 (world state: collectables)

---

### 8. ItemRegistry returns null silently for unknown ids

**What happens:** Item ids may change during development. A renamed item id produces a null slot item — no error, item silently disappears.

**Prevention:** `ItemRegistry.get_item()` must call `push_warning("ItemRegistry: unknown id '%s'" % id)` before returning null. Null items are treated as empty slots on load.

**Phase:** Phase 9 (ItemRegistry implementation)

---

### 9. Replacing `player.inventory` breaks UI reference chain

**What happens:** `world.gd._ready()` passes `player.inventory` to UI nodes. If load creates a new instance and assigns `player.inventory = new_inventory`, the UI is subscribed to the old instance's signals.

**Prevention:** `Inventory.from_dict()` and `EquipmentData.from_dict()` mutate the existing instance. Never replace the var. Emit `inventory_changed` / `equipment_changed` at end of `from_dict()`.

**Phase:** Phase 10–11

---

### 10. Autosave during player death saves incoherent state

**What happens:** Autosave could fire while `player.current_state == DEAD`. Loading a save with `health = 0` and dead state causes an infinite reload loop.

**Prevention:** All save triggers guard: `if player.current_state == Player.State.DEAD: return`.

**Phase:** Phase 12 (autosave triggers)

---

## Minor Pitfalls

### 11. Float serialisation drift

**What happens:** `global_position` is a `Vector2` of floats. JSON round-trips may introduce tiny drift.

**Prevention:** Cast on load: `Vector2(float(data["x"]), float(data["y"]))`. Sub-pixel drift is imperceptible — no extra handling needed.

**Phase:** Phase 10

---

### 12. GUT tests cannot write to `user://` paths in headless mode

**What happens:** `user://` paths are inaccessible in headless Godot. Tests calling `FileAccess.open("user://save.json", ...)` fail in CI.

**Prevention:** Wrap `FileAccess` calls in a `SaveFileIO` helper with an injectable path. Tests pass a temp path; `SaveManager` uses `"user://save.json"` at runtime.

**Phase:** Phase 10

---

### 13. `equipment_changed` fires before HUD is wired

**What happens:** If `EquipmentData.from_dict()` runs before `hud_strip.set_equipment_data()`, the signal fires into void.

**Prevention:** Call `SaveManager.load_game()` as the last line of `world.gd._ready()` — after all `set_*()` calls.

**Phase:** Phase 10

---

### 14. Player position not saved

**What happens:** `global_position` is a `Node2D` property, invisible to `@export` scanners. Easy to forget when building the save dict.

**Prevention:** Explicitly include `"player_position": {"x": player.global_position.x, "y": player.global_position.y}` in the save dict. Restore with `player.global_position = Vector2(float(data["x"]), float(data["y"]))`.

**Phase:** Phase 10

---
*Pitfalls research for: Adding Save & Load to Godot 4 Resource-based inventory/equipment system*
*Researched: 2026-03-30*
