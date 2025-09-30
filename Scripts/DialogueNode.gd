# scripts/DialogueNode.gd
@tool
class_name DialogueNode
extends Resource

@export var node_id: String
@export var next_id: String = ""

func get_next_id() -> String:
	return next_id
