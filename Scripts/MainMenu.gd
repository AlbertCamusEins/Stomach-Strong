# scripts/MainMenu.gd
# 主菜单的控制脚本
extends Control

@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var new_game_button: Button = $VBoxContainer/NewGameButton

func _ready():
	# 检查是否存在存档文件
	if GameManager.has_save_file():
		# 如果有，让“继续游戏”按钮可以点击
		continue_button.disabled = false
	else:
		# 如果没有，禁用“继续游戏”按钮
		continue_button.disabled = true
	
	# 连接按钮信号
	continue_button.pressed.connect(_on_continue_button_pressed)
	new_game_button.pressed.connect(_on_new_game_button_pressed)

func _on_continue_button_pressed():
	# 调用 GameManager 的函数来加载游戏
	GameManager.continue_game()

func _on_new_game_button_pressed():
	# 调用 GameManager 的函数来开始新游戏
	GameManager.new_game()
