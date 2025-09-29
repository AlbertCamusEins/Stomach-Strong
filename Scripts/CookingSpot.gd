# scripts/CookingSpot.gd
class_name CookingSpot extends Area2D

# 这个信号会在玩家与炊点交互时发出
signal player_interacted(spot, cookware_component)

# 导出变量，让我们可以为每个炊点单独设置它提供的厨具
# 例如，一个篝火可能提供“烤架”，而一个炉灶可能提供“铁锅”
@export var provided_cookware: Item

@onready var prompt_label: Label = $Label

func _ready():
	# 游戏开始时先隐藏提示
	prompt_label.hide()
	# 将身体进入和离开的信号连接到处理函数上
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	# 检查进入的是否是玩家角色
	# 假设你的玩家角色场景根节点挂载了 Character.gd 脚本
	if body is CharacterBody2D and body.is_in_group("Player"):
		prompt_label.show()

func _on_body_exited(body):
	if body is CharacterBody2D:
		prompt_label.hide()

func _unhandled_input(event: InputEvent):
	# 检查玩家是否按下了交互键，并且有角色在区域内
	if prompt_label.visible and event.is_action_pressed("ui_accepted"):
		# "ui_accept" 默认是空格键或回车键，你也可以在项目设置里改成 E 键
		print("玩家与炊点交互！")
		
		if provided_cookware and provided_cookware.cookware_props:
			emit_signal("player_interacted", self, provided_cookware.cookware_props)
		else:
			emit_signal("player_interacted", self, null)
