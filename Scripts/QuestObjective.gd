# scripts/QuestObjective.gd
@tool
class_name QuestObjective extends Resource

# 定义任务目标的类型
enum ObjectiveType {
	COLLECT,  # 收集物品
	DEFEAT,   # 击败敌人
	TALK_TO   # 与NPC交谈
}

@export var type: ObjectiveType
@export var description: String # 任务面板中显示的目标描述，例如“收集 5 个苹果”

# --- 根据不同类型所需的数据 ---
@export_group("收集目标")
@export var item_to_collect: Item
@export var collect_quantity: int = 1

@export_group("击败目标")
# 我们用 CharacterStats 来定义敌人类型
@export var enemy_to_defeat: CharacterStats
@export var defeat_quantity: int = 1

@export_group("交谈目标")
# 我们用一个字符串ID来标识NPC
@export var npc_id_to_talk: String

# --- 进度追踪 ---
@export var current_progress: int = 0
@export var is_complete: bool = false

# 一个辅助函数，用来检查目标是否完成
func check_completion():
	var required_quantity = 0
	match type:
		ObjectiveType.COLLECT:
			required_quantity = collect_quantity
		ObjectiveType.DEFEAT:
			required_quantity = defeat_quantity
		ObjectiveType.TALK_TO:
			# 交谈任务通常只需要一次
			required_quantity = 1
			
	if current_progress >= required_quantity:
		is_complete = true
	else:
		is_complete = false
	return is_complete
