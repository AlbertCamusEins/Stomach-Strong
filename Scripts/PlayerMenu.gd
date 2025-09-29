extends CanvasLayer

@onready var panel_container: PanelContainer = $PanelContainer
@onready var adjust_button: Button = $"PanelContainer/MarginContainer/HBoxContainer/FormationPanel/AdjustButton"
@onready var combat_party_grid: GridContainer = $"PanelContainer/MarginContainer/HBoxContainer/FormationPanel/CombatPartyPanel/CombatPartyGrid"
@onready var reserve_party_grid: GridContainer = $"PanelContainer/MarginContainer/HBoxContainer/FormationPanel/ReservePartyPanel/ReservePartyGrid"
@onready var character_name_label: Label = $"PanelContainer/MarginContainer/HBoxContainer/DetailPanel/CharacterNameLabel"
@onready var stats_title_label: Label = $"PanelContainer/MarginContainer/HBoxContainer/DetailPanel/StatsPanel/VBoxContainer/StatsTitle"
@onready var stats_grid: GridContainer = $"PanelContainer/MarginContainer/HBoxContainer/DetailPanel/StatsPanel/VBoxContainer/StatsGrid"
@onready var close_button: Button = $"PanelContainer/MarginContainer/HBoxContainer/VBoxContainer3/CloseButton"

var adjust_mode := false
var selected_character_id: String = ""

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	set_process_unhandled_input(true)
	adjust_button.text = "Edit Formation"
	close_button.text = "Close"
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
	var toggle_actions := ["toggle_inventory", "toggle_party_screen"]
	if visible and event.is_action_pressed("exit"):
		close_menu()
		get_viewport().set_input_as_handled()
		return
	for action in toggle_actions:
		if event.is_action_pressed(action):
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

func refresh_party_lists() -> void:
	_populate_party_grid(combat_party_grid, GameManager.combat_party, true)
	_populate_party_grid(reserve_party_grid, GameManager.reserve_party, false)

func refresh_selected_character() -> void:
	if selected_character_id.is_empty() or not GameManager.all_characters.has(selected_character_id):
		character_name_label.text = "No Character Selected"
		stats_title_label.text = "Stats"
		_clear_stats_grid()
		return

	var character: CharacterData = GameManager.all_characters[selected_character_id]
	if not character:
		return

	GameManager.calculate_total_stats(selected_character_id)
	var stats: CharacterStats = character.stats
	character_name_label.text = character.character_name
	stats_title_label.text = "%s - Stats" % character.character_name
	_update_stats_display(stats)

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

func _clear_stats_grid() -> void:
	for child in stats_grid.get_children():
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
