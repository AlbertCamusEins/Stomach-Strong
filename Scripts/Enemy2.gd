extends CharacterBody2D

# 使用枚举来定义所有可能的状态
enum State { SLEEPING, WAKING_UP, WANDERING, FLEEING }

# -- 导出变量 --
@export var wander_speed: float = 10.0
@export var flee_speed: float = 25.0 # 逃跑时应该更快
@export var wander_radius: float = 100.0
@export var side_step_factor: float = 0.5

# -- 节点引用 --
@onready var birth_trigger_radius: Area2D = $BirthTriggerArea
@onready var fear_area: Area2D = $FearArea # 新增：恐惧范围的引用
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

# -- 状态和变量 --
var current_state: State = State.SLEEPING # 当前状态，默认为沉睡
var start_position: Vector2
var wander_target: Vector2
var player_ref = null # 用于存储玩家的引用
var is_player_in_fear_area: bool = false

func _ready() -> void:
	start_position = global_position
	
	# 连接所有需要的信号
	birth_trigger_radius.body_entered.connect(_on_birth_trigger_area_body_entered)
	birth_trigger_radius.body_exited.connect(_on_birth_trigger_area_body_exited)
	fear_area.body_entered.connect(_on_fear_area_body_entered)
	fear_area.body_exited.connect(_on_fear_area_body_exited)
	
	# 连接动画完成信号，用于状态转换
	anim_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	# 使用 match 语句根据当前状态执行不同逻辑，非常清晰
	match current_state:
		State.SLEEPING:
			velocity = Vector2.ZERO
			# 确保动画停止
			if anim_sprite.is_playing() and anim_sprite.animation != "birth":
				anim_sprite.stop()
		
		State.WAKING_UP:
			# 醒来时不动，等待动画播放完毕
			velocity = Vector2.ZERO
		
		State.WANDERING:
			if is_player_in_fear_area:
				if not player_ref.velocity == Vector2.ZERO:
					current_state = State.FLEEING
			# 执行游荡逻辑
			var direction = global_position.direction_to(wander_target)
			velocity = direction * wander_speed
			move_and_slide()
			# 确保播放行走动画
			if not anim_sprite.is_playing() or anim_sprite.animation != "walk":
				anim_sprite.play("walk")
			
			if global_position.distance_to(wander_target) < 5.0:
				_pick_new_wander_target()
		
		State.FLEEING:
			# 如果玩家实例无效（比如场景切换），则返回游荡状态
			if not is_instance_valid(player_ref):
				current_state = State.WANDERING
				return
				
			var flee_direction: Vector2
			# 计算从玩家指向自己的方向，然后朝这个方向移动
			var away_direction = player_ref.global_position.direction_to(global_position)
			var side_direction = away_direction.orthogonal()
			flee_direction = (away_direction + side_direction * side_step_factor).normalized()
			velocity = flee_direction * flee_speed
			move_and_slide()
			# 逃跑时也播放行走（或奔跑）动画
			if not anim_sprite.is_playing() or anim_sprite.animation != "walk":
				anim_sprite.play("walk")


# --- 信号处理函数 ---

# 大范围触发
func _on_birth_trigger_area_body_entered(body):
	if body.is_in_group("Player"):
		player_ref = body # 存储玩家引用
		if current_state == State.SLEEPING:
			current_state = State.WAKING_UP
			anim_sprite.animation = "birth"
			anim_sprite.speed_scale = 1.0
			anim_sprite.play()

func _on_birth_trigger_area_body_exited(body):
	if body.is_in_group("Player"):
		player_ref = null # 清除玩家引用
		current_state = State.SLEEPING
		if anim_sprite.animation == "birth":
			anim_sprite.speed_scale = -1.0
			anim_sprite.play()
		else:
			anim_sprite.animation = "birth"
			anim_sprite.frame = 10
			anim_sprite.speed_scale = -1.0
			anim_sprite.play()

# 小范围（恐惧范围）触发
func _on_fear_area_body_entered(body):
	if body.is_in_group("Player"):
		is_player_in_fear_area = true
		if body.velocity == Vector2.ZERO:
			return
		# 只有在游荡时被靠近才会进入逃跑状态
		if current_state == State.WANDERING:
			current_state = State.FLEEING

func _on_fear_area_body_exited(body):
	if body.is_in_group("Player"):
		is_player_in_fear_area = false
		# 只有在逃跑时，玩家离开范围才返回游荡状态
		if current_state == State.FLEEING:
			current_state = State.WANDERING
			_pick_new_wander_target()

# 动画播放完成时
func _on_animation_finished():
	# 当"birth"动画正向播放完毕后，从 WAKING_UP 转换到 WANDERING
	if anim_sprite.animation == "birth" and anim_sprite.speed_scale > 0:
		if current_state == State.WAKING_UP:
			current_state = State.WANDERING
			_pick_new_wander_target()

# --- 辅助函数 ---

func _pick_new_wander_target():
	var random_direction = Vector2.from_angle(randf_range(0, TAU))
	var random_distance = randf_range(0, wander_radius)
	wander_target = start_position + random_direction * random_distance

func _on_flee_cooldown_timer_timeout():
	# 只有当计时器走完，才真正切换回游荡状态
	# 并且要确保此时玩家确实不在圈内
	if current_state == State.FLEEING and not fear_area.has_overlapping_bodies():
		current_state = State.WANDERING
		_pick_new_wander_target()
