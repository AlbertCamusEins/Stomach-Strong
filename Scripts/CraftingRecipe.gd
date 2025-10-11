@tool
class_name CraftingRecipe
extends Resource

@export var recipe_id: StringName
@export var output_item: Item
@export_range(1, 999) var output_quantity: int = 1
@export var pattern: Array[IngredientSlot] = []
