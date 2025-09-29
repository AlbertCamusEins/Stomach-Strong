# scripts/Quest.gd
@tool
class_name Quest extends Resource

# 任务的几种可能状态
enum QuestState {
	NOT_STARTED, # 未开始
	IN_PROGRESS, # 进行中
	COMPLETED    # 已完成
}

@export_group("基本信息")
@export var quest_id: String # 任务的唯一ID，例如 "village_chief_collect_apples"
@export var quest_name: String # 任务名称，例如 "村长的烦恼"
@export_multiline var description: String # 任务的详细描述

@export_group("目标与奖励")
@export var objectives: Array[QuestObjective] # 任务包含的所有目标
@export var item_rewards: Dictionary # 任务完成后给予的物品奖励
# 未来可以扩展其他奖励，比如金钱、经验值等

# --- 状态追踪 ---
# 这个变量将在游戏运行时被 GameManager 修改，我们不在编辑器里设置它
var current_state: QuestState = QuestState.NOT_STARTED

# 检查整个任务是否所有目标都已完成
func check_completion() -> bool:
	for objective in objectives:
		if not objective.is_complete:
			return false # 只要有一个目标未完成，整个任务就未完成
	return true
