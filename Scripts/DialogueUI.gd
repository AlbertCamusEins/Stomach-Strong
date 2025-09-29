# scripts/DialogueUI.gd
class_name DialogueUI extends CanvasLayer

signal dialogue_finished
signal quest_started(quest_resource)

@onready var speaker_label: Label = $PanelContainer/MarginContainer/VBoxContainer/SpeakerLabel
@onready var text_label: RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/TextLabel
@onready var next_indicator: Button = $NextIndicator
@onready var choice_container: VBoxContainer = $ChoiceContainer

var current_dialogue: Dialogue
var current_node: DialogueNode
var node_map: Dictionary = {}
var is_displaying_text: bool = false
var typing_tween: Tween
var pending_full_text: String = ""
var use_legacy: bool = false
var legacy_lines: Array = []
var legacy_index: int = 0
var external_context: Dictionary = {}

func _ready():
	hide()
	next_indicator.disabled
	choice_container.hide()

func _unhandled_input(event: InputEvent):
	if not visible:
		return
	if event.is_action_pressed("ui_accept"):
		if is_displaying_text:
			_finish_typing()
		elif next_indicator.visible:
			_process_next()

func start_dialogue(dialogue_resource: Dialogue, extra_context: Dictionary = {}):
	if not dialogue_resource:
		push_error("start_dialogue called with null resource")
		return
	use_legacy = false
	legacy_lines = []
	legacy_index = 0
	external_context = extra_context if extra_context else {}
	current_dialogue = dialogue_resource
	node_map = dialogue_resource.get_node_map()
	if not node_map.is_empty() and not dialogue_resource.start_node_id.is_empty():
		_show_node(dialogue_resource.get_node(dialogue_resource.start_node_id))
	else:
		_show_legacy(dialogue_resource)
	show()

func _show_legacy(dialogue_resource: Dialogue):
	var lines = dialogue_resource.dialogue_lines
	if lines.is_empty():
		hide()
		return
	use_legacy = true
	legacy_lines = lines
	legacy_index = 0
	current_node = null
	choice_container.hide()
	next_indicator.show()
	_display_line(lines[legacy_index].get("speaker", "？？"), lines[legacy_index].get("text", "..."))
	current_dialogue.dialogue_lines = lines

func _show_node(node: DialogueNode):
	current_node = node
	var node_id = node.node_id if node and node.node_id else "<unknown>"
	print("[Dialogue] Enter node: %s (%s)" % [node_id, node.get_class()])
	if node is DialogueLineNode:
		_show_line(node)
	elif node is DialogueChoiceNode:
		_show_choice(node)
	elif node is DialogueActionNode:
		_execute_actions(node)
	elif node is DialogueConditionNode:
		_evaluate_condition(node)
	else:
		push_warning("Unsupported dialogue node type")
		_process_next_from(node)

func _show_line(line_node: DialogueLineNode):
	choice_container.hide()
	_display_line(line_node.speaker, line_node.text)

func _display_line(speaker: String, text: String):
	speaker_label.text = speaker
	_start_typing(text)

func _show_choice(choice_node: DialogueChoiceNode):
	choice_container.show()
	next_indicator.hide()
	speaker_label.text = choice_node.prompt
	text_label.text = ""
	_clear_choice_container()
	var context = _build_context()
	for option in choice_node.get_choices():
		var button := Button.new()
		button.text = option.text
		var info := {}
		var available = _evaluate_conditions(option.conditions, context, info)
		button.disabled = not available
		button.tooltip_text = info.get("reason", "") if not available else ""
		button.pressed.connect(_on_choice_selected.bind(option))
		choice_container.add_child(button)

func _execute_actions(action_node: DialogueActionNode):
	choice_container.hide()
	var context = _build_context()
	for action in action_node.actions:
		if action:
			action.execute(context)
	_process_next_from(action_node)

func _evaluate_condition(condition_node: DialogueConditionNode):
	choice_container.hide()
	var context = _build_context()
	var index := 0
	for branch in condition_node.branches:
		var info := {}
		var result = _evaluate_conditions(branch.conditions, context, info)
		#print("[Dialogue] Condition branch %d result: %s next=%s reason=%s" % [index, result, branch.next_id, info.get("reason", "")])
		if result:
			_process_next_by_id(branch.next_id)
			return
		index += 1
	#print("[Dialogue] Condition fallback -> %s" % condition_node.fallback_next_id)
	_process_next_by_id(condition_node.fallback_next_id)

func _start_typing(text: String):
	if typing_tween and typing_tween.is_valid():
		typing_tween.kill()
	typing_tween = create_tween()
	pending_full_text = text
	is_displaying_text = true
	text_label.text = ""
	next_indicator.hide()
	var duration = max(text.length() * 0.03, 0.1)
	typing_tween.tween_property(text_label, "text", text, duration)
	typing_tween.finished.connect(_on_typing_finished)

func _finish_typing():
	if typing_tween and typing_tween.is_valid():
		typing_tween.kill()
	typing_tween = null
	text_label.text = pending_full_text
	pending_full_text = ""
	is_displaying_text = false
	next_indicator.show()

func _on_typing_finished():
	typing_tween = null
	pending_full_text = ""
	is_displaying_text = false
	next_indicator.show()

func _process_next():
	if use_legacy:
		legacy_index += 1
		if legacy_index >= legacy_lines.size():
			_end_dialogue()
			return
		_display_line(legacy_lines[legacy_index].get("speaker", "？？"), legacy_lines[legacy_index].get("text", "..."))
		return
	if not current_node:
		_end_dialogue()
		return
	_process_next_from(current_node)

func _process_next_from(node: DialogueNode):
	if not node:
		_end_dialogue()
		return
	var next_id = node.get_next_id()
	if next_id.is_empty():
		_end_dialogue()
		return
	_process_next_by_id(next_id)

func _process_next_by_id(next_id: String):
	if next_id.is_empty():
		_end_dialogue()
		return
	var next_node = node_map.get(next_id)
	if not next_node:
		push_warning("Dialogue next node not found: %s" % next_id)
		_end_dialogue()
		return
	_show_node(next_node)

func _on_choice_selected(option: DialogueChoiceOption):
	var context = _build_context()
	if not _evaluate_conditions(option.conditions, context):
		return
	for action in option.actions:
		if action:
			action.execute(context)
	choice_container.hide()
	_process_next_by_id(option.next_id)

func _evaluate_conditions(conditions: Array, context = null, info = null) -> bool:
	var ctx = context if context != null else _build_context()
	var index := 0
	for condition in conditions:
		if not condition:
			index += 1
			continue
		var result = condition.is_met(ctx)
		if not result:
			var reason = condition.get_failure_reason(ctx)
			var identifier = condition.resource_path if condition.resource_path != "" else condition.get_class()
			if info != null:
				info["reason"] = reason
			return false
		index += 1
	return true

func _build_context() -> Dictionary:
	var gm = null
	if Engine.has_singleton("GameManager"):
		gm = GameManager
	var dm = null
	if Engine.has_singleton("DialogueManager"):
		dm = DialogueManager
	var flags: Dictionary = {}
	if gm and gm.dialogue_flags:
		flags = gm.dialogue_flags.duplicate() if gm.dialogue_flags else {}
	if dm:
		var dm_flags = dm.get_flags()
		for key in dm_flags.keys():
			flags[key] = dm_flags[key]
	var context := {
		"dialogue": current_dialogue,
		"node": current_node,
		"ui": self,
		"game_manager": gm,
		"dialogue_manager": dm,
		"active_quests": gm.active_quests if gm else {},
		"completed_quests": gm.completed_quests if gm else [],
		"inventory": gm.player_current_inventory if gm else [],
		"flags": flags
	}
	var extra_context := external_context if external_context else {}
	if dm:
		var dm_context = dm.get_context()
		if dm_context and dm_context.size() > 0:
			extra_context = dm_context
	if extra_context:
		for key in extra_context.keys():
			if key == "flags":
				var ext_flags = extra_context["flags"]
				if ext_flags is Dictionary:
					for fk in ext_flags.keys():
						flags[fk] = ext_flags[fk]
			else:
				context[key] = extra_context[key]
	return context

func _end_dialogue():
	hide()
	choice_container.hide()
	use_legacy = false
	legacy_lines = []
	legacy_index = 0
	external_context = {}
	if current_dialogue and current_dialogue.quest_to_start:
		emit_signal("quest_started", current_dialogue.quest_to_start)
	emit_signal("dialogue_finished")

func _clear_choice_container():
	for child in choice_container.get_children():
		child.queue_free()
