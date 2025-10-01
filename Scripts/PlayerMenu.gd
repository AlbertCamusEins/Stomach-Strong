extends CanvasLayer

const PORTRAIT_SIZE = Vector2(250, 400)

@onready var panel_container: PanelContainer = $PanelContainer
@onready var adjust_button: Button = $"PanelContainer/MarginContainer/HBoxContainer/FormationPanel/AdjustButton"
@onready var combat_party_grid: GridContainer = $"PanelContainer/MarginContainer/HBoxContainer/FormationPanel/CombatPartyPanel/CombatPartyGrid"
@onready var reserve_party_grid: GridContainer = $"PanelContainer/MarginContainer/HBoxContainer/FormationPanel/ReservePartyPanel/ReservePartyGrid"
@onready var character_name_label: Label = $PanelContainer/MarginContainer/HBoxContainer/DetailPanel/EquipmentPanel/PortraitAndEquipment/PortraitContainer/CharacterNameLabel
@onready var portrait_container: VBoxContainer = $"PanelContainer/MarginContainer/HBoxContainer/DetailPanel/EquipmentPanel/PortraitAndEquipment/PortraitContainer"
@onready var equipment_grid: GridContainer = $"PanelContainer/MarginContainer/HBoxContainer/DetailPanel/EquipmentPanel/PortraitAndEquipment/EquipmentContainer/EquipmentGrid"
@onready var stats_title_label: Label = $"PanelContainer/MarginContainer/HBoxContainer/DetailPanel/StatsPanel/HBoxContainer/StatsContainer/StatsTitle"
@onready var stats_grid: GridContainer = $"PanelContainer/MarginContainer/HBoxContainer/DetailPanel/StatsPanel/HBoxContainer/StatsContainer/StatsGrid"
@onready var skills_title_label: Label = $"PanelContainer/MarginContainer/HBoxContainer/DetailPanel/StatsPanel/HBoxContainer/SkillsContainer/SkillsTitle"
@onready var skills_grid: GridContainer = $"PanelContainer/MarginContainer/HBoxContainer/DetailPanel/StatsPanel/HBoxContainer/SkillsContainer/SkillsGrid"
@onready var inventory_title_label: Label = $"PanelContainer/MarginContainer/HBoxContainer/VBoxContainer3/Label"
@onready var inventory_grid: GridContainer = $"PanelContainer/MarginContainer/HBoxContainer/VBoxContainer3/VBoxContainer/InventoryGrid"
@onready var close_button: Button = $"PanelContainer/MarginContainer/HBoxContainer/VBoxContainer3/CloseButton"

var adjust_mode := false
var selected_character_id: String = ""

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_unhandled_input(true)
	adjust_button.text = "Edit Formation"
	close_button.text = "Close"
	skills_title_label.text = "Skills"
	stats_title_label.text = "Stats"
	inventory_title_label.text = "Inventory"
	equipment_grid.columns = 2
	skills_grid.columns = 2
	stats_grid.columns = 2
	adjust_button.pressed.connect(_on_adjust_button_pressed)
	close_button.pressed.connect(close_menu)
	refresh_menu()

func open_menu() -> void:
	if visible:
		return
	show()
	get_tree().paused = true
	refresh_menu()

func close_menu() -> void:
	hide()
	if adjust_mode:
		_set_adjust_mode(false)
	get_tree().paused = false

func toggle_menu() -> void:
	if visible:
		close_menu()
	else:
		open_menu()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("exit"):
		close_menu()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("toggle_player_menu"):
		if visible:
			close_menu()
		else:
			open_menu()
			get_viewport().set_input_as_handled()
			return

func refresh_menu() -> void:
	_ensure_selected_character()
	refresh_party_lists()
	refresh_selected_character()
	_update_inventory_display()

func refresh_party_lists() -> void:
	_populate_party_grid(combat_party_grid, GameManager.combat_party, true)
	_populate_party_grid(reserve_party_grid, GameManager.reserve_party, false)

func refresh_selected_character() -> void:
	if selected_character_id.is_empty() or not GameManager.all_characters.has(selected_character_id):
		character_name_label.text = "No Character Selected"
		stats_title_label.text = "Stats"
		_clear_stats_grid()
		_clear_equipment_grid()
		_clear_skills_grid()
		_clear_portrait()
		return

	var character: CharacterData = GameManager.all_characters[selected_character_id]
	if not character:
		return

	GameManager.calculate_total_stats(selected_character_id)
	var stats: CharacterStats = character.stats
	character_name_label.text = character.character_name
	stats_title_label.text = "%s - Stats" % character.character_name
	_update_portrait(character)
	_update_equipment_display(selected_character_id)
	_update_stats_display(stats)
	_update_skills_display(stats)

func select_character(character_id: String) -> void:
	if character_id.is_empty() or not GameManager.all_characters.has(character_id):
		return
	selected_character_id = character_id
	refresh_party_lists()
	refresh_selected_character()

func _populate_party_grid(container: GridContainer, party: Array[String], is_combat: bool) -> void:
	for child in container.get_children():
		child.queue_free()
	for character_id in party:
		if not GameManager.all_characters.has(character_id):
			continue
		var character: CharacterData = GameManager.all_characters[character_id]
		var button := Button.new()
		button.text = character.character_name
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = not adjust_mode
		if not adjust_mode:
			button.button_pressed = character_id == selected_character_id
		button.pressed.connect(_on_party_member_pressed.bind(character_id, is_combat))
		container.add_child(button)

func _on_party_member_pressed(character_id: String, is_combat: bool) -> void:
	if adjust_mode:
		if is_combat:
			GameManager.move_character_to_reserve(character_id)
		else:
			GameManager.move_character_to_combat(character_id)
		selected_character_id = character_id
		refresh_menu()
	else:
		select_character(character_id)

func _on_adjust_button_pressed() -> void:
	_set_adjust_mode(not adjust_mode)

func _set_adjust_mode(enabled: bool) -> void:
	adjust_mode = enabled
	adjust_button.text = "Finish Editing" if enabled else "Edit Formation"
	refresh_party_lists()

func _ensure_selected_character() -> void:
	if not _character_in_parties(selected_character_id):
		if GameManager.combat_party.size() > 0:
			selected_character_id = GameManager.combat_party[0]
		elif GameManager.reserve_party.size() > 0:
			selected_character_id = GameManager.reserve_party[0]
		else:
			selected_character_id = ""

func _character_in_parties(character_id: String) -> bool:
	if character_id.is_empty():
		return false
	return GameManager.combat_party.has(character_id) or GameManager.reserve_party.has(character_id)

func _update_portrait(character: CharacterData) -> void:
	_clear_portrait()
	if character.portrait:
		var portrait_rect := TextureRect.new()
		portrait_rect.texture = character.portrait
		portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		portrait_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		portrait_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		portrait_rect.expand_mode = TextureRect.EXPAND_FIT_HEIGHT
		
		portrait_rect.custom_minimum_size = PORTRAIT_SIZE
		
		portrait_container.add_child(portrait_rect)
	else:
		var placeholder_rect := TextureRect.new()
		placeholder_rect.custom_minimum_size = PORTRAIT_SIZE
		placeholder_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		placeholder_rect.size_flags_horizontal = Control.SIZE_FILL
		placeholder_rect.size_flags_vertical = Control.SIZE_FILL
		placeholder_rect.expand_mode = TextureRect.EXPAND_FIT_HEIGHT
		
		portrait_container.add_child(placeholder_rect)

func _update_equipment_display(character_id: String) -> void:
	_clear_equipment_grid()
	var equipment := GameManager.get_character_equipment(character_id, false)

	for slot_enum_value in EquipmentComponent.EquipmentSlot.values():
		var slot_name := _format_slot_name(EquipmentComponent.EquipmentSlot.keys()[slot_enum_value])
		var name_label := Label.new()
		name_label.text = slot_name
		equipment_grid.add_child(name_label)

		var slot_panel := PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(140, 36)

		var button := Button.new()
		button.flat = true
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		button.pressed.connect(_on_equipment_slot_clicked.bind(slot_enum_value))
		slot_panel.add_child(button)

		var item_label := Label.new()
		item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		var equipped_item: Item = null
		if equipment and equipment.has(slot_enum_value):
			equipped_item = equipment[slot_enum_value]

		if equipped_item:
			item_label.text = equipped_item.item_name
			item_label.tooltip_text = equipped_item.description
		else:
			item_label.text = "Empty"

		slot_panel.add_child(item_label)
		equipment_grid.add_child(slot_panel)

func _update_stats_display(stats: CharacterStats) -> void:
	_clear_stats_grid()
	if not stats:
		return
	var bonuses: Dictionary = stats.equipment_bonuses if stats.equipment_bonuses else {}
	_add_stat_row("Max Health", stats.max_health, bonuses.get("max_health", 0))
	_add_stat_row("Current Health", stats.current_health, 0, stats.max_health)
	_add_stat_row("Max Satiety", stats.max_satiety, bonuses.get("max_satiety", 0))
	_add_stat_row("Current Satiety", stats.current_satiety, 0, stats.max_satiety)
	_add_stat_row("Max Mana", stats.max_mana, bonuses.get("max_mana", 0))
	_add_stat_row("Current Mana", stats.current_mana, 0, stats.max_mana)
	_add_stat_row("Attack", stats.attack, bonuses.get("attack", 0))
	_add_stat_row("Defense", stats.defense, bonuses.get("defense", 0))
	_add_stat_row("Base Speed", stats.base_speed, bonuses.get("base_speed", 0))

func _update_skills_display(stats: CharacterStats) -> void:
	_clear_skills_grid()
	if not stats or not stats.skills or stats.skills.is_empty():
		var none_label := Label.new()
		none_label.text = "No skills learned"
		none_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		none_label.size_flags_horizontal = Control.SIZE_FILL
		skills_grid.add_child(none_label)
		return
	for skill in stats.skills:
		if not (skill is Skill):
			continue
		var name_label := Label.new()
		name_label.text = skill.skill_name
		skills_grid.add_child(name_label)

		var details_label := Label.new()
		details_label.text = _describe_skill(skill)
		details_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		#skills_grid.add_child(details_label)

func _update_inventory_display() -> void:
	for child in inventory_grid.get_children():
		child.queue_free()

	var can_equip := not selected_character_id.is_empty()
	for slot in GameManager.player_current_inventory:
		if not slot or not slot.item:
			continue
		var item: Item = slot.item
		var button := Button.new()
		button.text = "%s x%d" % [item.item_name, slot.quantity]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = item.description

		var is_equipment := item.equipment_props != null
		var is_consumable := item.consumable_props != null
		if can_equip and (is_equipment or is_consumable):
			button.disabled = false
			button.pressed.connect(_on_inventory_item_clicked.bind(item))
		else:
			button.disabled = true

		inventory_grid.add_child(button)

func _on_equipment_slot_clicked(slot_enum: EquipmentComponent.EquipmentSlot) -> void:
	if selected_character_id.is_empty():
		return
	GameManager.unequip_item_for_character(selected_character_id, slot_enum)
	refresh_selected_character()
	_update_inventory_display()

func _on_inventory_item_clicked(item: Item) -> void:
	if selected_character_id.is_empty() or not item:
		return
	if not GameManager.all_characters.has(selected_character_id):
		return
	var character: CharacterData = GameManager.all_characters[selected_character_id]
	if not character:
		return

	if item.equipment_props:
		GameManager.equip_item_for_character(selected_character_id, item)
		refresh_selected_character()
		_update_inventory_display()
		return

	if item.consumable_props and character.stats:
		var stats := character.stats
		var props := item.consumable_props
		if props.health_change != 0:
			if props.health_change > 0:
				stats.heal(props.health_change)
			else:
				stats.take_damage(-props.health_change, 1.0)
		if props.mana_change != 0:
			stats.change_mana(props.mana_change)
		if props.satiety_change != 0:
			stats.change_satiety(props.satiety_change)

		if props.add_max_health != 0:
			stats.base_max_health += props.add_max_health
		if props.add_max_satiety != 0:
			stats.base_max_satiety += props.add_max_satiety
		if props.add_max_mana != 0:
			stats.base_max_mana += props.add_max_mana
		if props.add_attack != 0:
			stats.base_attack += props.add_attack
		if props.add_defense != 0:
			stats.base_defense += props.add_defense
		if props.add_base_speed != 0:
			stats.base_speed += props.add_base_speed

		GameManager.calculate_total_stats(selected_character_id)
		stats.current_health = clamp(stats.current_health, 0, stats.max_health)
		stats.current_mana = clamp(stats.current_mana, 0, stats.max_mana)
		stats.current_satiety = clamp(stats.current_satiety, 0, stats.max_satiety)
		GameManager.remove_item(item, 1)
		refresh_selected_character()
		_update_inventory_display()
		return

func _clear_portrait() -> void:
	for child in portrait_container.get_children():
		child.queue_free()

func _clear_equipment_grid() -> void:
	for child in equipment_grid.get_children():
		child.queue_free()

func _clear_stats_grid() -> void:
	for child in stats_grid.get_children():
		child.queue_free()

func _clear_skills_grid() -> void:
	for child in skills_grid.get_children():
		child.queue_free()

func _add_stat_row(label_text: String, value: int, bonus: int, max_value: int = -1) -> void:
	var name_label := Label.new()
	name_label.text = label_text
	stats_grid.add_child(name_label)

	var value_label := Label.new()
	if max_value >= 0 and bonus == 0:
		value_label.text = "%d / %d" % [value, max_value]
	elif bonus > 0:
		var base_value = value - bonus
		value_label.text = "%d (%d + %d)" % [value, base_value, bonus]
		value_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		value_label.text = str(value)
	stats_grid.add_child(value_label)

func _describe_skill(skill: Skill) -> String:
	var cost_text := ""
	match skill.cost_type:
		Skill.CostType.MANA:
			cost_text = "MP %d" % skill.cost
		Skill.CostType.SATIETY:
			cost_text = "Satiety %d" % skill.cost
		_:
			cost_text = "No cost"
	return "%s | %s" % [cost_text, skill.description]

func _format_slot_name(raw_name: String) -> String:
	var with_spaces := raw_name.capitalize().replace("_", " ")
	return with_spaces
