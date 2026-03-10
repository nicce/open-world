# Technology Stack

**Project:** Open World — Stardew-like 2D Survival/Adventure
**Researched:** 2026-03-10
**Confidence Note:** All findings grounded in direct codebase inspection + Godot 4 knowledge through August 2025.

---

## Recommended Stack

### Core Engine

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Godot Engine | 4.3 (stable) | Game engine and runtime | `project.godot` declares `"4.3"` feature flag. Forward Plus renderer enabled. Do not downgrade to 4.2. |
| GDScript | 4.x | All game logic, UI, resource systems | Engine-native; no compilation step; full editor integration; `class_name` for typed Resources works correctly. |

**Confidence:** HIGH — read directly from `project.godot`.

---

### Inventory and Item Data

| Pattern | Purpose | Why |
|---------|---------|-----|
| `Resource` subclasses | Item, InventorySlot, Inventory data model | Already in use. Serializable by engine, can be saved with `ResourceSaver`, instantiated cleanly in tests with `.new()`, exported as `.tres` for editor-configured items. Do not move item data into dictionaries or JSON. |
| `@export` on Resource fields | Expose item properties in the Inspector | Allows editor-time configuration of items (name, weight, texture, category) without touching code. |
| `StringName id` on Item (recommended) | Item identity for stack-matching and queries | Current codebase matches items by `slot.item.name == item.name` — fragile if names share strings. Add `id: StringName` for identity, keep `name` for display. |

**Confidence:** HIGH — based on direct codebase inspection.

---

### UI System

| Technology | Purpose | Why |
|------------|---------|-----|
| Godot `Control` nodes | Inventory UI, health bar, HUD | Already in use. `GridContainer` is the correct node for fixed-slot grid inventory. |
| `GridContainer` | Grid-based inventory layout | Standard Godot node for grid UIs. Set `columns` to desired slot count per row. Each slot is a `Panel` or `TextureRect` child instantiated via `preload`. |
| Theme resources | Visual consistency | Use a shared `.tres` Theme resource for slot borders, fonts, colors. Apply once at root Control, propagates to children. |

**Confidence:** HIGH — GridContainer behavior is documented and stable in Godot 4.

---

### Save System (future phase)

| Technology | Purpose | Why |
|------------|---------|-----|
| `ResourceSaver` / `ResourceLoader` | Persist inventory and game state | Inventory already extends Resource — `ResourceSaver.save(inventory, "user://save.tres")` serializes the entire slot array with items. No manual serialization needed. |
| `user://` path prefix | Save file location | Maps to platform-appropriate writable directory. Never use `res://` — read-only in exported builds. |
| `FileAccess` + JSON | Game metadata (settings, playtime) | For non-Resource data; simpler than a Resource for flat key-value structures. |

**Confidence:** MEDIUM — ResourceSaver works for Resources in Godot 4. Sub-resources (`InventorySlot` containing `Item`) may need `ResourceSaver.FLAG_BUNDLE_RESOURCES`. Verify during implementation.

**Do NOT use:** `ConfigFile` for save data — designed for settings, not object graphs.

---

### Testing

| Technology | Version | Purpose |
|------------|---------|---------|
| GUT | 9.3.0 | Unit testing framework — `make test` runs headlessly |
| gdtoolkit | 4.* | Linting and formatting — `make lint`, `make format-check` |

**Confidence:** HIGH — versions read directly from Makefile.

**Test pattern:** Pure logic tests (Resource methods, game math) in `tests/unit/`. Do not test `_physics_process` behavior in GUT — it requires a running scene tree.

---

## Patterns to Establish

### Item Identity
```gdscript
# Add to scripts/resources/item.gd
@export var id: StringName
```
Use `id` for all identity checks. Use `name` for display only.

### Slot Scene (Inventory UI)
Preload a `slot.tscn` scene (Panel + TextureRect + Label). In `inventory_ui.gd`, instantiate N slots into a `GridContainer` at `_ready()`. Update slot visuals by iterating `inventory.slots` and calling `slot_node.update(inventory_slot)`. Avoids rebuilding the slot list every frame.

### Inventory Signal Bus
Emit `changed` signal from `Inventory` when slots change (insert, remove, use). The UI observes this to refresh. Keeps UI decoupled from game logic.

### Consumable Use Handler
UI emits `item_used(item: Item, slot_index: int)`. Player script observes and dispatches by `item.category`. For `HealthItem`, calls `health_component.increase(health_item.health)` then `inventory.remove(item, 1)`. Keeps UI ignorant of game effects.

---

## What NOT to Use

| Avoid | Why |
|-------|-----|
| Third-party addons (beyond GUT) | Explicitly constrained in PROJECT.md |
| C# / .NET | Adds a second runtime dependency |
| `ConfigFile` for save data | Cannot encode object graphs |
| `RigidBody2D` for player | Physics engine fights direct velocity control |
| `get_node()` in `_process()` | Forbidden in CLAUDE.md — cache with `@onready` |
| Dictionary for item data | Loses type safety, editor integration, serialization |
| JSON for inventory save | ResourceSaver handles this automatically |

---

## Godot Version Note

`project.godot` declares `"4.3"` as its feature version, but the Makefile sets `GODOT_VERSION ?= 4.2.2` for the binary download. Update the Makefile's `GODOT_VERSION` to `4.3.x` to avoid version mismatch warnings during headless test runs.

**Confidence:** HIGH — read directly from `project.godot` and `Makefile`.

---

*Research complete: 2026-03-10*
