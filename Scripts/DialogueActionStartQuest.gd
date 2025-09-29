# scripts/DialogueActionStartQuest.gd
@tool
class_name DialogueActionStartQuest
extends DialogueAction

@export var quest: Quest

func execute(context: Dictionary) -> void:
	if not quest:
		return
	var gm = _get_game_manager(context)
	if gm == null:
		return
	gm.start_quest(quest)
