# scripts/DialogueChoiceOption.gd
@tool
class_name DialogueChoiceOption
extends Resource

@export var text: String = ""
@export var next_id: String = ""
@export var conditions: Array[DialogueCondition] = []
@export var actions: Array[DialogueAction] = []
