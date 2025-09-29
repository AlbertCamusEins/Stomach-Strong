# scripts/Dialogue.gd
@tool
class_name Dialogue
extends Resource


@export_group("Legacy")
@export var dialogue_lines: Array[Dictionary] = []

@export_group("Graph")
@export var start_node_id: String = ""
@export var nodes: Array[DialogueNode] = []

@export_group("Quest Integration")
@export var quest_to_start: Quest

func get_node_map() -> Dictionary:
	var map: Dictionary = {}
	for node in nodes:
		if node == null:
			continue
		var id = String(node.node_id)
		if id.is_empty():
			push_warning("Dialogue node missing node_id")
			continue
		if map.has(id):
			push_warning("Duplicate dialogue node id: %s" % id)
			continue
		map[id] = node
	return map

func get_node(node_id: String) -> DialogueNode:
	if node_id.is_empty():
		return null
	return get_node_map().get(node_id, null)
