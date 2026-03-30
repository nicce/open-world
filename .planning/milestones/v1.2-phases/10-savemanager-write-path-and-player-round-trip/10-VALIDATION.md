# Phase 10 Validation: SaveManager — Write Path and Player Round-Trip

## Truths
- [x] SaveManager exists as a script-only autoload.
- [x] SaveManager.save_game writes to user://save.tmp, verifies, then renames to user://save.json.
- [x] SaveManager.load_game returns the Dictionary saved by save_game.
- [x] Player position and HP are persisted correctly between saves.
- [x] Restarting the game automatically restores player state from save.json if it exists.
- [x] Interacting with a Campfire opens a menu with a 'Save' option.
- [x] Missing save file on start does not cause errors.

## Artifacts
- [x] `scripts/save_manager.gd` exists and is an autoload.
- [x] `tests/unit/test_save_manager.gd` passes.
- [x] `tests/unit/test_player_save_load.gd` passes.
- [x] `user://save.json` exists after a save.
- [x] `scenes/campfire_menu.tscn` and `scripts/campfire_menu.gd` exist.

## Key Links
- [x] `world.gd` -> `SaveManager.load_game()` (Automatic load in _ready())
- [x] `SaveManager.save_game()` -> `Player.to_dict()` (Serialization)
- [x] `SaveManager.load_game()` -> `Player.from_dict()` (Restoration)
- [x] `campfire.gd` -> `CampfireMenu` (Interaction triggers menu)
