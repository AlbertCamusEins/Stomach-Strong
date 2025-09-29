# scripts/FoodItem.gd
# A resource for all consumable food items.
@tool
class_name ConsumableComponent extends Resource



@export_group("Immediate Effects")
@export var health_change: int = 0 # 恢复的生命值
@export var satiety_change: int = 20 # 恢复的饱食度
@export var mana_change: int = 0 # 恢复的魔力

@export_group("Permanent Stat Boosts")
@export var add_max_health: int = 0
@export var add_max_satiety: int = 0
@export var add_max_mana: int = 0
@export var add_attack: int = 0
@export var add_defense: int = 0
@export var add_base_speed: int = 0
