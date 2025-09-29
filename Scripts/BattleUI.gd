# ------------------------------------------------------------------
# scripts/BattleUI.gd
# 负责更新所有UI元素，不处理任何游戏逻辑。
# ------------------------------------------------------------------
class_name BattleUI extends Control

# 信号
signal attack_pressed
signal skill_pressed
signal item_pressed # 新增：当主“道具”按钮被点击时发出
signal defend_button_pressed
signal food_item_selected(food_item: Item) # 新增：当一个具体食物被选择时发出
signal skill_selected(skill: Skill)
signal weapon_selected(weapon: Item) #战斗中切换武器时发出
signal target_selected(target: Combatant)
signal targeting_cancelled
signal victory_loot_clicked(item: Item)
signal victory_confirmed

# 导出变量
@export var status_display_scene: PackedScene
@export var target_selector_scene: PackedScene
@export var spawn_offset: Vector2 = Vector2(0, -50) # 生成偏移：状态块中心向上50像素


# --- 节点引用 ---
# 使用 @onready 可以在场景准备好后立即获取节点引用，比 get_node() 更安全。
@onready var player_status_container: HBoxContainer = $MarginContainer/VBoxContainer/PlayerStatusContainer
@onready var enemy_status_container: HBoxContainer = $MarginContainer/VBoxContainer/EnemyStatusContainer

@onready var log_message_label: RichTextLabel = $MarginContainer/VBoxContainer/BattleLog
@onready var action_menu: PanelContainer = $MarginContainer/VBoxContainer/ActionMenu
@onready var attack_button = $MarginContainer/VBoxContainer/ActionMenu/HBoxContainer/AttackButton
@onready var skill_button = $MarginContainer/VBoxContainer/ActionMenu/HBoxContainer/SkillButton
@onready var defend_button = $MarginContainer/VBoxContainer/ActionMenu/HBoxContainer/DefendButton
@onready var item_button = $MarginContainer/VBoxContainer/ActionMenu/HBoxContainer/ItemButton

@onready var food_grid = $ItemMenu.find_child("FoodGrid")
@onready var weapon_grid = $ItemMenu.find_child("WeaponGrid")
@onready var item_menu = $ItemMenu

@onready var skill_menu = $SkillMenu
@onready var skill_list = skill_menu.find_child("SkillList")
@onready var victory_panel: VictoryPanel = $"../VictoryPanel"

var target_selector: PanelContainer
var is_targeting: bool = false
var valid_targets: Array[Combatant] = []
var current_target_index: int = 0

# [新增] 用一个字典来存储战斗单位和其对应的UI显示组件
var status_displays: Dictionary = {}

# 记录进入目标选择时 ActionMenu 的临时UI状态，便于恢复
var _action_menu_ui_state := {
	"alpha": 1.0,
	"mouse_filter": Control.MOUSE_FILTER_STOP,
	"buttons": []
}

func _ready():
	attack_button.pressed.connect(func(): emit_signal("attack_pressed"))
	skill_button.pressed.connect(func(): emit_signal("skill_pressed"))
	item_button.pressed.connect(func(): emit_signal("item_pressed"))
	defend_button.pressed.connect(func(): emit_signal("defend_button_pressed"))
	item_menu.hide() # 默认隐藏道具菜单
	skill_menu.hide()
		# [新增] 实例化目标指示器，并添加到场景中，但默认隐藏
	if target_selector_scene:
		target_selector = target_selector_scene.instantiate()
		add_child(target_selector)
		target_selector.hide()
	else:
		push_error("Target Selector Scene not set in BattleUI!")

	if victory_panel:
		victory_panel.hide_results()
		victory_panel.loot_clicked.connect(_on_victory_panel_loot_clicked)
		victory_panel.confirm_pressed.connect(_on_victory_panel_confirm_pressed)
	else:
		push_warning("VictoryPanel node not found in BattleUI.")

# 获取某个战斗单位对应的状态块（StatusDisplay）节点
func get_status_display(combatant: Combatant) -> StatusDisplay:
	if status_displays.has(combatant):
		var d = status_displays[combatant]
		if is_instance_valid(d):
			return d
	return null

# Helper：获取某个战斗单位状态块的全局矩形
func get_status_block_rect(combatant: Combatant) -> Rect2:
	var d: StatusDisplay = get_status_display(combatant)
	if d:
		return d.get_global_rect()
	return Rect2(Vector2.ZERO, Vector2.ZERO)

# Helper：获取某个战斗单位状态块在屏幕上的位置（中心点）
func get_status_block_position(combatant: Combatant) -> Vector2:
	var d: StatusDisplay = get_status_display(combatant)
	if d:
		# 使用全局矩形的中心点，适合用来放置指示器
		return d.get_global_rect().get_center()
	return Vector2.ZERO

# Helper：获取某个战斗单位状态块的尺寸
func get_status_block_size(combatant: Combatant) -> Vector2:
	return get_status_block_rect(combatant).size

# Helper：基于状态块中心 + 偏移，返回一个用于生成/对齐的点
func get_spawn_position_for(combatant: Combatant) -> Vector2:
	var center = get_status_block_position(combatant)
	if center == Vector2.ZERO:
		return center
	return center + spawn_offset

# 填充技能菜单
func populate_skill_menu(skills: Array[Skill]):
	for child in skill_list.get_children():
		child.queue_free()
	
	for skill in skills:
		var button = Button.new()
		# 显示技能名和消耗
		var cost_text = ""
		match skill.cost_type:
			Skill.CostType.MANA:
				cost_text = " (MP: %d)" % skill.cost
			Skill.CostType.SATIETY:
				cost_text = " (饱食: %d)" % skill.cost
		
		button.text = skill.skill_name + cost_text
		button.pressed.connect(_on_skill_button_pressed.bind(skill))
		skill_list.add_child(button)

# 当技能菜单中的按钮被点击
func _on_skill_button_pressed(skill: Skill):
	emit_signal("skill_selected", skill)
	skill_menu.hide()

# --- [新增] 核心目标选择函数 ---

func start_targeting(targets: Array[Combatant]):
	valid_targets = targets
	if valid_targets.is_empty():
		# 如果没有有效目标，立即取消
		cancel_targeting()
		return
		
	is_targeting = true
	current_target_index = 0
	_enter_targeting_ui_mode()
	target_selector.show()
	_update_selector_position()

func cancel_targeting():
	is_targeting = false
	if is_instance_valid(target_selector):
		target_selector.hide()
	_exit_targeting_ui_mode()
	emit_signal("targeting_cancelled")

func _update_selector_position():
	var target = valid_targets[current_target_index]
	var rect = get_status_block_rect(target)
	# 设置指示器大小与状态块一致，位置对齐到左上角
	if rect.size != Vector2.ZERO:
		# 尺寸在布局流程中可能需要延后设置
		target_selector.set_deferred("size", rect.size)
		target_selector.global_position = rect.position
	else:
		# 兜底：无法获取UI矩形时，保持原本的基于世界坐标的近似
		target_selector.global_position = target.global_position

# [新增] 在_unhandled_input中处理目标选择的输入
func _unhandled_input(event: InputEvent):
	if not is_targeting: return
	
	if event.is_action_pressed("ui_right"):
		current_target_index = (current_target_index + 1) % valid_targets.size()
		_update_selector_position()
	elif event.is_action_pressed("ui_left"):
		current_target_index = (current_target_index - 1 + valid_targets.size()) % valid_targets.size()
		_update_selector_position()
	elif event.is_action_pressed("ui_accept"):
		var selected_target = valid_targets[current_target_index]
		is_targeting = false
		target_selector.hide()
		_exit_targeting_ui_mode()
		emit_signal("target_selected", selected_target)
	elif event.is_action_pressed("ui_cancel"):
		cancel_targeting()

# 根据传入的武器数组，动态创建按钮并填充到武器菜单
func populate_weapon_grid(weapons: Array[Item]):
	for child in weapon_grid.get_children():
		child.queue_free()

	for weapon in weapons:
		var button = Button.new()
		button.text = weapon.item_name



# 新增：根据传入的食物数组，动态创建按钮并填充到菜单中
func populate_item_menu(food_items: Array[Item]):
	# 1. 先清空旧的按钮
	for child in food_grid.get_children():
		child.queue_free()
	
	# 2. 遍历食物数组，为每个食物创建一个新按钮
	for item in food_items:
		var button = Button.new()
		button.text = item.item_name
		# 关键：将按钮的 pressed 信号连接到一个处理函数上。
		# bind() 方法可以让我们在连接信号时传递额外的参数（这里是 food 对象本身）。
		button.pressed.connect(_on_food_button_pressed.bind(item))
		food_grid.add_child(button)

# 新增：当动态创建的食物按钮被点击时调用
func _on_food_button_pressed(food_item: Item):
	emit_signal("food_item_selected", food_item)
	item_menu.hide() # 选择后自动关闭菜单


func show_victory_screen(loot_data: Dictionary) -> void:
	if is_targeting:
		cancel_targeting()
	_close_combat_menus()
	show_action_menu(false)
	if victory_panel:
		victory_panel.show_results(loot_data)
	else:
		push_warning("VictoryPanel node missing; cannot display victory screen.")

func hide_victory_screen() -> void:
	if victory_panel:
		victory_panel.hide_results()

func mark_victory_loot_claimed(item_identifier: String) -> void:
	if victory_panel:
		victory_panel.mark_loot_collected_by_name(item_identifier)

func update_victory_loot_quantity(item_identifier: String, quantity: int) -> void:
	if victory_panel:
		victory_panel.update_loot_quantity(item_identifier, quantity)

func has_victory_panel() -> bool:
	return is_instance_valid(victory_panel)

func _close_combat_menus() -> void:
	item_menu.hide()
	skill_menu.hide()

func _on_victory_panel_loot_clicked(item: Item) -> void:
	emit_signal("victory_loot_clicked", item)

func _on_victory_panel_confirm_pressed() -> void:
	emit_signal("victory_confirmed")

# --- [核心新增] UI设置函数 ---
func setup_ui(
	player_party: Array[Combatant], 
	enemy_party: Array[Combatant],
	spacing: int = 24,
	player_align: int = BoxContainer.ALIGNMENT_BEGIN,
	enemy_align: int = BoxContainer.ALIGNMENT_BEGIN,
	item_min_width: int = 300
	):
	# 清空旧的UI
	for child in player_status_container.get_children(): child.queue_free()
	for child in enemy_status_container.get_children(): child.queue_free()
	status_displays.clear()
	
	# 配置两行容器（占满、分隔、对齐）
	_configure_row(player_status_container, spacing, player_align)
	_configure_row(enemy_status_container, spacing, enemy_align)

	# 生成状态块
	for member in player_party:
		var d: StatusDisplay = _create_status_display(member, player_status_container)
		if d:
			d.custom_minimum_size.x = item_min_width
			d.size_flags_horizontal = 0

	for member in enemy_party:
		var d: StatusDisplay = _create_status_display(member, enemy_status_container)
		if d:
			d.custom_minimum_size.x = item_min_width
			d.size_flags_horizontal = 0

	# 强制刷新状态显示
	player_status_container.queue_sort()
	enemy_status_container.queue_sort()

# --- [核心修改] 更新状态的函数 ---
func update_all_statuses():
	for combatant in status_displays:
		var display = status_displays[combatant]
		display.update_display(combatant)

# --- [核心修改] 日志函数 ---
func log_message(message: String):
	log_message_label.text = message
	print("[Battle Log] " + message) # 同时在后台打印，方便调试

# --- 辅助函数 ---
func _create_status_display(combatant: Combatant, container: Container):
	if not status_display_scene:
		push_error("Status Display Scene not set in BattleUI!")
		return
		
	var display = status_display_scene.instantiate() as StatusDisplay
	container.add_child(display)
	display.update_display(combatant)
	
	# 将战斗单位实例和其UI组件关联起来
	status_displays[combatant] = display	

# 显示或隐藏玩家的行动菜单
func show_action_menu(visible: bool):
	action_menu.visible = visible

# 统一配置行容器
func _configure_row(row: HBoxContainer, separation: int, align: int) -> void:
	row.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
	row.alignment = align
	row.add_theme_constant_override("separation", separation)

# --- 菜单开关（供 BattleManager 调用） ---
func open_item_menu(items: Array[Item]):
	if item_menu.visible:
		item_menu.hide()
		return
	populate_item_menu(items)
	item_menu.show()

func open_skill_menu(skills: Array[Skill]):
	if skill_menu.visible:
		skill_menu.hide()
		return
	populate_skill_menu(skills)
	skill_menu.show()

# --- 目标选择期的 UI 管理（方案一） ---
func _enter_targeting_ui_mode():
	# 保持 ActionMenu 在布局中的占位，但变为不可见/不可交互
	# 记录旧状态
	_action_menu_ui_state.alpha = action_menu.modulate.a
	_action_menu_ui_state.mouse_filter = action_menu.mouse_filter
	_action_menu_ui_state.buttons = []
	var btns = [attack_button, skill_button, defend_button, item_button]
	for b in btns:
		_action_menu_ui_state.buttons.append({
			"ref": b,
			"disabled": b.disabled,
			"focus_mode": b.focus_mode
		})

	# 应用目标选择期的外观与输入策略
	var c: Color = action_menu.modulate
	c.a = 0.0 # 完全透明；如需半透明可改为 0.2
	action_menu.modulate = c
	action_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for b in btns:
		b.disabled = true
		b.focus_mode = Control.FOCUS_NONE
		b.release_focus()

func _exit_targeting_ui_mode():
	# 恢复 ActionMenu 的外观与输入设置
	var c: Color = action_menu.modulate
	c.a = float(_action_menu_ui_state.alpha)
	action_menu.modulate = c
	action_menu.mouse_filter = int(_action_menu_ui_state.mouse_filter)
	for entry in _action_menu_ui_state.buttons:
		var b: Button = entry.ref
		if is_instance_valid(b):
			b.disabled = bool(entry.disabled)
			b.focus_mode = int(entry.focus_mode)
