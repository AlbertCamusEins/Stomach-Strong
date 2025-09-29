# scripts/DialogueConditionInventory.gd
@tool
class_name DialogueConditionInventory
extends DialogueCondition

@export var item: Item
@export var required_quantity: int = 1
@export var must_have: bool = true

func is_met(context: Dictionary) -> bool:
	if not item:
		return false if must_have else true
	var quantity := 0
	quantity = _count_in_inventory(GameManager.player_current_inventory)
	return quantity >= required_quantity if must_have else quantity < required_quantity

func get_failure_reason(context: Dictionary) -> String:
	return "缺少必要物品" if must_have else "持有禁止物品"

func _count_in_inventory(inv_array: Array) -> int:
	var total = 0
	for slot in inv_array:
		if slot.item.item_name == item.item_name:
			total += slot.quantity
	return total
