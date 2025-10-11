extends CanvasLayer
class_name QuickBar

const SLOT_COUNT = 10

@onready var slots_container: HBoxContainer = $"SlotsContainer"
@onready var slot_buttons: Array[Button] = [
	$"SlotsContainer/Button0", $"SlotsContainer/Button1", $"SlotsContainer/Button2",
	$"SlotsContainer/Button3", $"SlotsContainer/Button4", $"SlotsContainer/Button5",
	$"SlotsContainer/Button6", $"SlotsContainer/Button7", $"SlotsContainer/Button8",
	$"SlotsContainer/Button9"
]
@onready var slot_highlight: Panel = $"SlotHighlight"
@onready var action_menu: ItemActionMenu = $SlotsContainer/ItemActionMenu

var cursor := -1
var menu_slot := -1
var menu_open := false

func _ready() -> void:
	slot_highlight.visible = false
	for index in SLOT_COUNT:
		var button := slot_buttons[index]
		button.custom_minimum_size = Vector2(64, 64)
		button.pressed.connect(func(): _on_slot_pressed(index))
		button.mouse_entered.connect(func(): _on_slot_hovered(index))
	action_menu.action_selected.connect(_on_action_selected)
	action_menu.popup_hide.connect(_on_menu_hidden)
	if not QuickbarManager.quickbar_updated.is_connected(refresh_slots):	
		QuickbarManager.quickbar_updated.connect(refresh_slots)
	refresh_slots(QuickbarManager.get_slots_snapshot())

func refresh_slots(updated_slots: Array) -> void:
	for index in SLOT_COUNT:
		var slot: Dictionary= updated_slots[index]
		var button := slot_buttons[index]
		if slot and slot.item:
			var item: Item = slot.item
			button.text = "%dx" % slot.quantity
			button.tooltip_text = item.item_name
			button.icon = item.icon
			button.disabled = false
		else:
			button.text = ""
			button.tooltip_text = ""
			button.icon = null
			button.disabled = true
	_update_highlight()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quickbar_backward"):
		_move_cursor(-1)
	elif event.is_action_pressed("quickbar_forward"):
		_move_cursor(1)
	if event.is_action_pressed("ui_accept"):
		_trigger_menu()

func _move_cursor(delta: int) -> void:
	cursor = clamp(cursor + delta if cursor >= 0 else 0, 0, SLOT_COUNT - 1)
	_update_highlight()

func _on_slot_pressed(index: int) -> void:
	cursor = index
	_update_highlight()
	_trigger_menu()

func _on_slot_hovered(index: int) -> void:
	cursor = index
	_update_highlight()

func _trigger_menu() -> void:
	if cursor < 0:
		return
	if menu_open and menu_slot == cursor:
		action_menu.hide()
		return
	var slot:Dictionary = QuickbarManager.slots[cursor]
	if not slot or not slot.item:
		return
	menu_slot = cursor
	menu_open = true
	var button := slot_buttons[cursor]
	action_menu.open_with_item(
		slot.item,
		button.global_position,
		[&"unequip", &"drop", &"place_trap"],
		{"slot_index": cursor}
	)

func _on_action_selected(action: ItemActionMenu.Action, item: Item, ctx: Dictionary) -> void:
	menu_open = false
	menu_slot = -1
	QuickbarManager.handle_action(action, item, ctx)  # 实际逻辑
	refresh_slots(QuickbarManager.get_slots_snapshot())

func _on_menu_hidden() -> void:
	menu_open = false
	menu_slot = -1

func _update_highlight() -> void:
	if cursor < 0:
		slot_highlight.visible = false
		return
	var button := slot_buttons[cursor]
	slot_highlight.visible = true
	slot_highlight.global_position = button.global_position
	slot_highlight.size = button.size
	button.button_pressed = true
