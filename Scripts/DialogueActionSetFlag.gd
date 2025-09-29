# scripts/DialogueActionSetFlag.gd
@tool
class_name DialogueActionSetFlag
extends DialogueAction

@export var flag_name: String
@export var value: bool = true

func execute(context: Dictionary) -> void:
	if flag_name.is_empty():
		return
	var gm = GameManager
	if gm:
		gm.set_dialogue_flag(flag_name, value)
	var dm = _get_dialogue_manager(context)
	if dm:
		dm.set_flag(flag_name, value)
	else:
		var flags: Dictionary = context.get("flags", {})
		flags[flag_name] = value
		context["flags"] = flags
