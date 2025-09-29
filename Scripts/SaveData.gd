# scripts/SaveData.gd
# 这个资源就像一个“集装箱”，用来打包所有需要存档的游戏数据。
class_name SaveData extends Resource

# --- 玩家数据 ---
@export var player_stats: CharacterStats
@export var player_inventory: Array
@export var player_equipment: Dictionary
@export var equipment_by_character: Dictionary
@export var player_known_recipes: Array[Recipe]
@export var player_known_techniques: Array[CookingTechnique]

# --- 任务数据 ---
@export var active_quests: Dictionary # 存储正在进行的任务
@export var completed_quests: Array[String] # 只需存储已完成任务的ID
@export var dialogue_flags: Dictionary

# --- 战斗编队 ---
@export var all_characters: Dictionary
@export var combat_party: Array[String]
@export var reserve_party: Array[String]

# (未来) 当我们有新系统时，只需在这里添加新变量
# @export var player_position_on_map: Vector2
# @export var completed_quests: Array[String]
