# scripts/DialogueConditionObjective.gd
@tool
class_name DialogueConditionObjective
extends DialogueCondition

@export var quest_id: String
@export var objective_index: int = 0
@export var require_completed: bool = true
@export var minimum_progress: int = 1

func is_met(context: Dictionary) -> bool:
	if quest_id.is_empty():
		return false
	var gm = GameManager
	if gm == null:
		return false
	var quest = gm.active_quests.get(quest_id)
	if quest == null:
		if require_completed and gm.completed_quests.has(quest_id):
			return true
		return false
	if objective_index < 0 or objective_index >= quest.objectives.size():
		return false
	var objective: QuestObjective = quest.objectives[objective_index]
	if require_completed:
		return objective.is_complete
	return objective.current_progress >= minimum_progress

func get_failure_reason(context: Dictionary) -> String:
	return "目标尚未完成" if require_completed else "目标进度不足"
