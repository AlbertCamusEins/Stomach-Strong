# scripts/Combatant.gd
# 代表一个战斗单位，可以是玩家或敌人。
# 现在它被设计为可以被动态创建和设置。
class_name Combatant extends Node2D

# --- 核心数据 ---
# [修改] 我们不再导出 stats_resource，因为数据将由 BattleManager 动态注入
var character_data: CharacterData # 存储角色的“灵魂档案”
var stats: CharacterStats # 战斗中实际使用的属性副本
var is_defending: bool = false

# 一个计算属性，根据核心公式实时计算出最终速度。
var final_speed: float:
	get:
		if not stats: return 0.0 # 安全检查
		if stats.max_satiety == 0:
			return stats.base_speed
		var satiety_ratio = float(stats.current_satiety) / stats.max_satiety
		return stats.base_speed * (1.0 - satiety_ratio)

# [新增] 核心设置函数
# BattleManager 将在实例化这个节点后调用此函数
func setup(data: CharacterData):
	self.character_data = data
	# 关键：我们从注入的 CharacterData 中获取 stats，并创建其副本
	self.stats = character_data.stats.duplicate(true)
	self.name = character_data.character_name # 将节点的名字也改成角色名，方便调试

# [修改] _ready() 函数不再需要做任何事情
func _ready():
	pass

# 在每个新回合开始时，重置状态
func start_turn():
	is_defending = false
