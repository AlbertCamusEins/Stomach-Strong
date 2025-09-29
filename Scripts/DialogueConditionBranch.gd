# scripts/DialogueConditionBranch.gd
@tool
class_name DialogueConditionBranch
extends Resource

@export var conditions: Array[DialogueCondition] = []
@export var next_id: String = ""
