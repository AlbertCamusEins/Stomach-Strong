# scripts/StatusDisplay.gd
# 一个独立、可复用的UI组件，用于显示单个战斗单位的状态
class_name StatusDisplay extends PanelContainer

# --- 节点引用 ---
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var hp_bar: ProgressBar = $VBoxContainer/PlayerHPBar
@onready var hp_label: Label = $VBoxContainer/PlayerHPBar/PlayerHPLabel
@onready var satiety_bar: ProgressBar = $VBoxContainer/PlayerSatietyBar
@onready var satiety_label: Label = $VBoxContainer/PlayerSatietyBar/PlayerSatietyLabel
@onready var mana_bar: ProgressBar = $VBoxContainer/PlayerManaBar
@onready var mana_label: Label = $VBoxContainer/PlayerManaBar/PlayerManaLabel

# --- 核心函数 ---
func update_display(combatant: Combatant):
	var stats = combatant.stats
	
	# 更新名字
	name_label.text = combatant.character_data.character_name
	
	# 更新生命值
	hp_bar.max_value = stats.max_health
	hp_bar.value = stats.current_health
	hp_label.text = "%d / %d" % [stats.current_health, stats.max_health]
	
	# 更新饱食度
	satiety_bar.max_value = stats.max_satiety
	satiety_bar.value = stats.current_satiety
	satiety_label.text = "%d / %d" % [stats.current_satiety, stats.max_satiety]

	# 更新魔力值
	mana_bar.max_value = stats.max_mana
	mana_bar.value = stats.current_mana
	mana_label.text = "%d / %d" % [stats.current_mana, stats.max_mana]
