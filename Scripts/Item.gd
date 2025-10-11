# scripts/Item.gd
# 所有物品的统一基类
@tool
class_name Item extends Resource

@export_group("基本信息")
@export var item_name: String
@export_multiline var description: String
@export var stackable: bool = true # 默认所有物品都可以堆叠
@export var max_stack_size: int = 5 # 最大堆叠数量
@export var icon: Texture2D

@export_group("功能组件 (可选)")
# 一个物品可以拥有的不同功能组件
# 如果某个组件为空(null)，说明物品不具备该功能
@export var consumable_props: ConsumableComponent
@export var equipment_props: EquipmentComponent
@export var cookware_props: CookwareComponent
