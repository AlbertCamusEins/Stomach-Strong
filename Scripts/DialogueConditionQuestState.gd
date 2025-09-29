# scripts/DialogueConditionQuestState.gd
@tool
class_name DialogueConditionQuestState
extends DialogueCondition

@export var quest_id: String
@export var required_state: Quest.QuestState = Quest.QuestState.IN_PROGRESS

func is_met(context: Dictionary) -> bool:
	print("start to check quest state")
	if quest_id.is_empty():
		print("no quests")
		return false
	var gm = GameManager
	if gm != null:
		return gm.get_quest_state(quest_id) == required_state
	var active = context.get("active_quests", {})
	var completed = context.get("completed_quests", [])
	match required_state:
		Quest.QuestState.IN_PROGRESS:
			return active.has(quest_id)
		Quest.QuestState.COMPLETED:
			if completed is Array:
				return completed.has(quest_id)
			return false
		Quest.QuestState.NOT_STARTED:
			var in_active = active.has(quest_id) if active is Dictionary else false
			var in_completed = completed.has(quest_id) if completed is Array else false
			return not in_active and not in_completed
	return false

func get_failure_reason(context: Dictionary) -> String:
	return "任务状态不满足"
