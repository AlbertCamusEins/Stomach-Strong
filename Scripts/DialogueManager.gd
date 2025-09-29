# scripts/DialogueManager.gd
extends Node

var conversation_context: Dictionary = {}
var temp_flags: Dictionary = {}

func begin_conversation(extra_context: Dictionary = {}) -> Dictionary:
	conversation_context = extra_context.duplicate(true) if extra_context else {}
	var existing_flags = conversation_context.get("flags", {})
	temp_flags = existing_flags.duplicate(true) if existing_flags is Dictionary else {}
	conversation_context["flags"] = temp_flags
	return conversation_context

func get_context() -> Dictionary:
	conversation_context["flags"] = temp_flags
	return conversation_context

func set_value(key: String, value) -> void:
	conversation_context[key] = value

func get_value(key: String, default = null):
	return conversation_context.get(key, default)

func set_flag(flag_name: String, value: bool = true) -> void:
	if flag_name.is_empty():
		return
	temp_flags[flag_name] = value
	conversation_context["flags"] = temp_flags

func get_flag(flag_name: String, default: bool = false) -> bool:
	if flag_name.is_empty():
		return default
	return temp_flags.get(flag_name, default)

func clear_flag(flag_name: String) -> void:
	if temp_flags.has(flag_name):
		temp_flags.erase(flag_name)

func get_flags() -> Dictionary:
	conversation_context["flags"] = temp_flags
	return temp_flags

func end_conversation() -> void:
	conversation_context.clear()
	temp_flags.clear()
