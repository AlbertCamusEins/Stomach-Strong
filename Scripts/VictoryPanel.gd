extends Control

class_name VictoryPanel

signal loot_clicked(item: Item)
signal confirm_pressed

@onready var _grid_container: GridContainer = $PanelContainer/MarginContainer/VBoxContainer/GridContainer
@onready var _confirm_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Button

var _loot_entries: Dictionary = {}
const _CLAIMED_SUFFIX := "（已领取）"
const _PLACEHOLDER_TEXT := "没有掉落"
const _UNKNOWN_ITEM_TEXT := "未知物品"

func _ready() -> void:
	hide()
	_confirm_button.pressed.connect(_on_confirm_button_pressed)

func show_results(loot_data: Dictionary) -> void:
	_clear_entries()
	var source: Dictionary = {}
	if loot_data != null:
		source = loot_data
	var keys := source.keys()
	keys.sort()
	var has_entries := false
	for key in keys:
		var entry: Dictionary = source.get(key) as Dictionary
		var item: Item = entry.get("item")
		var quantity: int = int(entry.get("quantity", 0))
		if not item or quantity <= 0:
			continue
		_add_loot_button(key, item, quantity)
		has_entries = true
	if not has_entries:
		_add_placeholder_label()
	show()
	_confirm_button.grab_focus()

func hide_results() -> void:
	hide()

func mark_loot_collected_by_name(item_name: String) -> void:
	if not _loot_entries.has(item_name):
		return
	var entry: Dictionary = _loot_entries[item_name]
	if entry.get("claimed", false):
		return
	entry["claimed"] = true
	_loot_entries[item_name] = entry
	_update_entry_button(entry)

func mark_loot_collected(item: Item) -> void:
	if not item:
		return
	var identifier := _identify_item(item)
	if identifier.is_empty():
		return
	mark_loot_collected_by_name(identifier)

func update_loot_quantity(item_name: String, quantity: int) -> void:
	if not _loot_entries.has(item_name):
		return
	var entry: Dictionary = _loot_entries[item_name]
	entry["quantity"] = quantity
	if quantity <= 0:
		entry["claimed"] = true
	_loot_entries[item_name] = entry
	_update_entry_button(entry)

func get_unclaimed_items() -> Array:
	var result: Array = []
	for entry in _loot_entries.values():
		if entry.get("claimed", false):
			continue
		result.append(entry.get("item"))
	return result

func _add_loot_button(item_name: String, item: Item, quantity: int) -> void:
	var display_name := _get_display_name(item, item_name)
	var button := Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.text = _format_entry_text(display_name, quantity, false)
	button.pressed.connect(_on_loot_button_pressed.bind(item_name))
	_grid_container.add_child(button)
	_loot_entries[item_name] = {
		"button": button,
		"item": item,
		"quantity": quantity,
		"claimed": false,
		"display_name": display_name,
		"identifier": item_name
	}

func _add_placeholder_label() -> void:
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text = _PLACEHOLDER_TEXT
	_grid_container.add_child(label)

func _clear_entries() -> void:
	for child in _grid_container.get_children():
		child.queue_free()
	_loot_entries.clear()

func _on_loot_button_pressed(item_name: String) -> void:
	if not _loot_entries.has(item_name):
		return
	var entry: Dictionary = _loot_entries[item_name]
	if entry.get("claimed", false):
		return
	entry["claimed"] = true
	_loot_entries[item_name] = entry
	_update_entry_button(entry)
	emit_signal("loot_clicked", entry.get("item"))

func _on_confirm_button_pressed() -> void:
	emit_signal("confirm_pressed")

func _update_entry_button(entry: Dictionary) -> void:
	var button: Button = entry.get("button")
	if not is_instance_valid(button):
		return
	var display_name: String = entry.get("display_name", _UNKNOWN_ITEM_TEXT)
	var quantity: int = int(entry.get("quantity", 0))
	var claimed: bool = entry.get("claimed", false)
	button.text = _format_entry_text(display_name, quantity, claimed)
	button.disabled = claimed

func _format_entry_text(display_name: String, quantity: int, claimed: bool) -> String:
	var text := "%s x%d" % [display_name, max(quantity, 0)]
	if claimed:
		text += _CLAIMED_SUFFIX
	return text

func _get_display_name(item: Item, fallback: String) -> String:
	if item and item.item_name and not item.item_name.is_empty():
		return item.item_name
	if fallback and not fallback.is_empty():
		return fallback
	if item and not item.resource_path.is_empty():
		return item.resource_path
	return _UNKNOWN_ITEM_TEXT

func _identify_item(item: Item) -> String:
	if not item:
		return ""
	if item.item_name and not item.item_name.is_empty():
		return item.item_name
	if not item.resource_path.is_empty():
		return item.resource_path
	return str(item)
