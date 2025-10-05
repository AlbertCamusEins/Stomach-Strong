extends CharacterBody2D



# 移动速度
@export var speed: float = 10.0
# 游荡半径
@export var wander_radius: float = 100.0

# 起身触发范围
@onready var birth_trigger_radius = $Area2D

@onready var anim_sprite = $AnimatedSprite2D

var start_position: Vector2
var wander_target: Vector2

var is_active: bool = false

func _ready() -> void:
	start_position = global_position
	birth_trigger_radius.body_entered.connect(_on_birth_trigger_area_body_entered)
	birth_trigger_radius.body_exited.connect(_on_birth_trigger_area_body_exited)

func _physics_process(delta: float) -> void:
	if not is_active:
		velocity = Vector2.ZERO
		return
	if anim_sprite.animation == "birth" and anim_sprite.is_playing():
		return
	if (anim_sprite.animation == "birth" and anim_sprite.frame == 10) or anim_sprite.animation == "walk":
		var direction = global_position.direction_to(wander_target)
		velocity = direction * speed
		move_and_slide()
		anim_sprite.play("walk")
	
	if global_position.distance_to(wander_target) < 5.0:
		_pick_new_wander_target()

func _on_birth_trigger_area_body_exited(body):
	if body == self:
		return
	if body.is_in_group("Player"):
		is_active = false
		if anim_sprite.animation == "birth":
			anim_sprite.speed_scale = -1.0
			anim_sprite.play()
		else:
			anim_sprite.animation = "birth"
			anim_sprite.frame = 10
			anim_sprite.speed_scale = -1.0
			anim_sprite.play()

func _on_birth_trigger_area_body_entered(body):
	if body == self:
		return
	if body.is_in_group("Player"):
		anim_sprite.animation = "birth"
		anim_sprite.speed_scale = 1
		anim_sprite.play()
		is_active = true

func _pick_new_wander_target():
	# 在初始位置为圆心，wander_radius为半径的圆内随机选择一个新目标点
	var random_direction = Vector2.from_angle(randf_range(0, TAU))
	var random_distance = randf_range(0, wander_radius)
	wander_target = start_position + random_direction * random_distance
