# scripts/DialogueChoiceNode.gd
@tool
class_name DialogueChoiceNode
extends DialogueNode

@export var prompt: String = ""
@export var choices: Array[DialogueChoiceOption] = []

func get_choices() -> Array[DialogueChoiceOption]:
	return choices
