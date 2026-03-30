extends Node

## ItemRegistry
## Resolves item IDs to standalone Resource instances for serialisation.

var _registry: Dictionary = {}


func _ready() -> void:
	_build_registry()


func _build_registry() -> void:
	_registry[&"sword"] = preload("res://resources/items/sword.tres")
	_registry[&"axe"] = preload("res://resources/items/axe.tres")
	_registry[&"medpack"] = preload("res://resources/items/medpack.tres")
	_registry[&"gold_key"] = preload("res://resources/items/gold_key.tres")


func get_item(id: StringName) -> Item:
	if _registry.has(id):
		return _registry[id]

	push_warning("ItemRegistry: Unknown item ID: ", id)
	return null
