# scripts/DialogueActionAddItem.gd
@tool
class_name DialogueActionAddItem
extends DialogueAction

@export var item: Item
@export var quantity: int = 1

func execute(context: Dictionary) -> void:
	if not item or quantity == 0:
		return
	var gm = _get_game_manager(context)
	if gm:
		gm.add_item(item, quantity)
	elif context.has("inventory"):
		var slot = InventorySlot.new()
		slot.item = item.duplicate(true)
		slot.quantity = quantity
		context["inventory"].append(slot)
