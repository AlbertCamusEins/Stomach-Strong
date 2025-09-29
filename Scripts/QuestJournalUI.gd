# scripts/QuestJournalUI.gd
class_name QuestJournalUI extends CanvasLayer

# --- 节点引用 ---
@onready var quest_list_container = $MainPanel/MarginContainer/HBoxContainer/QuestListPanel/ScrollContainer/QuestList
@onready var quest_name_label = $MainPanel/MarginContainer/HBoxContainer/DetailPanel/QuestNameLabel
@onready var quest_description_label = $MainPanel/MarginContainer/HBoxContainer/DetailPanel/QuestDescriptionLabel
@onready var objectives_list_container = $MainPanel/MarginContainer/HBoxContainer/DetailPanel/ObjectivesList



func _ready():
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.quest_progress_updated.connect(refresh_journal)

func _unhandled_input(event: InputEvent):
	# 检查玩家是否按下了我们定义的 "toggle_journal" 键
	if event.is_action_pressed("exit"):
		if visible:
			hide()
			get_tree().paused = false
	if event.is_action_pressed("toggle_journal"):
		# 如果界面可见，就隐藏它；如果隐藏，就显示它
		if visible:
			hide()
			get_tree().paused = false
		else:
			show()
			get_tree().paused = true
			# 每次显示时都刷新数据
			refresh_journal()
	
# --- 核心功能 ---
func refresh_journal():
	# 保存当前选中的任务ID，以便刷新后能重新选中
	var previously_selected_id = ""
	if objectives_list_container.get_child_count() > 0:
		# 这是一个小技巧，我们把任务ID暂存在name_label的元数据里
		previously_selected_id = quest_name_label.get_meta("quest_id", "")
	# 清空旧的任务列表
	for child in quest_list_container.get_children():
		child.queue_free()
		
	# 从 GameManager 获取当前所有激活的任务
	var active_quests = GameManager.active_quests.values()
	
	for quest in active_quests:
		var button = Button.new()
		button.text = quest.quest_name
		# 使用 lambda 函数连接信号，这样可以方便地传递 quest 参数
		button.pressed.connect(func(): _on_quest_selected(quest))
		quest_list_container.add_child(button)
	
	# 如果有任务，默认选中第一个
	#if not active_quests.is_empty():
		#_on_quest_selected(active_quests[0])
	#else:
		#_clear_details()

# --- 私有函数 ---
func _on_quest_selected(quest: Quest):
	quest_name_label.text = quest.quest_name
	quest_name_label.set_meta("quest_id", quest.quest_id) # 暂存ID
	quest_description_label.text = quest.description
	
	# 清空旧的目标列表
	for child in objectives_list_container.get_children():
		child.queue_free()
	
	# 填充新的目标
	for objective in quest.objectives:
		var objective_label = Label.new()
		var desc = objective.description if objective.description else "[目标描述未设置]"

		# [核心修改] 根据目标类型，显示不同的进度格式
		var progress_text = ""
		match objective.type:
			QuestObjective.ObjectiveType.COLLECT:
				progress_text = " (%d/%d)" % [objective.current_progress, objective.collect_quantity]
			QuestObjective.ObjectiveType.DEFEAT:
				progress_text = " (%d/%d)" % [objective.current_progress, objective.defeat_quantity]
		
		objective_label.text = "- " + desc + progress_text
		
		# 如果目标已完成，就把它变成绿色
		if objective.is_complete:
			objective_label.add_theme_color_override("font_color", Color.GREEN)
			
		objectives_list_container.add_child(objective_label)

func _clear_details():
	quest_name_label.text = "没有正在进行的任务"
	quest_description_label.text = ""
	for child in objectives_list_container.get_children():
		child.queue_free()
