# scripts/DialogueAction.gd
@tool
class_name DialogueAction
extends Resource

func execute(context: Dictionary) -> void:
	pass

func _get_game_manager(context: Dictionary):
	if context.has("game_manager") and context["game_manager"] != null:
		return context["game_manager"]
	if Engine.has_singleton("GameManager"):
		return GameManager
	return null

func _get_dialogue_manager(context: Dictionary):
	if context.has("dialogue_manager") and context["dialogue_manager"] != null:
		return context["dialogue_manager"]
	if Engine.has_singleton("DialogueManager"):
		return DialogueManager
	return null
