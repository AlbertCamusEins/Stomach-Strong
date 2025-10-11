# scripts/NPC.gd
class_name NPC extends Area2D

# 当玩家与 NPC 互动时发出信号，传递对话资源和 NPC 实体
signal player_interacted(dialogue_resource, npc_node)

# 在编辑器中可以拖入 Dialogue 资源
@export var dialogue: Dialogue
@export var npc_id: String = ""

@onready var prompt_label: Label = $Label

func _ready():
	prompt_label.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	# 检查进入的是否是玩家
	if body is CharacterBody2D:
		prompt_label.show()

func _on_body_exited(body):
	if body is CharacterBody2D:
		prompt_label.hide()

func _unhandled_input(event: InputEvent):
	# 当提示显示时按下交互键，触发对话
	if prompt_label.visible and self.visible and event.is_action_pressed("ui_accepted"):
		if dialogue:
			emit_signal("player_interacted", dialogue, self)
			print("NPC 可交互，对话开始")
		else:
			print("警告：该 NPC 未配置对话资源")
