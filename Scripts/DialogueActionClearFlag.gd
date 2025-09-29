# scripts/DialogueActionClearFlag.gd
@tool
class_name DialogueActionClearFlag
extends DialogueAction

@export var flag_name: String

func execute(context: Dictionary) -> void:
	if flag_name.is_empty():
		return
	var gm = _get_game_manager(context)
	if gm:
		gm.clear_dialogue_flag(flag_name)
	var dm = _get_dialogue_manager(context)
	if dm:
		dm.clear_flag(flag_name)
	else:
		if context.has("flags") and context["flags"].has(flag_name):
			context["flags"].erase(flag_name)
