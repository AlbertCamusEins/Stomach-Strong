# scripts/DialogueActionRemoveItem.gd
@tool
class_name DialogueActionRemoveItem
extends DialogueAction

@export var item: Item
@export var quantity: int = 1

func execute(context: Dictionary) -> void:
	if not item or quantity <= 0:
		return
	var gm = GameManager
	if gm:
		gm.remove_item(item, quantity)
	elif context.has("inventory"):
		var remaining = quantity
		var inventory: Array = context["inventory"]
		for slot in inventory:
			if remaining <= 0:
				break
			if slot and slot.item and slot.item.item_name == item.item_name:
				var remove = min(remaining, slot.quantity)
				slot.quantity -= remove
				remaining -= remove
