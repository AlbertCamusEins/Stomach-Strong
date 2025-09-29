# scripts/Skill.gd
# A resource for all usable skills in battle.
@tool
class_name Skill extends Resource

# --- 枚举定义 ---
# 定义技能的目标类型
enum TargetType {
	ENEMY_SINGLE, # 敌方单体
	SELF,         # 自身
	ALLY_SINGLE,  # 友方单体（新增）
	# 以后可以扩展: ENEMY_ALL, ALLY_ALL
}

# 定义技能的消耗类型
enum CostType {
	MANA,    # 消耗魔力
	SATIETY, # 消耗饱食度
	NONE     # 无消耗
}

# --- 技能属性 ---
@export_group("Basic Info")
@export var skill_name: String = "New Skill"
@export_multiline var description: String = "A powerful skill."

@export_group("Combat Properties")
@export var target_type: TargetType = TargetType.ENEMY_SINGLE
@export var cost_type: CostType = CostType.MANA
@export var cost: int = 10
@export var power: int = 20 # 技能的威力，可以是伤害值或治疗量

# (可选) 以后可以添加状态效果
# @export var status_effect: StatusEffect
# @export var effect_chance: float = 1.0 # 100% 触发
