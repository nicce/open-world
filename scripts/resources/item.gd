class_name Item extends Resource

enum Category { MATERIAL, FOOD, WEAPON, TOOL }

@export var id: StringName
@export var name: String
@export var texture: Texture2D
@export var weight: float = 1.0
@export var category: Category = Category.MATERIAL
@export var consumable: bool = false
