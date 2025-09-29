# scripts/DialogueConditionFlag.gd
@tool
class_name DialogueConditionFlag
extends DialogueCondition

@export var flag_name: String
@export var expected_value: bool = true
@export var require_existence: bool = true

func is_met(context: Dictionary) -> bool:
	if flag_name.is_empty():
		return not require_existence
	var gm = GameManager
	var flags: Dictionary = {}
	var dm = context.get("dialogue_manager", null)
	if dm:
		flags = dm.get_flags()
	elif gm != null:
		flags = gm.dialogue_flags
	elif context.has("flags"):
		flags = context["flags"]
	if not flags.has(flag_name):
		return (not require_existence) or (not expected_value)
	return flags.get(flag_name, false) == expected_value

func get_failure_reason(context: Dictionary) -> String:
	return "条件旗标未满足"
