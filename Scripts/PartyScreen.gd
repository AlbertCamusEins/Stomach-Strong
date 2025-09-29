# scripts/PartyScreen.gd
# 控制队伍界面的显示、数据刷新和编队调整
class_name PartyScreen extends CanvasLayer

# --- 节点引用 ---
@onready var combat_party_grid: GridContainer = $MainPanel/MarginContainer/HBoxContainer/FormationPanel/CombatPartyPanel/CombatPartyGrid
@onready var reserve_party_grid: GridContainer = $MainPanel/MarginContainer/HBoxContainer/FormationPanel/ReservePartyPanel/ReservePartyGrid
@onready var character_name_label: Label = $MainPanel/MarginContainer/HBoxContainer/DetailPanel/CharacterNameLabel
@onready var adjust_button: Button = $MainPanel/MarginContainer/HBoxContainer/FormationPanel/AdjustButton
@onready var close_button: Button = $MainPanel/MarginContainer/HBoxContainer/DetailPanel/CloseButton
# 这里我们假设详情面板里有一个专门放属性的GridContainer
@onready var stats_grid: GridContainer = $MainPanel/MarginContainer/HBoxContainer/DetailPanel/StatsPanel/VBoxContainer/StatsGrid

# --- 状态变量 ---
var is_adjusting: bool = false # 当前是否处于“调整编队”模式
var selected_character: CharacterData # 当前在详情页显示的角色

func _ready():
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	adjust_button.pressed.connect(_on_adjust_button_pressed)
	close_button.pressed.connect(close_screen)

# --- 公共函数 ---
func open_screen():
	show()
	get_tree().paused = true
	# 每次打开时，都确保处于非编辑模式
	_exit_adjust_mode() 
	refresh_data()

func close_screen():
	hide()
	get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("exit"):
		if visible:
			close_screen()
	
	if event.is_action_pressed("toggle_party_screen"):
		if visible:
			close_screen()
		else:
			open_screen()
		

# --- 核心刷新与交互 ---
func refresh_data():
	# 从GameManager获取最新数据
	var all_chars = GameManager.all_characters
	var combat_ids = GameManager.combat_party
	var reserve_ids = GameManager.reserve_party
	
	# 分别刷新两个编队
	_populate_party_grid(combat_party_grid, combat_ids, all_chars)
	_populate_party_grid(reserve_party_grid, reserve_ids, all_chars)
	
	# 刷新详情面板
	_update_details()

func _populate_party_grid(grid: GridContainer, id_list: Array[String], all_chars: Dictionary):
	# 清空旧的按钮
	for child in grid.get_children():
		child.queue_free()
	
	# 根据ID列表创建新的角色按钮
	for char_id in id_list:
		var character = all_chars.get(char_id)
		if character:
			var button = Button.new()
			button.text = character.character_name
			# 使用 .bind() 来传递角色数据
			button.pressed.connect(_on_character_button_pressed.bind(character))
			grid.add_child(button)

func _on_character_button_pressed(character: CharacterData):
	if is_adjusting:
		# --- 编辑模式下的逻辑 ---
		# 判断这个角色当前在哪个队伍
		if GameManager.combat_party.has(character.character_id):
			GameManager.move_character_to_reserve(character.character_id)
		elif GameManager.reserve_party.has(character.character_id):
			# 这里可以添加逻辑，比如战斗编队人数已满的提示
			if GameManager.combat_party.size() < 4: # 假设最大战斗人数为4
				GameManager.move_character_to_combat(character.character_id)
			else:
				print("战斗编队已满！")
		
		# 移动后立即刷新整个界面
		refresh_data()
	else:
		# --- 普通模式下的逻辑 ---
		selected_character = character
		_update_details()

func _on_adjust_button_pressed():
	is_adjusting = not is_adjusting
	
	if is_adjusting:
		_enter_adjust_mode()
	else:
		_exit_adjust_mode()

# --- 辅助函数 ---
func _enter_adjust_mode():
	adjust_button.text = "完成"
	# 可以给详情面板加上一个遮罩或者提示，表明当前正在编辑
	character_name_label.text = "请点击队员来调整编队"
	# 清空属性显示
	for child in stats_grid.get_children():
		child.queue_free()

func _exit_adjust_mode():
	is_adjusting = false
	adjust_button.text = "调整编队"
	# 恢复详情显示
	_update_details()

func _update_details():
	# 如果没有选中任何角色，就显示默认提示
	if not is_instance_valid(selected_character):
		character_name_label.text = "请选择一个角色"
		for child in stats_grid.get_children():
			child.queue_free()
		return
	
	character_name_label.text = selected_character.character_name
	
	# --- 更新属性显示 ---
	# (这里的逻辑和 StatusScreen.gd 中的 update_stats 完全一样)
	var stats = selected_character.stats
	for child in stats_grid.get_children():
		child.queue_free()
	
	# 为了简洁，我们只显示几个核心属性作为示例
	_add_stat_entry("最大生命", stats.max_health)
	_add_stat_entry("攻击力", stats.attack)
	_add_stat_entry("防御力", stats.defense)
	# ... 你可以添加更多属性

func _add_stat_entry(stat_name: String, value: int):
	var name_label = Label.new()
	name_label.text = stat_name
	var value_label = Label.new()
	value_label.text = str(value)
	stats_grid.add_child(name_label)
	stats_grid.add_child(value_label)
