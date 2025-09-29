# scripts/DialogueConditionNode.gd
@tool
class_name DialogueConditionNode
extends DialogueNode

@export var branches: Array[DialogueConditionBranch] = []
@export var fallback_next_id: String = ""

func get_next_id() -> String:
	return fallback_next_id
