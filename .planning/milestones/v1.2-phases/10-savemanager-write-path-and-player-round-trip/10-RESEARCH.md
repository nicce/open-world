# Phase 10: SaveManager — Write Path and Player Round-Trip - Research

**Researched:** 2025-05-22
**Domain:** Godot 4.3 Persistence, JSON Serialization, Atomic File Access
**Confidence:** HIGH

## Summary

This phase implements a persistent `SaveManager` to store player state (position and health) between sessions. Godot 4.3 provides a static `FileAccess` API and a global `JSON` class for efficient data serialization. To ensure data integrity, an **atomic write pattern** (writing to a temporary file before renaming) is required to prevent data corruption during crashes or interruptions.

**Primary recommendation:** Implement `SaveManager` as an **Autoload** singleton that handles JSON serialization of player data and manages atomic file operations using `FileAccess` and `DirAccess`.

## Project Constraints (from GEMINI.md)

- **Language:** Godot 4.3 GDScript.
- **Coding Style:** PascalCase for class names, snake_case for variables/methods.
- **Signals:** Use signals for system communication (e.g., player health changes).
- **Singletons:** Registered as Autoloads in `project.godot`.
- **Validation:** `make lint` and `make test` must pass. New logic functions require unit tests in `tests/unit/`.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| FileAccess | Godot 4.3 | Static file I/O | Replaces the deprecated `File` class in Godot 4.x |
| JSON | Godot 4.3 | Serialization | Built-in high-performance JSON processing |
| DirAccess | Godot 4.3 | Atomic file operations | Required for safe file renaming and removal |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Autoload | Godot 4.3 | Singleton | Global persistence manager available to all scenes |

## Architecture Patterns

### Recommended Project Structure
```
scripts/
└── save_manager.gd     # The Autoload singleton
```

### Pattern 1: Atomic Write (Save-Safe)
**What:** Writing to a `.tmp` file, closing it, removing the old file, and then renaming the `.tmp` file to the target name.
**When to use:** All critical data persistence to prevent file corruption.
**Example:**
```gdscript
func save_atomic(path: String, data: Dictionary) -> Error:
    var json_string = JSON.stringify(data)
    var tmp_path = path + ".tmp"
    
    var file = FileAccess.open(tmp_path, FileAccess.WRITE)
    if not file:
        return FileAccess.get_open_error()
    file.store_string(json_string)
    file.close() # CRITICAL: Close before renaming
    
    var dir = DirAccess.open("user://")
    if dir.file_exists(path):
        dir.remove(path) # Safer for cross-platform compatibility
    return dir.rename(tmp_path, path)
```

### Anti-Patterns to Avoid
- **Writing directly to `user://save.json`:** If the game crashes during `store_string()`, the save file will be corrupted.
- **Forgetting to `.close()`:** Prevents renaming on Windows and some other platforms due to file locks.
- **Serializing Vector2 directly:** `JSON.stringify()` turns `Vector2(1,2)` into `"(1, 2)"`, which `JSON.parse_string()` cannot automatically convert back.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON Parsing | Custom Regex | `JSON.parse_string()` | Fast, built-in, handles edge cases. |
| Type Conversion | Manual string splits | `var_to_str()` / `str_to_var()` | Godot's native way to handle complex types in strings. |
| Path Management | Manual path strings | `user://` prefix | Ensures cross-platform write permissions. |

## Common Pitfalls

### Pitfall 1: Vector2 Serialization
**What goes wrong:** Saving `player.position` directly into a Dictionary and passing to `JSON.stringify` results in a string representation in the JSON file.
**How to avoid:** Convert to a Dictionary `{"x": pos.x, "y": pos.y}` or use `var_to_str(pos)`.

### Pitfall 2: Atomic Rename failing on Windows
**What goes wrong:** `DirAccess.rename()` may fail if the destination file already exists.
**How to avoid:** Explicitly call `DirAccess.remove(path)` before renaming the `.tmp` file.

### Pitfall 3: Loading too early
**What goes wrong:** An Autoload's `_ready()` runs before the main scene is fully loaded.
**How to avoid:** Provide a `load_game(player)` method that is called by the `world.gd` in its `_ready()` or after the player is instantiated.

## Code Examples

### JSON-Safe Vector2 Helpers
```gdscript
static func vector2_to_dict(vec: Vector2) -> Dictionary:
    return {"x": vec.x, "y": vec.y}

static func dict_to_vector2(dict: Dictionary) -> Vector2:
    return Vector2(dict.get("x", 0.0), dict.get("y", 0.0))
```

### SaveManager Skeleton
```gdscript
extends Node

const SAVE_PATH = "user://save.json"

func save_game(player: Player) -> void:
    var data = {
        "position": {"x": player.position.x, "y": player.position.y},
        "health": player.health_component.health
    }
    # ... atomic write logic ...

func load_game(player: Player) -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        return false
        
    var json_string = FileAccess.get_file_as_string(SAVE_PATH)
    var data = JSON.parse_string(json_string)
    if data:
        player.position = Vector2(data.position.x, data.position.y)
        player.health_component.load_health(int(data.health))
        return true
    return false
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `File.new()` | `FileAccess.open()` | Godot 4.0 | Static API, safer memory management. |
| `JSON.print()` | `JSON.stringify()` | Godot 4.0 | Simplified naming. |
| `JSON.parse()` | `JSON.parse_string()` | Godot 4.0 | Direct return of data structure. |

## Open Questions

1. **When should auto-save occur?**
   - Recommendation: Every time the player transitions between areas or manually interacts with a "save point" (e.g., the campfire). For this phase, a simple call in `world.gd` or a test key (e.g., F5) is sufficient.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Godot | Engine Runtime | ✓ | 4.3 | — |
| user:// filesystem | Persistence | ✓ | — | — |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | GUT 9.x |
| Config file | .gutconfig.json (standard) |
| Quick run command | `make test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SAVE-01 | Atomic write verification | Unit | `make test` | ❌ Wave 0 |
| SAVE-02 | Player state (Pos, HP) persistent | Integration | `make test` | ❌ Wave 0 |
| SAVE-04 | Auto-load on start | Integration | `make test` | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] `tests/unit/test_save_manager.gd` — covers atomic write logic and data integrity.
- [ ] `tests/unit/test_player_persistence.gd` — covers player state restoration.

## Sources

### Primary (HIGH confidence)
- Official Godot 4.3 Documentation - [FileAccess](https://docs.godotengine.org/en/stable/classes/class_fileaccess.html)
- Official Godot 4.3 Documentation - [JSON](https://docs.godotengine.org/en/stable/classes/class_json.html)

### Secondary (MEDIUM confidence)
- Godot community forums for atomic write best practices.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core Godot APIs.
- Architecture: HIGH - Standard Singleton pattern.
- Pitfalls: HIGH - Common cross-platform issues documented.

**Research date:** 2025-05-22
**Valid until:** 2025-06-22
