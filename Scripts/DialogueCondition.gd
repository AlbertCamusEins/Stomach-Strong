# scripts/DialogueCondition.gd
@tool
class_name DialogueCondition
extends Resource

func is_met(context: Dictionary) -> bool:
	return true

func get_failure_reason(context: Dictionary) -> String:
	return ""

func _get_game_manager(context: Dictionary):
	if context.has("game_manager") and context["game_manager"] != null:
		return context["game_manager"]
	if Engine.has_singleton("GameManager"):
		return GameManager
	return null
