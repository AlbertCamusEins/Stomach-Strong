@tool # 添加 @tool 注解以便在编辑器中更好地支持枚举
extends PopupMenu
class_name ItemActionMenu

## 当一个菜单动作被选择时发出。
## @param action: Action枚举值，表示选择了哪个动作。
## @param item:   与菜单关联的物品对象。
## @param context: 调用时传入的额外上下文信息。
signal action_selected(action: Action, item: Item, context: Dictionary)

## 使用枚举（enum）来定义所有可能的动作。
## 这比使用不直观的数字ID（0, 1, 2...）更安全、更易读、更易维护。
enum Action {
	CONSUME,
	EQUIP,
	ADD_TO_SHORTCUT,
	UNEQUIP,
	DROP,
	PLACE_TRAP
}

@export var default_actions: Array[StringName] = [
	&"consume",
	&"equip",
	&"add_to_shortcut",
	&"drop"
]

# 使用常量字典来映射动作的 StringName 和对应的显示文本。
const ACTION_LABELS := {
	&"consume": "食用",
	&"equip": "装备",
	&"add_to_shortcut": "添加到快捷栏",
	&"remove_from_shortcut": "从快捷栏移除",
	&"unequip": "卸下",
	&"drop": "丢弃",
	&"place_trap": "放置陷阱"
}

# 使用常量字典来映射动作的 StringName 和对应的枚举值。
const ACTION_ENUM_MAP := {
	&"consume": Action.CONSUME,
	&"equip": Action.EQUIP,
	&"add_to_shortcut": Action.ADD_TO_SHORTCUT,
	&"unequip": Action.UNEQUIP,
	&"drop": Action.DROP,
	&"place_trap": Action.PLACE_TRAP
}

var _current_item: Item = null
var _current_context: Dictionary = {}


func _ready() -> void:
	self.hide()
	# 连接内置的 id_pressed 信号到我们的处理函数
	id_pressed.connect(_on_id_pressed)
	about_to_popup.connect(_on_about_to_popup)

func _on_about_to_popup() -> void:
	# 弹出时确保能接收键盘事件，并初始化一个有效索引
	grab_focus()
	if get_focused_item() < 0 and get_item_count() > 0:
		_select_first_valid(1)

## 调用此函数，为指定的物品在特定位置打开操作菜单。
func open_with_item(item: Item, global_pos: Vector2, extra_actions: Array[StringName] = [], context: Dictionary = {}) -> void:
	# 确保传入的 item 是一个有效的对象
	if not is_instance_valid(item):
		return

	_current_item = item
	_current_context = context
	
	clear()
	
	# 合并默认操作和额外的操作，并确保没有重复项
	var actions_to_show: Array[StringName] = default_actions.duplicate()
	for action in extra_actions:
		if not actions_to_show.has(action):
			actions_to_show.append(action)
	
	# 根据物品的属性，动态填充菜单项
	_populate_menu(actions_to_show)
	
	# 如果没有任何可用的操作，则不显示菜单
	if get_item_count() == 0:
		return
	
	# 设置菜单位置并弹出
	self.position = global_pos
	popup()

# 用自定义动作上下移动与确认
func _unhandled_key_input(event: InputEvent) -> void:
	if not visible:
		return
	# 仅当本控件拥有焦点或鼠标在其上时接管（避免误吸键）
	if not has_focus():
		return
	
	if event.is_action_pressed("menu_up"):
		_move_selection(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("menu_down"):
		_move_selection(1)
		get_viewport().set_input_as_handled()

# 内部函数，根据有效操作列表来填充菜单
func _populate_menu(actions: Array[StringName]) -> void:
	for action_name in actions:
		# 根据物品的属性判断是否应该添加这个操作
		var should_add: bool = false
		match action_name:
			&"consume":
				# 仅当物品有 "consumable_props" 属性且不为 null 时，才显示“食用”
				should_add = _current_item.consumable_props != null
			&"equip":
				# 仅当物品有 "equipment_props" 属性且不为 null 时，才显示“装备”
				should_add = _current_item.equipment_props != null
			&"add_to_shortcut", &"drop", &"unequip", &"place_trap":
				# 假设这些操作总是可用的，你可以根据需要添加更复杂的判断逻辑
				# 例如，对 "unequip"，你可能需要检查物品当前是否真的处于装备状态
				should_add = true
			_:
				# 忽略任何未知的操作
				printerr("Unknown item action: ", action_name)
				should_add = false
		
		# 如果确定要添加此操作，则创建菜单项
		if should_add:
			# 确保此操作在我们的字典中有定义
			if ACTION_LABELS.has(action_name) and ACTION_ENUM_MAP.has(action_name):
				var label: String = ACTION_LABELS[action_name]
				var action_id: Action = ACTION_ENUM_MAP[action_name] # ID现在是我们的枚举值
				add_item(label, action_id)


# 当菜单项被点击时，此函数会被调用
func _on_id_pressed(id: int) -> void:
	if not is_instance_valid(_current_item):
		return
	
	# 此处的 'id' 现在是我们的 Action 枚举值
	# 我们直接将枚举、物品和上下文信息一起发射出去，使信号的接收方处理起来更方便
	action_selected.emit(id, _current_item, _current_context)
	# PopupMenu 默认在点击后会自动隐藏，所以 hide() 调用是可选的


# —— 辅助：键盘导航 —— #

func _move_selection(dir: int) -> void:
	if get_item_count() == 0:
		return
	
	var idx = get_focused_item()
	if idx < 0:
		_select_first_valid(dir)
		return
	
	var count = get_item_count()
	var tries = 0
	while tries < count:
		idx = (idx + dir + count) % count
		if not is_item_separator(idx) and not is_item_disabled(idx):
			_set_current_index_safe(idx)
			return
		tries = tries + 1

func _select_first_valid(dir: int) -> void:
	var count = get_item_count()
	if count == 0:
		return
	# dir > 0 时从头到尾；dir < 0 时从尾到头
	var i = 0
	while i < count:
		var idx = i if dir > 0 else (count - 1 - i)
		if not is_item_separator(idx) and not is_item_disabled(idx):
			_set_current_index_safe(idx)
			return
		i = i + 1

func _set_current_index_safe(idx: int) -> void:
	set_focused_item(idx)
	grab_focus()
