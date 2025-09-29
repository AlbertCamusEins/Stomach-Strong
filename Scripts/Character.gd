# Character.gd
# 挂载到玩家角色节点 (例如一个 CharacterBody2D)

extends CharacterBody2D

# 玩家的移动速度，可以稍后在编辑器中调整
@export var speed = 150.0
var can_move = true
var last_direction = Vector2(1,0)
@onready var anim_sprite = $AnimatedSprite2D

func _ready():
	# When the player is ready on the map, allow movement.
	# call_deferred ensures this runs after the GameManager has placed the player.
	call_deferred("enable_movement")
	set_idle_animation()
	
func enable_movement():
	can_move = true

func _physics_process(_delta):
	if not can_move:
		velocity = Vector2.ZERO
		return
	# 获取玩家的输入（支持方向键和WASD）
	# 这会返回一个标准化的向量，代表移动方向
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	# 根据输入方向和速度计算角色的速度
	# 如果没有输入，velocity 会是 (0, 0)
	if direction != Vector2.ZERO:
		last_direction = direction
	
	velocity = direction * speed
	move_and_slide()
	# 更新动画
	update_animation(direction)


func update_animation(direction):
	
	if direction != Vector2.ZERO:
		if direction.x > 0:
			anim_sprite.play("walk_right")
		elif direction.x < 0:
			anim_sprite.play("walk_left")
		elif direction.y > 0:
			anim_sprite.play("walk_down")
		elif direction.y < 0:
			anim_sprite.play("walk_up")
	else:
		set_idle_animation()

func set_idle_animation():
	# 首先，播放 "idle" 动画
	anim_sprite.animation = "idle"
	anim_sprite.stop()
	# 然后，根据记录的最后一个移动方向 last_direction 来设置具体的帧
	# 这个判断逻辑的优先级应该和你播放行走动画的优先级保持一致
	if last_direction.x > 0:       # 最后是向右
		anim_sprite.frame = 0
	elif last_direction.x < 0:     # 最后是向左
		anim_sprite.frame = 1
	elif last_direction.y > 0:     # 最后是向下
		anim_sprite.frame = 2      # 对应 idle 第3帧
	elif last_direction.y < 0:     # 最后是向上
		anim_sprite.frame = 3      # 对应 idle 第4帧
