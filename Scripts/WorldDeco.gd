class_name WorldDeco extends Node2D

@export var texture: Texture

@onready var sprite = $Sprite2D

func _ready() -> void:
	sprite.texture = texture
	sprite.scale = Vector2(1,1)
