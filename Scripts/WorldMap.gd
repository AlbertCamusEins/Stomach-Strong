# scripts/WorldMap.gd
extends Node2D

# --- 节点引用 ---
# 引用烹饪UI
@onready var cooking_ui: CanvasLayer = $UI/CookingUi
# 引用玩家角色控制其移动
@onready var player: CharacterBody2D = $Ysort/Character
# 引用对话UI
@onready var dialogue_ui: CanvasLayer = $UI/DialogueUI
# 引用任务面板UI
@onready var quest_journal_ui: CanvasLayer = $UI/QuestJournalUI


# --- 导出变量 ---
@export var enemy_in_area: CharacterStats
@export var encounter_in_area: Encounter

# [新增] 存储当前正在交互的NPC
var current_interacting_npc: NPC = null

func _ready():
	# --- 烹饪逻辑 ---
	# 找到场景中所有属于"CookingSpots" 分组的炊点
	var cooking_spots = get_tree().get_nodes_in_group("CookingSpots")
	for spot in cooking_spots:
		# 将每一个炊点的 "player_interacted" 信号连接到我们的处理函数
		spot.player_interacted.connect(_on_cooking_spot_interacted)

	# 对话逻辑：注册所有 NPC 的交互
	var npcs = get_tree().get_nodes_in_group("NPCs")
	for npc in npcs:
		npc.player_interacted.connect(_on_npc_interacted)

	dialogue_ui.dialogue_finished.connect(_on_dialogue_finished)
	# 连接任务开始信号
	dialogue_ui.quest_started.connect(_on_quest_started_from_dialogue)

# --- 信号处理函数 ---

# 烹饪交互处理
func _on_cooking_spot_interacted(spot, cookware_component):
	cooking_ui.open_cooking_menu(cookware_component)

# NPC 交互处理
func _on_npc_interacted(dialogue_resource: Dialogue, npc_node: NPC):
	player.can_move = false
	current_interacting_npc = npc_node
	var dialogue_context := {
		"npc": npc_node,
		"npc_id": npc_node.npc_id if not npc_node.npc_id.is_empty() else npc_node.name
	}
	if Engine.has_singleton("DialogueManager"):
		dialogue_context = DialogueManager.begin_conversation(dialogue_context)
	dialogue_ui.start_dialogue(dialogue_resource, dialogue_context)


# 对话结束
func _on_dialogue_finished():
	player.can_move = true
	if Engine.has_singleton("DialogueManager"):
		DialogueManager.end_conversation()

# 任务开始
func _on_quest_started_from_dialogue(quest: Quest):
	GameManager.start_quest(quest)
